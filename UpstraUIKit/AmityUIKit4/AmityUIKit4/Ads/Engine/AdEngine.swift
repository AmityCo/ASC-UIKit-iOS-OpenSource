//
//  AdEngine.swift
//  AmityUIKit4
//
//  Created by Nishan on 13/6/2567 BE.
//

import Foundation
import AmitySDK
import Combine
import RealmSwift
import OSLog

class AdEngine {
    
    /// Entry point
    static let shared = AdEngine()
    
    let adRepo: AmityAdRepository
    var timeWindowTracker = AdTimeWindowTracker()
    
    var adSettings: AmityAdsSettings?
    var ads: [AmityAd] = []
    var cancellable: AnyCancellable?
        
    // Persistent cache for ad assets & seen recency
    let dataStore = RealmStore.shared
    let assetEngine = AssetSyncEngine()
    
    var isEngineSyncStarted = false
        
    private init() {
        adRepo = AmityAdRepository(client: AmityUIKitManagerInternal.shared.client)
                                
        let client = AmityUIKitManagerInternal.shared.client
        cancellable = client.$sessionState.sink { [weak self] state in
            guard let self else { return }
                        
            switch state {
            case .established:
                // Due to bug in sdk, session "established" even can be emitted 2 times when sdk login() method is called
                // for same user id. So we check for ad settings presence before querying for ads.
                guard adSettings == nil else { return }
                
                Task {
                    await self.start()
                }
            case .terminated(_), .notLoggedIn: // State changes to NotLoggedIn incase of manual logout.
                self.clear()
                
            default:
                break
            }
        }
    }
    
    // Clears out ad settings & ads
    func clear() {
        adSettings = nil
        ads = []
        isEngineSyncStarted = false
        
        // Clear assets metadata
        dataStore.clear()
        timeWindowTracker.clear()
        
        // Cancel downloads & remove cached ad images
        assetEngine.cancelAllDownload()
        assetEngine.removeAllAssets()
    }
    
    @MainActor
    func start() async {
        do {
            let networkAds = try await adRepo.getNetworkAds()
            self.ads = networkAds.ads
            self.adSettings = networkAds.settings
            
            Log.ads.debug("Ads Fetched: \(self.ads.count) | Settings Enabled: \(String(describing: self.adSettings?.enabled))")
            
            // Remove obsolete ads and upsert ads asset info into database.
            self.prepareAds(newAds: ads)
            
            // Prefetch ad assets
            self.prefetchAssets(newAds: ads)
        } catch let error {
            Log.ads.debug("Error occurred while querying network ads \(error.localizedDescription)")
        }
    }
    
    // Note:
    // This method combines removeObsoleteAssets and assignNewAds present in tech spec into single method to perform
    // efficient database manipulation.
    func prepareAds(newAds: [AmityAd]) {
        // We query all existing ads from realm to avoid multiple trip
        guard let realm = dataStore.database else { return }
        
        let obsoleteAds = getObsoleteAds(newAds: newAds, store: realm)
        
        Log.ads.debug("Ads Received: \(newAds.count), Obsolete ads found: \(obsoleteAds.count)")
        
        // We remove obsolete ads in single realm write operation
        realm.perform {
            
            // Delete those obsolete ads
            if !obsoleteAds.isEmpty {
                realm.delete(obsoleteAds)
            }
            
            // Upsert new ads
            newAds.forEach {
                AdAsset.upsert(ad: $0, in: realm)
            }
        }
    }
    
    func getObsoleteAds(newAds: [AmityAd], store: Realm) -> [AdAsset] {
        var newAssetIds = Set<String>()  // Keeping track of all adId as set to compare it with existing assets efficiently.
        newAds.forEach {
            if let fileId1 = $0.image1_1?.fileId {
                newAssetIds.insert(fileId1)
            }
            
            if let fileId2 = $0.image9_16?.fileId {
                newAssetIds.insert(fileId2)
            }
        }
        
        let allAssets = store.objects(AdAsset.self)

        // Keep track of all obsolete assets
        var obsoleteAds = [AdAsset]()
        allAssets.forEach { item in
            // Since new ad list does not contain this ad, we mark it as obsolete.
            if !newAssetIds.contains(item.fileId) {
                obsoleteAds.append(item)
            }
        }
        
        return obsoleteAds
    }
    
    func prefetchAssets(newAds: [AmityAd]) {
        // 1. Check if the ad asset is already prefetched
        for ad in newAds {
                        
            let fileIdImage1_1 = ad.image1_1?.fileId
            let fileUrlImage1_1 = ad.image1_1?.fileURL
            
            let fileIdImage9_16 = ad.image9_16?.fileId
            let fileUrlImage9_16 = ad.image9_16?.fileURL
            
            let imageSize = "?size=large"
            
            // FileURL: FileID Map
            var map: [String: String] = [:]
            
            var prefetchUrls = [String]()
            if let fileIdImage1_1, let fileUrlImage1_1, !self.isAssetDownloaded(assetId: fileIdImage1_1) {
                
                let imageURL = fileUrlImage1_1 + imageSize
                
                prefetchUrls.append(imageURL)
                map[imageURL] = fileIdImage1_1
            }
            
            if let fileIdImage9_16, let fileUrlImage9_16, !self.isAssetDownloaded(assetId: fileIdImage9_16) {
                
                let imageURL = fileUrlImage9_16 + imageSize
                
                prefetchUrls.append(imageURL)
                
                map[imageURL] = fileIdImage9_16
            }
            
            guard !prefetchUrls.isEmpty else { continue }
            
            Log.adAssets.debug("Prefetching ad assets: \(prefetchUrls)")
            
            // Sync Assets
            assetEngine.fetchAssets(urls: prefetchUrls) { downloadedUrls in
                
                // Map downloaded urls to asset id
                let ids = downloadedUrls.compactMap { url in
                    map[url]
                }
                                
                self.markAssetsAsReady(assetIds: ids)
            }
        }
    }
    
    func isAssetDownloaded(assetId: String) -> Bool {
        guard let realm = dataStore.database else { return false }
        let asset = realm.object(ofType: AdAsset.self, forPrimaryKey: assetId)
        
        if let asset {
            // Log.adAssets.debug("Is Asset Downloaded: \(assetId) \(asset.isDownloaded)")
            return asset.isDownloaded
        } else {
            Log.adAssets.debug("Is Asset Downloaded: Error - Asset not found")
            return false
        }
    }
    
    private func markAssetsAsReady(assetIds: [String]) {
        guard let realm = dataStore.database else { return }
        
        realm.perform {
            assetIds.forEach { id in
                
                if let asset = realm.object(ofType: AdAsset.self, forPrimaryKey: id) {
                    asset.isDownloaded = true
                    // Log.adAssets.debug("Asset is ready: \(id)")
                } else {
                    Log.adAssets.debug("Asset is ready: \(id) Error - Asset not found")
                }
            }
        }
    }
    
    /// Returns frequency settings for ad at given placement
    func getAdFrequency(at placement: AmityAdPlacement) -> AmityAdFrequency? {
        switch placement {
        case .feed:
            return adSettings?.frequency?.feed
        case .story:
            return adSettings?.frequency?.story
        case .comment:
            return adSettings?.frequency?.comment
        case .chat, .chatList:
            return nil
        @unknown default:
            return nil
        }
    }
}

// AdEngine + Analytics
extension AdEngine {
    
    func markAsClicked(ad: AmityAd, placement: AmityAdPlacement) {
        ad.analytics.markLinkAsClicked(placement: placement)
    }
    
    // We also need to update seen recency
    func markAsSeen(ad: AmityAd, placement: AmityAdPlacement) {
        updateSeenRecencyCache(ad: ad, placement: placement)
        
        ad.analytics.markAsSeen(placement: placement)
    }
    
    func getLastSeen(adId: String) -> Date? {
        guard let database = dataStore.database else { return nil }
        
        let cachedData = database.object(ofType: AdSeenEvent.self, forPrimaryKey: adId)
        return cachedData?.lastSeen
    }
    
    private func updateSeenRecencyCache(ad: AmityAd, placement: AmityAdPlacement) {
        guard let database = dataStore.database else { return }
        
        // Update cache
        database.perform {
            AdSeenEvent.upsert(adId: ad.adId, lastSeen: Date(), in: database)
        }
        
        // Update time window tracker
        if let adFrequency = getAdFrequency(at: placement), adFrequency.isTypeTimeWindow {
            timeWindowTracker.markAsSeen(placement: placement)
        }
    }
}

extension AdEngine {
    
    // AdEngine query ads filtering by activeness, readiness, and placement, then use AdSupplier to determine which ads to recommend.
    // This is the entry points for paginator.
    public func getRecommendedAds(count: Int, placement: AmityAdPlacement, communityId: String?) -> [AmityAd] {
        let applicableAds = getApplicableAds(placement: placement, communityId: communityId)
        
        // Ask supplier to provide us with relevant ads
        return AdSupplier.shared.recommendAds(count: count, placement: placement, communityId: communityId, from: applicableAds)
    }
    
    // Determines ads which suits for given placement & whose assets are downloaded & ready to be used.
    private func getApplicableAds(placement: AmityAdPlacement, communityId: String?) -> [AmityAd] {
        let readyAds = ads.filter {
            
            // Criteria 1: Placement should be valid.
            let isPlacementValid = $0.placements.contains(placement)
            
            // Criteria 2: Ad's end date should not be in the past
            var isEndDateValid: Bool = $0.endAt == nil
            if let endAd = $0.endAt {
                isEndDateValid = endAd > Date()
            }
            
            // Criteria 3: Ad's asset should be ready.
            var isAssetReady = false
            switch placement {
            case .story:
                if let fileId = $0.image9_16?.fileId {
                    isAssetReady = isAssetDownloaded(assetId: fileId)
                }
            default:
                if let fileId = $0.image1_1?.fileId {
                    isAssetReady = isAssetDownloaded(assetId: fileId)
                }
            }
            
            return isPlacementValid && isEndDateValid && isAssetReady
        }
        
        // Find if any ready ads targets matches community id
        if let communityId {
            let targetedAds = readyAds.filter { ad in
                let commIds = ad.target?.communityIds ?? []
                return commIds.contains(communityId)
            }
            
            // If there are no ads which target particular communities, we return non targeted ads
            if targetedAds.isEmpty {
                let nonTargetedAds = readyAds.filter { ad in
                    let commIds = ad.target?.communityIds ?? []
                    return commIds.isEmpty
                }
                return nonTargetedAds
            }
            
            return targetedAds
        } else {
            let nonTargetedAds = readyAds.filter { ad in
                let commIds = ad.target?.communityIds ?? []
                return commIds.isEmpty
            }
            
            return nonTargetedAds
        }
    }
}

extension AdEngine {
    
    func log(_ info: String) {
        #if DEBUG
        Log.ads.debug("\(info)")
        #endif
    }
}
