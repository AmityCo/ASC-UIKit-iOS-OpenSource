//
//  AmityUserAction.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/9/25.
//

import AmitySDK

struct AmityUserAction {
    
    static func perform(host: AmitySwiftUIHostWrapper? = nil, _ action: () -> Void) {
        if AmityUIKitManagerInternal.shared.isGuestUser {
            if let guestUserBehavior = AmityUIKit4Manager.behaviour.globalBehavior {
                guestUserBehavior.handleGuestUserAction(context: .init(host: host))
            } else {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.errorGuestUser.localizedString)
            }
        } else {
            action()
        }
    }
}
