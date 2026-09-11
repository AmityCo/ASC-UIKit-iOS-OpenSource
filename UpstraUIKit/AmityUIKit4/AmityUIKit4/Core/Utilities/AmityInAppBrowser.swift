//
//  AmityInAppBrowser.swift
//  AmityUIKit4
//
//  Single entry point for opening an in-app browser (SFSafariViewController).
//
//

import UIKit
import SafariServices

enum AmityInAppBrowser {

    static func present(url: URL,
                        modalPresentationStyle: UIModalPresentationStyle = .pageSheet,
                        animated: Bool = true,
                        from presenter: UIViewController? = UIApplication.topViewController()) {
        // Supports pip only for livestream + recorded video
        PiPState.shared.startPiPIfNeeded()

        let browserVC = SFSafariViewController(url: url)
        browserVC.modalPresentationStyle = modalPresentationStyle
        presenter?.present(browserVC, animated: animated)
    }
}
