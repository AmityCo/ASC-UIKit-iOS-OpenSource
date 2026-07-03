//
//  ChatBehavior.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - AmityChatPageBehavior

open class AmityChatPageBehavior {

    open class Context {
        /// The hosting chat page.
        public let page: AmityChatPage
        /// The user ID whose avatar was tapped (the other participant).
        public let userId: String
        /// The avatar URL of the user, if available.
        public let avatarURL: URL?

        init(page: AmityChatPage, userId: String, avatarURL: URL?) {
            self.page = page
            self.userId = userId
            self.avatarURL = avatarURL
        }
    }

    public init() {}

    open func onAvatarTap(context: AmityChatPageBehavior.Context) {
        guard let avatarURL = context.avatarURL else { return }
        let viewConfig = AmityViewConfigController(pageId: .chatPage)
        guard let presenter = context.page.host.controller else { return }

        var hostingController: UIViewController?
        let viewer = MediaViewer(
            url: avatarURL,
            viewConfig: viewConfig,
            closeAction: { [weak presenter] in
                hostingController?.dismiss(animated: true)
                _ = presenter
            }
        )
        let vc = AmitySwiftUIHostingController(rootView: viewer)
        vc.modalPresentationStyle = .fullScreen
        hostingController = vc
        presenter.present(vc, animated: true)
    }

    static func appendLargeSizeQuery(to url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "size" }) {
            items.append(URLQueryItem(name: "size", value: "large"))
            components.queryItems = items
        }
        return components.url ?? url
    }
}

// MARK: - AmityMessageBubbleBehavior

open class AmityMessageBubbleBehavior {

    open class Context {
        /// The user ID whose avatar was tapped.
        public let userId: String
        /// The avatar URL of the user, if available.
        public let avatarURL: URL?
        /// The view controller that is currently presenting the chat page.
        public weak var sourceViewController: UIViewController?

        init(userId: String, avatarURL: URL?, sourceViewController: UIViewController?) {
            self.userId = userId
            self.avatarURL = avatarURL
            self.sourceViewController = sourceViewController
        }
    }

    public init() {}

    open func onAvatarTap(context: AmityMessageBubbleBehavior.Context) {
        guard let avatarURL = context.avatarURL else { return }
        guard let presenter = context.sourceViewController else { return }
        let viewConfig = AmityViewConfigController(pageId: .chatPage)

        var hostingController: UIViewController?
        let viewer = MediaViewer(
            url: avatarURL,
            viewConfig: viewConfig,
            closeAction: {
                hostingController?.dismiss(animated: true)
            }
        )
        let vc = AmitySwiftUIHostingController(rootView: viewer)
        vc.modalPresentationStyle = .fullScreen
        hostingController = vc
        presenter.present(vc, animated: true)
    }
}
