//
//  AmityUserAction.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/9/25.
//

import UIKit
import AmitySDK

struct AmityUserAction {
    
    static func perform(host: AmitySwiftUIHostWrapper? = nil, toastBottomPadding: CGFloat? = nil, _ action: () -> Void) {
        if AmityUIKitManagerInternal.shared.isGuestUser {
            if let guestUserBehavior = AmityUIKit4Manager.behaviour.globalBehavior {
                guestUserBehavior.handleGuestUserAction(context: .init(host: host, toastBottomPadding: toastBottomPadding))
            } else {
                Toast.showToast(style: .info, message: AmityLocalizedStringSet.Social.errorGuestUser.localizedString, bottomPadding: toastBottomPadding ?? Toast.defaultBottomPadding)
            }
        } else {
            action()
        }
    }
}
