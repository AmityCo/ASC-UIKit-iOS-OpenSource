//
//  UIKitPaginator.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/6/2567 BE.
//

import Foundation
import AmitySDK
import Combine
import SwiftUI

// MARK: - Banner Ad Models
// Defined here so every file that sees UIKitPaginator also sees these types.

/// Represents a single banner-ad slot that will be rendered inside the feed.
public struct BannerAdPlacement: Identifiable {
    public let id: String
    public let adUnitID: String
    
    public init(adUnitID: String) {
        self.id = "banner-ad-\(UUID().uuidString)"
        self.adUnitID = adUnitID
    }
}

/// Controls how / whether banner ads are injected into the news feed.
/// Configure from your host app **before** the feed loads.
public class BannerAdFeedConfig {
    public static let shared = BannerAdFeedConfig()
    
    /// Master switch – set to `true` to start injecting ads.
    public var isEnabled: Bool = false
    
    /// The ad-unit ID forwarded to every `BannerAdPlacement`.
    public var adUnitID: String = "ca-app-pub-3940256099942544/2934735716"
    
    /// Insert a banner ad after every *frequency* content posts.
    public var frequency: Int = 5
    
    /// Maximum number of banner ads in the feed at any time.
    public var maxAdsCount: Int = 3
    
    /// Height (points) for the ad row. Defaults to 250.
    public var adHeight: CGFloat = 250
    
    /// Closure that returns the SwiftUI view for a given placement.
    /// The host app **must** set this to supply the actual ad view.
    ///
    /// ```swift
    /// BannerAdFeedConfig.shared.adViewBuilder = { placement in
    ///     AnyView(BannerAdView(adUnitID: placement.adUnitID))
    /// }
    /// ```
    public var adViewBuilder: ((BannerAdPlacement) -> AnyView)?
    
    private init() {}
}

// MARK: - Paginated Item

enum PaginatedItemType {
    case content
    case ad
}

class PaginatedItem<Content>: Identifiable, Equatable {
    enum ItemType {
        case content(_ value: Content)
        case ad(_ value: AmityAd)
        case bannerAd(_ value: BannerAdPlacement)
    }
    
    var id: String
    var type: ItemType
    
    init(id: String, type: ItemType) {
        self.id = id
        self.type = type
    }
    
    static func == (lhs: PaginatedItem<Content>, rhs: PaginatedItem<Content>) -> Bool {
        lhs.id == rhs.id
    }
}

class UIKitPaginator<T: AmityModel> {
    
    @Published var snapshots = [PaginatedItem<T>]()
    
    weak private var liveCollection: AmityCollection<T>?
    private let adPlacement: AmityAdPlacement
    let modelIdentifier: (T) -> String
    let communityId: String?
    let excludedId: String?

    private var token: AmityNotificationToken?
    var ads: [AmityAd] = []
    
    let timeWindowAdInjector = TimeWindowAdsInjector()
    let fixedFrequencyAdInjector = FixedFrequencyAdsInjector()
    
    init(liveCollection: AmityCollection<T>, adPlacement: AmityAdPlacement, communityId: String? = nil, excludedId: String? = nil, modelIdentifier: @escaping (T) -> String) {
        self.liveCollection = liveCollection
        self.adPlacement = adPlacement
        self.modelIdentifier = modelIdentifier
        self.communityId = communityId
        self.excludedId = excludedId
    }
    
    func load() {
        token?.invalidate()
        token = liveCollection?.observe { [weak self] collection, error in
            self?.integrateRecommendedAds(defaultContents: collection.snapshots, excludeId: self?.excludedId)
        }
    }
    
    func hasNextPage() -> Bool {
        guard let liveCollection else { return false }
        return liveCollection.hasNext
    }
    
    func nextPage() {
        guard let liveCollection, liveCollection.hasNext else { return }
        
        liveCollection.nextPage()
    }
    
    func hasPreviousPage() -> Bool {
        guard let liveCollection else { return false }
        return liveCollection.hasPrevious
    }
    
    func previousPage() {
        guard let liveCollection, liveCollection.hasPrevious else { return }
        
        liveCollection.previousPage()
    }
    
    func clear() {
        ads = []
        snapshots = []
        
        token?.invalidate()
        token = nil
    }
    
    // MARK:- Ads Integration
    func integrateRecommendedAds(defaultContents: [T], excludeId: String?) {
        var contents = defaultContents
        
        if let excludeId {
            contents = defaultContents.filter {
                let modelId = self.modelIdentifier($0)
                return modelId != excludeId
            }
        }
        
        // Default snapshots without ads
        let getDefaultSnapshots: () -> Void = {
            self.snapshots = contents.map { .init(id: self.modelIdentifier($0), type: .content($0)) }
        }
        
        // Ad settings should be enabled & frequency settings should be available.
        guard let adSettings = AdEngine.shared.adSettings, adSettings.enabled, let adFrequency = AdEngine.shared.getAdFrequency(at: adPlacement), adFrequency.value > 0 else {
            getDefaultSnapshots()
            return
        }
        
        if adFrequency.isTypeTimeWindow {
            guard !AdEngine.shared.timeWindowTracker.hasReachedTimeWindowLimit(placement: adPlacement) else {
                
                if snapshots.isEmpty || ads.isEmpty {
                    getDefaultSnapshots()
                } else {
                    if let firstAd = ads.first {
                        let mergedItems = timeWindowAdInjector.insertAdAtPosition(ad: firstAd, contents: contents, position: 1, modelIdentifier: modelIdentifier)
                        self.snapshots = mergedItems
                    } else {
                        getDefaultSnapshots()
                    }
                }
                
                return
            }
               
            // If we don't have ad, fetch it
            if ads.isEmpty {
                let recommendedAd = AdEngine.shared.getRecommendedAds(count: 1, placement: adPlacement, communityId: communityId)
                ads = recommendedAd
            }
            
            let mergedItems = timeWindowAdInjector.mergeAds(ads: ads, contents: contents, modelIdentifier: modelIdentifier)
            self.snapshots = mergedItems
            
        } else {
            // Ads with fixed frequency. Here fixed frequency determines the number of contents after which an ad is to be displayed.
            let frequency = adFrequency.value
            
            // If total content loaded is 20 and frequency is 5, number of ads required would be floor(20 / 5) = 4
            let requiredAdCount = contents.count / frequency
            let loadedAdCount = ads.count
            
//            Log.ads.debug("Feed Ad Frequency: \(frequency), Loaded ads count: \(loadedAdCount), Required Ad: \(requiredAdCount) Type: \(String(describing: T.self))")
            
            // If we have already loaded requireds ads in paginator before, just reuse it.
            if requiredAdCount > loadedAdCount {
                // We query for remaining recommended ads
                let requestedCount = requiredAdCount - loadedAdCount
                
                let recommendedAds = AdEngine.shared.getRecommendedAds(count: requestedCount, placement: adPlacement, communityId: communityId)
                
                Log.ads.debug("Fetched recommended ad: \(recommendedAds.count)")
                
                self.ads.append(contentsOf: recommendedAds)
            }
            
//            Log.ads.debug("Merging \(self.ads.count) ads with \(contents.count) items")
            
            let mergedItems = fixedFrequencyAdInjector.mergeAds(ads: ads, contents: contents, frequency: frequency, modelIdentifier: modelIdentifier)
            self.snapshots = mergedItems
        }
    }
}
