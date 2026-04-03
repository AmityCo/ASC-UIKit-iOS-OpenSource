//
//  SocialReactionConfiguration.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/13/25.
//
import UIKit

class SocialReactionConfiguration {
    
    static let shared = SocialReactionConfiguration()
    
    public let renderReactionCount = 5
    
    // Keep hashmap of available reactions
    private(set) var availableReactions = [String: AmityReactionType]()
    
    public var allReactions = [AmityReactionType]()

    private init() {
        loadReactions()
    }
    
    private func loadReactions() {
        let reactionsDict = AmityUIKitConfigController.shared.config["social_reactions"] as? [[String: String]] ?? [[:]]
        
        var reactionList = [AmityReactionType]()
        var reactionsMap = [String: AmityReactionType]()

        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let image: ImageResource = {
                guard let imageName = item["image"], !imageName.isEmpty else {
                    return AmityIcon.Chat.unknownReaction.imageResource
                }
                return AmityIcon.loadImageResource(name: imageName)
            }()
            
            let reactionType = AmityReactionType(name: name, image: image, accessibilityId: item["image"] ?? "")
            reactionList.append(reactionType)
            reactionsMap[name] = reactionType
        }
        
        allReactions = reactionList
        availableReactions = reactionsMap
    }
    
    func getReaction(withName name: String) -> AmityReactionType {
        return availableReactions[name] ?? AmityReactionType(name: name, image: AmityIcon.Chat.unknownReaction.imageResource, accessibilityId: "unknown")
    }
    
    func reload() {
        loadReactions()
    }
}
