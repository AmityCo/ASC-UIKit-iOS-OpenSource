//
//  MentionEditorTextHighlighter.swift
//  AmityUIKit4
//
//  Created by Nishan on 25/3/2567 BE.
//

import Foundation
import AmitySDK
import UIKit
import SwiftUI

/// Highlights mentions & links and returns AttributedString
@available(iOS 15, *)
class TextHighlighter {
    public static let mentionURL: String = "https://www.amity.co/mentionuser/"
    public static let hashtagURL: String = "https://www.amity.co/hashtag/"
    
    // Helper Method
    public static func getAttributedText(from message: MessageModel, highlightAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue, .font: UIFont.systemFont(ofSize: 15)]) -> AttributedString {
        let messageText = message.text
        
        var highlightedText = AttributedString(messageText)
        
        // If mention is present, highlight mentions first.
        if let metadata = message.metadata {
            highlightedText = AttributedString(highlightMentions(for: messageText, metadata: metadata, mentionees: message.mentionees, highlightAttributes: highlightAttributes))
        }
        
        // If links is present, highlight links
        let links = detectLinks(in: messageText)
        if !links.isEmpty {
            highlightedText = highlightLinks(links: links, in: highlightedText)
        }
        
        return highlightedText
    }
    
    public static func getAttributedText(from comment: AmityCommentModel, highlightAttributes: [NSAttributedString.Key: Any]) -> AttributedString {
        let commentText = comment.text
        
        guard let metadata = comment.metadata else {
            return AttributedString(commentText)
        }
        
        return AttributedString(highlightMentions(for: commentText, metadata: metadata, mentionees: comment.mentionees ?? [], highlightAttributes: highlightAttributes))
    }
    
    /// Returns attributed text where mentions are highlighted.
    public static func highlightMentions(for text: String, metadata: [String: Any], mentionees: [AmityMentionees], highlightAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        // AmityMention array should not be empty
        let mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        guard !mentions.isEmpty else { return NSMutableAttributedString(string: text) }
        
        // Create attributed string
        let highlightedText = getMentionHighlightedAttributedText(in: text, mentions: mentions, mentionees: mentionees, highlightAttributes: highlightAttributes)
        return highlightedText
    }
    
    /// Highlights hashtags in NSMutableAttributedString based on hashtag models
    @discardableResult
    static func highlightHashtags(_ attributedString: NSMutableAttributedString, metadata: [String: Any], highlightAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        /// If the text is, "Hello #A #B"
        /// Here, we will highlight hashtags like #A and #B.
        /// range for first hashtag will be (6, 1) and for second hashtag will be (9, 1) without counting # when we store in SDK.
        ///
        var hashtags: [AmityHashtag] = []
        hashtags = AmityMetadataMapper.hashtags(fromMetadata: metadata)
        
        for hashtag in hashtags {
            // +1 for '#' symbol
            // If the hashtag is at the end of the string, we cannot add +1 to the length as it will out of bound.
            let length = (hashtag.index + hashtag.length + 1) <= attributedString.length ? hashtag.length + 1 : hashtag.length
            let range = NSRange(location: hashtag.index, length: length)
            
            guard range.location >= 0,
                  range.location + range.length <= attributedString.length else {
                continue
            }
            
            // Add highlighting attributes to the adjusted range (including # symbol)
            attributedString.addAttribute(.foregroundColor, value: highlightAttributes[.foregroundColor] ?? UIColor.systemBlue, range: range)
            attributedString.addAttribute(.hashtag, value: true, range: range)
            
            if let font = highlightAttributes[.font] {
                attributedString.addAttribute(.font, value: font, range: range)
            }
            
            // Add link attribute for hashtag tap handling
            let hashtagURL = URL(string: "\(TextHighlighter.hashtagURL)\(hashtag.text)")
            if let url = hashtagURL {
                attributedString.addAttribute(.link, value: url, range: range)
            }
        }
        
        return attributedString
    }
    
    public static func detectLinks(in text: String) -> [String] {
        return AmityPreviewLinkWizard.shared.detectLinks(text: text)
    }
    
    @available(iOS 15, *)
    public static func highlightLinks(links: [String], in string: AttributedString, attributes: [NSAttributedString.Key: Any] = [.underlineStyle: Text.LineStyle(pattern: .solid), .foregroundColor : UIColor.systemBlue]) -> AttributedString {
        var finalStr = string
        
        for link in links {
            let linkRange = finalStr.range(of: link) // Get attributed link here.
            
            // Note:
            // Link without scheme does not get opened when tapping on it.
            // So we modify the scheme when tapping upon link.
            var finalLink = link
            if !link.hasPrefix("http") && !link.hasPrefix("https://") {
                finalLink = "https://" + link
            }
            
            if let linkRange {
                finalStr[linkRange].link = URL(string: finalLink)
                finalStr[linkRange].underlineStyle = attributes[.underlineStyle] as? Text.LineStyle
                finalStr[linkRange].foregroundColor = attributes[.foregroundColor] as? UIColor
                finalStr[linkRange].font = attributes[.font] as? UIFont
            }
        }
        
        return finalStr
    }
    
    @available(iOS 15, *)
    public static func highlightKeyword(keyword: String, in string: AttributedString, attributes: [NSAttributedString.Key: Any]) -> AttributedString {
        
        var finalStr = string
        
        if let keywordRange = finalStr.range(of: keyword, options: [.caseInsensitive]) {
            finalStr[keywordRange].font = attributes[.font] as? UIFont
            finalStr[keywordRange].foregroundColor = attributes[.foregroundColor] as? UIColor
        }
        
        return finalStr
    }
        
    private static func getMentionHighlightedAttributedText(in text: String, mentions: [AmityMention], mentionees: [AmityMentionees], highlightAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        
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
                
                // Update link attribute of mention users to handle tap event
                // SwiftUI need valid url so provide it
                var updatedAttributes = mentionAttr.attributes
                updatedAttributes[.link] = URL(string: "\(TextHighlighter.mentionURL)\(mentionAttr.userId)")
                
                attributedString.addAttributes(updatedAttributes, range: mentionAttr.range)
            }
        }
        
        return attributedString
    }
    
    static func highlightTexts(texts: [(value: String, range: NSRange)], in string: AttributedString, attributes: [NSAttributedString.Key: Any] = [.foregroundColor : UIColor.systemBlue]) -> AttributedString {
        
        var finalStr = string
        
        for item in texts {
            guard let range = Range(item.range, in: string) else { continue }
            finalStr[range].foregroundColor = attributes[.foregroundColor] as? UIColor
            finalStr[range].font = attributes[.font] as? UIFont
            finalStr[range].backgroundColor = attributes[.backgroundColor] as? UIColor
        }
        
        return finalStr
    }
}
