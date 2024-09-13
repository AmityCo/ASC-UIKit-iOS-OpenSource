//
//  AmityUserModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/13/24.
//

import Foundation
import AmitySDK

public struct AmityUserModel: Equatable {
    
    let userId: String
    let displayName: String
    let avatarURL: String
    let about: String
    let isGlobalBan: Bool
    let isBrand: Bool
    
    init(user: AmityUser) {
        userId = user.userId
        displayName = user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        avatarURL = user.getAvatarInfo()?.fileURL ?? ""
        about = user.userDescription
        isGlobalBan = user.isGlobalBanned
        isBrand = user.isBrand
    }
    
    var isCurrentUser: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
}
