//
//  AmityMediaSize+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import AmitySDK

extension AmityMediaSize {
    
    var description: String {
        switch self {
        case .full:
            return "full"
        case .large:
            return "large"
        case .medium:
            return "medium"
        case .small:
            return "small"
        default:
            return ""
        }
    }
    
}
