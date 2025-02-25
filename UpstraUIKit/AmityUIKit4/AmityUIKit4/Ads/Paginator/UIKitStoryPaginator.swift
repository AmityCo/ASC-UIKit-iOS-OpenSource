//
//  UIKitStoryPaginator.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 7/2/24.
//

import Foundation
import AmitySDK
import Combine

class UIKitStoryPaginator<T: AmityModel>: UIKitPaginator<T> {
    private var surplus: Int
    private let storyFixedFrequencyAdInjector: StoryFixedFrequencyAdInjector
    
    init(liveCollection: AmityCollection<T>, surplus: Int, communityId: String? = nil, modelIdentifier: @escaping (T) -> String) {
        self.surplus = surplus
        self.storyFixedFrequencyAdInjector = StoryFixedFrequencyAdInjector(surplus: surplus)
        super.init(liveCollection: liveCollection, adPlacement: .story, communityId: communityId, modelIdentifier: modelIdentifier)
    }
    
    override func integrateRecommendedAds(contents: [T]) {
        // Default snapshots without ads
        let getDefaultSnapshots: () -> Void = {
            self.snapshots = contents.map { .init(id: self.modelIdentifier($0), type: .content($0)) }
        }
        
        // Ad settings should be enabled & frequency settings should be available.
        guard let adSettings = AdEngine.shared.adSettings, adSettings.enabled, let adFrequency = AdEngine.shared.getAdFrequency(at: .story), adFrequency.value > 0 else {
            getDefaultSnapshots()
            return
        }
        
        if adFrequency.isTypeTimeWindow {
            guard !AdEngine.shared.timeWindowTracker.hasReachedTimeWindowLimit(placement: .story) else {
                return
            }
               
            // If we don't have ad, fetch it
            if ads.isEmpty {
                let recommendedAd = AdEngine.shared.getRecommendedAds(count: 1, placement: .story, communityId: communityId)
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
            
            // If we have already loaded requireds ads in paginator before, just reuse it.
            if requiredAdCount > loadedAdCount {
                // We query for remaining recommended ads
                let requestedCount = requiredAdCount - loadedAdCount
                
                let recommendedAds = AdEngine.shared.getRecommendedAds(count: requestedCount, placement: .story, communityId: communityId)
                self.ads.append(contentsOf: recommendedAds)
            }
            
            let mergedItems = storyFixedFrequencyAdInjector.mergeAds(ads: ads, contents: contents, frequency: frequency, modelIdentifier: modelIdentifier)
            self.snapshots = mergedItems
        }
    }
}
