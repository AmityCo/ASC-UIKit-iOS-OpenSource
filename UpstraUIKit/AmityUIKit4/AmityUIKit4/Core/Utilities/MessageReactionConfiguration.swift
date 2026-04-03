//
//  MessageReactionConfiguration.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

class MessageReactionConfiguration {
    
    static let shared = MessageReactionConfiguration()
    
    // Keep hashmap of available reactions
    private(set) var availableReactions = [String: AmityReactionType]()
    
    public var allReactions = [AmityReactionType]()
    
    private init() {
        loadReactions()
    }
    
    private func loadReactions() {
        let reactionsDict = AmityUIKitConfigController.shared.config["message_reactions"] as? [[String: String]] ?? [[:]]
        
        var reactionList = [AmityReactionType]()
        var reactionsMap = [String: AmityReactionType]()
        
        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let imageName = item["image"] ?? ""
            let image = AmityIcon.loadImageResource(name: imageName)
            
            let reactionType = AmityReactionType(name: name, image: image, accessibilityId: imageName)
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

struct AmityReactionType: Identifiable {
    let id: UUID = UUID()
    let name: String
    let image: ImageResource
    let accessibilityId: String
}
