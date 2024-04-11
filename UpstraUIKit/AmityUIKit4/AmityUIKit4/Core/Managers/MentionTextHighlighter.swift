//
//  MentionEditorTextHighlighter.swift
//  AmityUIKit4
//
//  Created by Nishan on 25/3/2567 BE.
//

import Foundation
import AmitySDK
import UIKit

/// Highlights mention text and returns as SwiftUI AttributedString
@available(iOS 15, *)
class MentionTextHighlighter {
    
    // Helper Method
    public static func getAttributedText(from message: MessageModel, highlightAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue, .font: UIFont.systemFont(ofSize: 15)]) -> AttributedString {
        let messageText = message.text
        
        guard let metadata = message.metadata else {
            return AttributedString(messageText)
        }
        
        return getAttributedText(for: messageText, metadata: metadata, mentionees: message.mentionees, highlightAttributes: highlightAttributes)
    }
    
    public static func getAttributedText(from comment: AmityCommentModel, highlightAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        let commentText = comment.text
        
        guard let metadata = comment.metadata else {
            return AttributedString(commentText)
        }
        
        return getAttributedText(for: commentText, metadata: metadata, mentionees: comment.mentionees ?? [], highlightAttributes: highlightAttributes)
    }
    
    /// Returns attributed text where mentions are highlighted.
    public static func getAttributedText(for text: String, metadata: [String: Any], mentionees: [AmityMentionees], highlightAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        // AmityMention array should not be empty
        let mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        guard !mentions.isEmpty else { return AttributedString(text) }
        
        // Create attributed string
        let highlightedText = highlightMentions(in: text, mentions: mentions, mentionees: mentionees, highlightAttributes: highlightAttributes)
        return AttributedString(highlightedText)
    }
    
    private static func highlightMentions(in text: String, mentions: [AmityMention], mentionees: [AmityMentionees], highlightAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: text)
        
        // Note: From sdk code, AmityMentionees will never contain any information about channel mention.
        var users: [AmityUser] = []
        mentionees.forEach {
            if $0.type == .user, let mentionedUsers = $0.users {
                users.append(contentsOf: mentionedUsers)
            }
        }
        
        // We generate attributes for part of the text that needs to be highlighted.
        // This can be useful if we want to highlight specific mention with different attributes.
        var attributes = [MentionAttribute]()
        
        for mention in mentions {
            if mention.index < 0 || mention.length <= 0 { continue }
            
            var shouldHighlight = true
            if mention.type == .user {
                // If user is mentioned and the id of the user matches with that present in mentionees array, we highlight that user.
                shouldHighlight = users.contains(where: { user in
                    user.userId == mention.userId
                })
            }
            
            // Create range for highlighting that text. Here length + 1 is for '@' character.
            let range = NSRange(location: mention.index, length: mention.length + 1)
            
            if shouldHighlight, range.location != NSNotFound && (range.location + range.length) <= text.count {
                let mentionAttr = MentionAttribute(attributes: highlightAttributes, range: range, userId: mention.userId ?? "")
                attributes.append(mentionAttr)
                
                attributedString.addAttributes(mentionAttr.attributes, range: mentionAttr.range)
            }
        }
        
        return attributedString
    }
}
