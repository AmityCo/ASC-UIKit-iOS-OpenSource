//
//  MentionManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/16/24.
//

import UIKit
import AmitySDK

struct MentionAttribute {
    let attributes: [NSAttributedString.Key: Any]
    let range: NSRange
    let userId: String
}

class MentionManager {
    
    static func getAttributes(fromText text: String, withMetadata metadata: [String: Any], mentionees: [AmityMentionees], shift: Int = 0, highlightColor: UIColor, highlightFont: UIFont) -> [MentionAttribute] {
        var attributes = [MentionAttribute]()
        
        let mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        if mentions.isEmpty || mentionees.isEmpty { return [] }
        
        var users: [AmityUser] = []
        let mentionee = mentionees[0]
        if mentionee.type == .user, let usersArray = mentionee.users {
            users = usersArray
        }
        
        for mention in mentions {
            if mention.index < 0 || mention.length <= 0 { continue }
            
            var shouldMention = true
            
            if mention.type == .user {
                shouldMention = users.contains(where: { user in
                    user.userId == mention.userId
                })
            }
            
            let range = NSRange(location: mention.index + shift, length: mention.length + 1)
            if shouldMention, range.location != NSNotFound && (range.location + range.length) <= text.count {
                attributes.append(MentionAttribute(attributes: [.foregroundColor: highlightColor, .font: highlightFont], range: range, userId: mention.userId ?? ""))
            }
        }

        return attributes
    }
    
}
