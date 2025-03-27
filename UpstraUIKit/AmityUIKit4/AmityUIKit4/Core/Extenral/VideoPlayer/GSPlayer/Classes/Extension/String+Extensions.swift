//
//  String+Extensions.swift
//  GSPlayer
//
//  Created by Gesen on 2019/4/21.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation
import CommonCrypto
import AmitySDK
import UIKit

extension String {
    
    var deletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    
    var int: Int? {
        return Int(self)
    }
    
    var md5: String {
        guard let data = data(using: .utf8) else { return self }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    var url: URL? {
        return URL(string: self)
    }
    
    func appendingPathComponent(_ str: String) -> String {
        return (self as NSString).appendingPathComponent(str)
    }
    
    func appendingPathExtension(_ str: String) -> String? {
        return (self as NSString).appendingPathExtension(str)
    }
    
    // Extension to support for highlight & mention in texts.
    @available(iOS 15, *)
    func highlight(mentions: AmityMentions?, highlightLink: Bool, highlightAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue, .font: UIFont.systemFont(ofSize: 15)]) -> AttributedString {
                
        let contentText = self
        var highlightedText = AttributedString(contentText)
        
        // If mention is present, highlight mentions first.
        if let mentions {
            highlightedText = TextHighlighter.highlightMentions(for: contentText, metadata: mentions.metadata, mentionees: mentions.mentionees, highlightAttributes: highlightAttributes)
        }
        
        // If links is present, highlight links
        if highlightLink {
            let links = TextHighlighter.detectLinks(in: contentText)
            if !links.isEmpty {
                highlightedText = TextHighlighter.highlightLinks(links: links, in: highlightedText, attributes: highlightAttributes)
            }
        }
        
        return highlightedText
    }
}
