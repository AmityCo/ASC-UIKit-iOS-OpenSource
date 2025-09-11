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
        let reactionsDict = AmityUIKitConfigController.shared.config["social_reactions"] as? [[String: String]] ?? [[:]]
        
        var reactionList = [AmityReactionType]()
        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let image: ImageResource? = {
                guard let imageName = item["image"], !imageName.isEmpty else { return nil }
                guard let _ = UIImage(named: imageName, in: AmityUIKit4Manager.bundle, compatibleWith: nil) else { return nil }
                return ImageResource(name: imageName, bundle: AmityUIKit4Manager.bundle)
            }()
            
            let item = AmityReactionType(name: name, image: image ?? AmityIcon.Chat.unknownReaction.imageResource, accessibilityId: item["image"] ?? "")
            reactionList.append(item)
            availableReactions[name] = item
        }
        
        allReactions = reactionList
    }
    
    func getReaction(withName name: String) -> AmityReactionType {
        return availableReactions[name] ?? AmityReactionType(name: name, image: AmityIcon.Chat.unknownReaction.imageResource, accessibilityId: "unknown")
    }
}
