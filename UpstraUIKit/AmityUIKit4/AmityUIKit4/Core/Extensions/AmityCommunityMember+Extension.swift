//
//  AmityCommunityMember+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation
import AmitySDK

enum AmityCommunityRole: String {
    /// Community moderator
    case communityModerator = "community-moderator"
    /// Standart member
    case member
    /// Community moderator.
    @available(*, deprecated, message: "Use communityModerator instead.")
    case moderator
}

extension AmityCommunityMember {
    
    var communityRoles: [AmityCommunityRole] {
        return roles.map { AmityCommunityRole(rawValue: $0) ?? .member }
    }

    var hasModeratorRole: Bool {
        return communityRoles.contains { $0 == .moderator || $0 == .communityModerator }
    }
}
