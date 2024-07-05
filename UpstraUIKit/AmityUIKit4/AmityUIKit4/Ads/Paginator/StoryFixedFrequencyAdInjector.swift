//
//  StoryFixedFrequencyAdInjector.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/2/24.
//

import Foundation
import AmitySDK

class StoryFixedFrequencyAdInjector: FixedFrequencyAdsInjector {
    private let surplus: Int
    
    init(surplus: Int) {
        self.surplus = surplus
        super.init()
    }
    
    // ads: all the
    override func mergeAds<T: AmityModel>(ads: [AmityAd], contents: [T], frequency: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] {
        
        guard !ads.isEmpty else {
            
            let snapshots = contents.map { PaginatedItem(id: modelIdentifier($0), type: .content($0)) }
            return snapshots
        }
        
        let mergedItems = self.insertAdEveryPosition(ads: ads, contents: contents, position: frequency, modelIdentifier: modelIdentifier)
        return mergedItems
    }
    
    override func insertAdEveryPosition<T>(ads: [AmityAd], contents: [T], position: Int, modelIdentifier: @escaping (T) -> String) -> [PaginatedItem<T>] where T : AmityModel {
        var mergedItems = [PaginatedItem<T>]()
        var positionCounter = surplus
        
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
                    
                    // Remove from ad list
                    availableAds.removeFirst()
                }
                
                positionCounter = 0
            }
        }
        return mergedItems
    }
}
