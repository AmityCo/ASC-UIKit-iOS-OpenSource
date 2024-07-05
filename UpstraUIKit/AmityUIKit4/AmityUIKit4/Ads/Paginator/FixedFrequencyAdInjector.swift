//
//  FixedFrequencyAdInjector.swift
//  AmityUIKit4
//
//  Created by Nishan on 26/6/2567 BE.
//

import SwiftUI
import AmitySDK

class FixedFrequencyAdsInjector {
 
    typealias AdId = String
    typealias ModelId = String
    
    private var adContentMap = [AdId: [ModelId]]()
    private var lastInsertModelId: String = "" // Id of the model where ad was injected last
    
    // ads: all the
    func mergeAds<T: AmityModel>(ads: [AmityAd], contents: [T], frequency: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        
        guard !ads.isEmpty else {
            adContentMap = [:]
            
            let snapshots = contents.map { PaginatedItem(id: modelIdentifier($0), type: .content($0)) }
            return snapshots
        }
                
        if adContentMap.isEmpty {
            Log.adInjector.debug("❗️Inserting ads for first time per frequency")
            let mergedItems = self.insertAdEveryPosition(ads: ads, contents: contents, position: frequency, modelIdentifier: modelIdentifier)
            
            return mergedItems
        } else {
            Log.adInjector.debug("‼️Inserting ads to its previous places..")
            let mergedItems = self.insertAdAfterModel(ads: ads, contents: contents, frequency: frequency, modelIdentifier: modelIdentifier)
            
            return mergedItems
        }
    }
    
    func insertAdEveryPosition<T: AmityModel>(ads: [AmityAd], contents: [T], position: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        var mergedItems = [PaginatedItem<T>]()
        var positionCounter = 0
        
        var availableAds = ads
        contents.forEach { model in
            // Add Items
            let modelId = modelIdentifier(model)
            mergedItems.append(PaginatedItem(id: modelId, type: .content(model)))
            
            // Increment index
            positionCounter += 1
            
            // If its time to inject ad,
            if positionCounter == position {
                // Inject Ad
                if let firstAd = availableAds.first {
                    mergedItems.append(PaginatedItem(id: firstAd.createUniqueId(withContentId: modelId), type: .ad(firstAd)))
                    
                    let modelId = modelIdentifier(model)
                    adContentMap[firstAd.adId, default: []].append(modelId)
                                        
                    lastInsertModelId = modelId
                    
                    // Remove from ad list
                    availableAds.removeFirst()
                }
                positionCounter = 0
            }
        }
        return mergedItems
    }
    
    private func insertAdAfterModel<T: AmityModel>(ads: [AmityAd], contents: [T], frequency: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        
        guard !ads.isEmpty else {
            adContentMap = [:]
            
            let snapshots = contents.map { PaginatedItem(id: modelIdentifier($0), type: .content($0)) }
            return snapshots
        }
        
        // First load case, Ads hasn't been injected yet. So inject it on 2nd position
        if adContentMap.isEmpty {
            let mergedItems = self.insertAdEveryPosition(ads: ads, contents: contents, position: frequency, modelIdentifier: modelIdentifier)
            return mergedItems
        } else {
            var mergedItems = [PaginatedItem<T>]()
            let contentIds: Set<String> = Set(contents.map { modelIdentifier($0) })
            
            // These are the ads that i need to work with
            var availableAds = filterInvalidAds(ads: ads, contentIds: contentIds)
            
            guard !availableAds.isEmpty else {
                adContentMap = [:]
                
                let snapshots = contents.map { PaginatedItem(id: modelIdentifier($0), type: .content($0)) }
                return snapshots
            }
            
            var positionCounter = 0
            var injectBasedOnFrequency = false
            
            for model in contents {
                // Append items
                mergedItems.append(PaginatedItem(id: modelIdentifier(model), type: .content(model)))
                
                // Increment position counter
                positionCounter += 1
                
                // If no ad is present, we skip rest of the process
                guard let ad = availableAds.first else { continue }
                
                let modelId = modelIdentifier(model)
                // Inject old ads which have associated model id
                if let adContentIds = adContentMap[ad.adId], adContentIds.contains(modelId) {
                    mergedItems.append(PaginatedItem(id: ad.createUniqueId(withContentId: modelId), type: .ad(ad)))
                    availableAds.removeFirst()
                }
                
                // If we have reached the id of the post where last ad was inserted before
                if lastInsertModelId.isEmpty || lastInsertModelId == modelId {
                    // Now we should start injecting ads based on frequency
                    if !injectBasedOnFrequency {
                        injectBasedOnFrequency = true
                        positionCounter = 0
                    }
                }
                
                guard injectBasedOnFrequency else { continue }
                
                if positionCounter == frequency {
                    mergedItems.append(PaginatedItem(id: ad.createUniqueId(withContentId: modelId), type: .ad(ad)))
                    
                    adContentMap[ad.adId, default: []].append(modelId)
                    lastInsertModelId = modelId
                    
                    // Remove ad from the list
                    availableAds.removeFirst()
                    
                    // Reset counter
                    positionCounter = 0
                }
            }
            
            return mergedItems
        }
    }
    
    func filterInvalidAds(ads: [AmityAd], contentIds: Set<String>) -> [AmityAd] {
        var oldAds = [AmityAd]()
        var newAds = [AmityAd]()
        
        ads.forEach { ad in
            if let modelIds = adContentMap[ad.adId] { // all the model ids associated with the ad
                
                var isModelAvailable = false
                modelIds.forEach {
                    // Can find content id
                    if contentIds.contains($0) {
                        isModelAvailable = true
                    }
                }
                
                // If the ad was injected before but its associated content is not available, we don't use that ad.
                if isModelAvailable {
                    oldAds.append(ad)
                }
                
            } else {
                // This ad has never been injected before
                newAds.append(ad)
            }
        }
        
        // After we encounter lastInserModelId, we switch to injecting ads every (x) items.
        // So we determine ahead, if the lastInsertModelId is still valid.
        // If it's not valid, we find new last injected ad based on valid old ads
        // If none of them is valid, then lastInsertModelId would be empty.
        if !contentIds.contains(lastInsertModelId) {
            if let lastAdId = adContentMap[oldAds.last?.adId ?? ""]?.last {
                lastInsertModelId = lastAdId
            }
        }
        
        let finalAds = oldAds + newAds
        return finalAds
    }
    
    // Useful for debugging items
    internal func printItems<T>(items: [PaginatedItem<T>], modelIdentifier: @escaping (T) -> String) {
        items.enumerated().forEach { index, item in
            switch item.type {
            case .ad(let ad):
                print("[\(index)] - 🐶 Ad \(ad.adId)")
            case .content(let value):
                print("[\(index)] - Content \(modelIdentifier(value))")
            }
        }
    }
}
