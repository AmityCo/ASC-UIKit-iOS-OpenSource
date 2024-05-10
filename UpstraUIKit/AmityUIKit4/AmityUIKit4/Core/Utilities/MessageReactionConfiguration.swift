//
//  MessageReactionConfiguration.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

class MessageReactionConfiguration {
    
    static var shared = MessageReactionConfiguration()
    
    func getMessageRactions() -> [AmityReactionType] {

        if let reactionsConfig = AmityUIKitConfigController.shared.config["message_reactions"] as? [[String: String]] {
            var reactionType = [AmityReactionType]()
            for reaction in reactionsConfig {
                reactionType.append(AmityReactionType(name: reaction["name"] ?? "", image: ImageResource(name: reaction["image"] ?? "", bundle: AmityUIKit4Manager.bundle)))
            }
            return reactionType
        } else {
            return []
        }
    }
}
