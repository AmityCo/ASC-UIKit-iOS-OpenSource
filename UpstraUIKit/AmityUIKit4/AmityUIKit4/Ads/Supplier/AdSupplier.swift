//
//  AdSupplier.swift
//  AmityUIKit4
//
//  Created by Nishan on 13/6/2567 BE.
//

import Foundation
import AmitySDK

class AdSupplier {
    
    static let shared = AdSupplier()
    
    private init() { /* Internal initialization */ }
    
    func recommendAds(count: Int, placement: AmityAdPlacement, communityId: String?, from ads: [AmityAd]) -> [AmityAd] {
        guard !ads.isEmpty else { return [] }

        // Calculate impression age
        let impressionAges = calculateImpressionAges(ads: ads)
        
        // Calculate score for all ads
        var scores = [String: Double]()
        ads.forEach { ad in
            var relevancy = 0
            if let communityId, let targetCommunityIds = ad.target?.communityIds, targetCommunityIds.contains(communityId) {
                relevancy = 1
            }
            
            if let impressionAge = impressionAges[ad.adId] {
                let score = Double(relevancy) + pow(M_E, 2) * Double(impressionAge)
                scores[ad.adId] = score
            }
        }
        
        return selectAdsByWeightedRandomChoice(ads: ads, scores: scores, count: count)
    }
    
    private func calculateImpressionAges(ads: [AmityAd]) -> [String: Int] {
        
        let recencySortedAds = ads.sorted { item1, item2 in
            let item1LastSeen = AdEngine.shared.getLastSeen(adId: item1.adId)
            let item2LastSeen = AdEngine.shared.getLastSeen(adId: item2.adId)
            
            if let item1LastSeen, let item2LastSeen {
                return item1LastSeen > item2LastSeen
            }
            
            return false // If last seen is not found, just sort in order as ads appear.
        }
        
        let sortedAdsSize = recencySortedAds.count
        
        var impressionAges = [String: Int]()
        let maxLastSeen = AdEngine.shared.getLastSeen(adId: recencySortedAds.first?.adId ?? "") // recently seen ad timestamp
        let minLastSeen = AdEngine.shared.getLastSeen(adId: recencySortedAds.last?.adId ?? "")  // not recently seen ads
        
        if maxLastSeen == minLastSeen {
            recencySortedAds.forEach { ad in
                impressionAges[ad.adId] = 1
            }
        } else {
            
            for i in 0..<recencySortedAds.count {
                let ad = recencySortedAds[i]
                
                let impressionAge = i / sortedAdsSize
                impressionAges[ad.adId] = impressionAge
            }
        }
        return impressionAges
    }
    
    private func selectAdsByWeightedRandomChoice(ads: [AmityAd], scores: [String: Double], count: Int) -> [AmityAd] {
        var relevantAds = ads
        var selectedAds = [AmityAd]()
        
        var totalScore: Double = 0
        scores.values.forEach { totalScore += $0 }
        
        // Repeat until count is met or until no ad to select
        while(selectedAds.count < count && relevantAds.count > 0) {
            let weights = relevantAds.compactMap {
                if let adScore = scores[$0.adId] {
                    return adScore / totalScore
                }
                return nil
            }
            
            let weightSum = weights.reduce(0, { $0 + $1 })
            
            // Normalize Weights
            let likelihoods = weights.map { $0 / weightSum }
            let selectedAdIndex = weightedRandomChoice(weights: likelihoods)
            
            selectedAds.append(relevantAds[selectedAdIndex])
            relevantAds.remove(at: selectedAdIndex)
        }
        
        return selectedAds
    }
    
    private func weightedRandomChoice(weights: [Double]) -> Int {
        let randomValue = Double.random(in: 0..<1)
        var cumulativeWeight = 0.0
        
        let totalCount = weights.count
        
        for i in 0..<totalCount {
            cumulativeWeight += weights[i]
            
            if randomValue < cumulativeWeight {
                return i
            }
        }
        
        return totalCount - 1
    }
}
