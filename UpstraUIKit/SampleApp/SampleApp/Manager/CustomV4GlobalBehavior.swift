//
//  CustomV4GlobalBehavior.swift
//  SampleApp
//
//  Created by prisa dumrongsiri on 3/9/26.
//  Copyright © 2026 Eko. All rights reserved.
//

import Foundation
import AmityUIKit4

class CustomV4GlobalBehavior: AmityGlobalBehavior {
    override func handleVisitorUsageLimitSignIn() {
        Toast.showToast(style: .warning, message: "Create an account or sign in to continue.")
        AppManager.shared.unregister()
    }
    
    /// With the "In-app PiP Testing" switch ON, a product tag tapped inside the
    /// livestream opens the Social home page instead of the product URL — an in-app
    /// navigation away from the player, which is what should hand the stream off to the
    /// PiP window. Only the livestream hook is overridden: product tags on ordinary posts
    /// have no stream to hand off, so they keep the default in-app browser.
    override func onLivestreamProductTagClick(context: AmityGlobalBehavior.Context) {
        guard LoginConfigStore.shared.inAppPipTesting else {
            super.onLivestreamProductTagClick(context: context)
            return
        }
        AppManager.shared.openHomeForInAppPiPTest()
    }
}
