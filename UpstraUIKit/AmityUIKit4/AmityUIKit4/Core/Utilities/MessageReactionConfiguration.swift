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
        let reactionsDict = AmityUIKitConfigController.shared.config["message_reactions"] as? [[String: String]] ?? [[:]]
        
        var reactionList = [AmityReactionType]()
        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let image = ImageResource(name: item["image"] ?? "", bundle: AmityUIKit4Manager.bundle)
            
            let item = AmityReactionType(name: name, image: image, accessibilityId: item["image"] ?? "")
            reactionList.append(item)
            availableReactions[name] = item
        }
        
        allReactions = reactionList
    }
    
    func getReaction(withName name: String) -> AmityReactionType {
        return availableReactions[name] ?? AmityReactionType(name: name, image: AmityIcon.Chat.unknownReaction.imageResource, accessibilityId: "unknown")
    }
}

struct AmityReactionType: Identifiable {
    let id: UUID = UUID()
    let name: String
    let image: ImageResource
    let accessibilityId: String
}
