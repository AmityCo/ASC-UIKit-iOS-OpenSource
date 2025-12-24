//
//  AmityPreviewLinkWizard.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/29/24.
//

import AmitySDK
import Foundation
import LinkPresentation

struct PreviewLinkMetadataCache {
    var metadata: AmityLinkPreviewMetadata?
    var timestamp: Date
}

public class AmityPreviewLinkWizard {
    
    public static let shared = AmityPreviewLinkWizard()
    
    private var metadataCache: [String: PreviewLinkMetadataCache] = [:]
    private var linkCache: [String: [String]] = [:]
    
    private init() {}
    
    static let pattern = "(?<![\\w])(?:(?:https?|ftp):\\/\\/(?:[a-zA-Z0-9.-]+|[\\d.]+)(?::\\d{1,5})?(?:\\/(?:[^\\s<>|()]*(?:\\([^\\s<>|()]*\\)[^\\s<>|()]*)*)*)?|mailto:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}|www\\.(?:[a-zA-Z0-9.-]+)(?:\\/(?:[^\\s<>|()]*(?:\\([^\\s<>|()]*\\)[^\\s<>|()]*)*)*)?)?(?=[.,;]?\\s|[.,;]?$|$)"
    
    /// Detects & extracts Link details from provided text using above regex pattern.
    func extractLinks(from text: String) -> [LinkDetail] {
        guard let regex = try? NSRegularExpression(pattern: AmityPreviewLinkWizard.pattern) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty { return [] }
        
        var links = [LinkDetail]()
        matches.forEach {
            let url = nsString.substring(with: $0.range)
            if !url.isEmpty {
                links.append(LinkDetail(range: $0.range, url: nsString.substring(with: $0.range)))
            }
        }
        return links
    }
    
    func detectLinks(text: String) -> [String] {
        if let cachedLinks = linkCache[text] {
            return cachedLinks
        } else {
            // Parsing regex everytime is expensive. So we cache parsed links from post texts.
            // We shouldn't see any performance degradation for even few 1000's texts
            // but it would still be nice to have some limits. Memory concern is negligible here.
            if linkCache.count >= 1000 {
                linkCache = [:]
            }
        }
        
        guard let regex = try? NSRegularExpression(pattern: AmityPreviewLinkWizard.pattern) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty { return [] }
        
        var links = [String]()
        matches.forEach {
            let url = nsString.substring(with: $0.range)
            if !url.isEmpty {
                links.append(url)
            }
        }
        
        linkCache[text] = links
        
        return links
    }
    
    @MainActor
    func fetchLinkMetadata(url: String) async -> AmityLinkPreviewMetadata? {
        guard let _ = URL(string: url) else { return nil }
        
        // Cache & return link data
        if let cache = metadataCache[url], Date().timeIntervalSince(cache.timestamp) < 86400 {
            return cache.metadata
        }
        
        do {
            let metadata = try await AmityUIKit4Manager.client.getLinkPreviewMetadata(url: url)
            metadataCache[url] = PreviewLinkMetadataCache(metadata: metadata, timestamp: Date())
        } catch {
            metadataCache[url] = PreviewLinkMetadataCache(metadata: nil, timestamp: Date())
        }
        
        return metadataCache[url]?.metadata
    }
}

// Extracted link detail from post content
public struct LinkDetail: CustomStringConvertible, Equatable {
    
    let index: Int
    let length: Int
    let url: String
    let range: NSRange
    
    init(range: NSRange, url: String) {
        self.index = range.location
        self.length = range.length
        self.url = url
        self.range = range
    }
    
    init(index: Int, length: Int, url: String) {
        self.index = index
        self.length = length
        self.url = url
        self.range = NSRange(location: index, length: length)
    }
    
    public var description: String {
        return "Index: \(index), Length: \(length), Range: \(range)\n, URL: \(url)"
    }
}

// Might need this later
//
//func detectLinks(input: String) -> [URL] {
//    var links: [URL] = []
//    do {
//        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
//        
//        for match in matches {
//            guard let range = Range(match.range, in: input),
//                  let url = URL(string: {
//                      let rawStr = String(input[range])
//                      if rawStr.hasPrefix("http") {
//                          return rawStr
//                      } else {
//                          return "https://" + rawStr
//                      }
//                  }()) else { continue }
//            
//            links.append(url)
//        }
//    } catch {}
//    
//    return links
//}
