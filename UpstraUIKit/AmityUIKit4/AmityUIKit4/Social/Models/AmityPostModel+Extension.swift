//
//  AmityPostModel+Extension.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import Foundation
import AmitySDK
import UIKit

extension AmityPostModel {

    public enum LivestreamState {
        case live
        case ended
        case terminated
        case recorded
        case idle
        case error
        case none
        
        var badgeTitle: String {
            switch self {
            case .live:
                return AmityLocalizedStringSet.Social.livestreamPlayerLive.localizedString
            case .recorded:
                return AmityLocalizedStringSet.Social.livestreamPlayerRecorded.localizedString
            case .idle:
                return AmityLocalizedStringSet.Social.livestreamPlayerUpcomingLive.localizedString
            case .none, .ended, .terminated, .error:
                return ""
            }
        }
    }
    
    public struct Author {
        public let avatarURL: String?
        public let displayName: String?
        public let isGlobalBan: Bool
        public let isBrand: Bool
        
        public init( avatarURL: String?, displayName: String?, isGlobalBan: Bool, isBrand: Bool) {
            self.avatarURL = avatarURL
            self.displayName = displayName
            self.isGlobalBan = isGlobalBan
            self.isBrand = isBrand
        }
    }
    
    enum DataType: String {
        case text
        case image
        case file
        case video
        case poll
        case liveStream
        case clip
        case room
        case unknown
    }
}
