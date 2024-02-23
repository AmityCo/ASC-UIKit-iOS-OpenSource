//
//  URLHelper.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/25/24.
//

import Foundation

class URLHelper {
    private init() {}
    
    static func concatProtocolIfNeeded(urlStr: String) -> URL? {
        return URL(string: {
            if urlStr.hasPrefix("http") {
                return urlStr
            } else {
                return "https://" + urlStr
            }
        }())
    }
}
