//
//  AmityMentionTextHighlighter.swift
//  AmityUIKit
//
//  Created by Nishan on 8/7/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK
import UIKit
import SwiftUI

/// Highlights mentions & links and returns AttributedString
class TextHighlighter {
    
    // MARK: UIKit V3 Specific Implementation
    private static func detectAndHighlightLinks(text: String) -> (text: NSMutableAttributedString, hyperlinks: [Hyperlink]) {
        
        let attributedString = NSMutableAttributedString(string: text)
        
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return (attributedString, [])
        }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        var links = [Hyperlink]()
        for match in matches {
            guard let textRange = Range(match.range, in: text) else { continue }
            
            let urlString = String(text[textRange])
            let validUrlString = urlString.hasPrefixIgnoringCase("http") ? urlString : "http://\(urlString)"
            
            guard let formattedString = validUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: formattedString) else { continue }
            
            attributedString.addAttributes([
                .foregroundColor: AmityColorSet.highlight,
                .attachment: url], range: match.range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
            
            links.append(Hyperlink(range: match.range, type: .url(url: url)))
        }
        
        return (attributedString, links)
    }
    
    public static func highlightLinksAndMentions(text: String, metadata: [String: Any], mentionees: [AmityMentionees]) -> (text: NSMutableAttributedString, hyperlinks: [Hyperlink]) {
        
        var attributedString = NSMutableAttributedString(string: text)
        var tappableLinks = [Hyperlink]()
        
        // 1. Detect links & highlight it
        let linkResult = TextHighlighter.detectAndHighlightLinks(text: text)
        attributedString = linkResult.text
        tappableLinks.append(contentsOf: linkResult.hyperlinks)

        // 2.
        // Detect mentions and highlight it. AmityMention array should not be empty
        let mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        if !mentions.isEmpty {
            // Note: From sdk code, AmityMentionees will never contain any information about channel mention.
            var users: [AmityUser] = []
            mentionees.forEach {
                if $0.type == .user, let mentionedUsers = $0.users {
                    users.append(contentsOf: mentionedUsers)
                }
            }
            
            // We generate attributes for part of the text that needs to be highlighted.
            // This can be useful if we want to highlight specific mention with different attributes.
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
                    let mentionAttr = MentionAttribute(attributes: [.foregroundColor: AmityColorSet.highlight, .font: AmityFontSet.bodyBold], range: range, userId: mention.userId ?? "")
                    
                    attributedString.addAttributes(mentionAttr.attributes, range: mentionAttr.range)
                    
                    tappableLinks.append(Hyperlink(range: mentionAttr.range, type: .mention(userId: mentionAttr.userId)))
                }
            }
        }
        
        return (attributedString, tappableLinks)
    }
}
