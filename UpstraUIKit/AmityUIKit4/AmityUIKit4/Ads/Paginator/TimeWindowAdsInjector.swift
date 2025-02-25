//
//  TimeWindowAdsInjector.swift
//  AmityUIKit4
//
//  Created by Nishan on 26/6/2567 BE.
//

import SwiftUI
import AmitySDK

/*
 How it works:
 
 | Case 1                   | Case 2                     | Case 3                             |
 |--------------------------|----------------------------|------------------------------------|
 | 20                       | 23 [rte]                   | 23 [rte]                           |
 | — ad (1) —               | 22 [rte]                   | 22 [rte]                           |
 | (always on 2nd position) | 21 [rte]                   | 21 [rte]                           |
 | 19                       | 20                         | 20                                 |
 | 18                       | — ad (1) —                 | — ad (1) —                         |
 | 17                       | (Retain previous position) | (Retain & show on first page only) |
 |                          | 19                         | 19                                 |
 |                          | 18                         | 18                                 |
 |                          | 17                         | 17                                 |
 |                          |                            | — nextPage() ——                    |
 |                          |                            | 16                                 |
 |                          |                            | 15                                 |
 |                          |                            | 14                                 |
 */

class TimeWindowAdsInjector {
    
    // [AdId: ModelId]
    private var adContentMap = [String: String]()
    
    // Ad needs to be displayed on 2nd position on first load of the page.
    func mergeAds<T: AmityModel>(ads: [AmityAd], contents: [T], modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        guard !ads.isEmpty else {
            let snapshots = contents.map { PaginatedItem(id: modelIdentifier($0), type: .content($0)) }
            return snapshots
        }
        
        // Recommended ad for this time window
        let recommendedAd = ads[0]
        let adTargetIndex = 1 // Inject ad in this index
        
        // Ads hasn't been injected yet. So inject it on 2nd position.
        if adContentMap.isEmpty {
            let mergedContents = insertAdAtPosition(ad: recommendedAd, contents: contents, position: adTargetIndex, modelIdentifier: modelIdentifier)
            return mergedContents
        } else {
            
            // Ads has been injected before for this collection. So we get the id of the content after which ad was injected previously.
            let associatedModelId = adContentMap[recommendedAd.adId]
            
            // If we have model id, then this is the same ad that was injected before
            if let associatedModelId {
                let mergedContents = insertAdAfterModel(ad: recommendedAd, contents: contents, afterModelId: associatedModelId, modelIdentifier: modelIdentifier)
                return mergedContents
            } else {
                // This might be a new ad. So we add it to second position
                let mergedContents = insertAdAtPosition(ad: recommendedAd, contents: contents, position: adTargetIndex, modelIdentifier: modelIdentifier)
                return mergedContents
            }
        }
    }
    
    private func insertAdAfterModel<T: AmityModel>(ad: AmityAd, contents: [T], afterModelId: String, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        var mergedItems = [PaginatedItem<T>]()
        
        contents.forEach { model in
            // Add items
            let modelId = modelIdentifier(model)
            mergedItems.append(PaginatedItem(id: modelId, type: .content(model)))

            // Add ads after required model. If model is not available, then we skip adding ads.
            let curModelId = modelIdentifier(model)
            if curModelId == afterModelId {
                mergedItems.append(PaginatedItem(id: ad.createUniqueId(withContentId: modelId), type: .ad(ad)))
                
                let modelId = modelIdentifier(model)
                adContentMap[ad.adId] = modelId
            }
        }
        
        return mergedItems
    }
    
    func insertAdAtPosition<T: AmityModel>(ad: AmityAd, contents: [T], position: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        var mergedItems = [PaginatedItem<T>]()
        var curItemIndex = 0
        
        contents.forEach { model in
            // Add Items
            let modelId = modelIdentifier(model)
            mergedItems.append(PaginatedItem(id: modelId, type: .content(model)))
            
            // Increment index
            curItemIndex += 1
            
            // If its time to inject ad,
            if curItemIndex == position {
                mergedItems.append(PaginatedItem(id: ad.createUniqueId(withContentId: modelId), type: .ad(ad)))
                
                let modelId = modelIdentifier(model)
                adContentMap[ad.adId] = modelId  // So that we know ad is injected after this post
            }
        }
        return mergedItems
    }
}
