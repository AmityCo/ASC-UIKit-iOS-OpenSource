//
//  OverflowDetectingText.swift
//  AmityUIKit4
//

import SwiftUI
import SafariServices

// MARK: - Public overflow preference key

struct TextOverflowPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - Internal size-pair key

struct TextSizePairKey: PreferenceKey {
    struct Value: Equatable {
        var clampedHeight: CGFloat = 0
        var naturalHeight: CGFloat = 0
        var isOverflowing: Bool { naturalHeight > clampedHeight + 1 }
    }
    static var defaultValue = Value()
    static func reduce(value: inout Value, nextValue: () -> Value) {
        let n = nextValue()
        if n.clampedHeight > 0 { value.clampedHeight = n.clampedHeight }
        if n.naturalHeight > 0 { value.naturalHeight = n.naturalHeight }
    }
}

// MARK: - OverflowDetectingText

struct OverflowDetectingText: View {

    private enum Content {
        case plain(String)
        case attributed(Any)
    }

    private let content: Content
    private let maxLines: Int

    init(plainText: String, maxLines: Int) {
        self.content = .plain(plainText)
        self.maxLines = maxLines
    }

    @available(iOS 15, *)
    init(attributedText: AttributedString, maxLines: Int) {
        self.content = .attributed(attributedText)
        self.maxLines = maxLines
    }

    var body: some View {
        textView(lines: maxLines)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TextSizePairKey.self,
                        value: TextSizePairKey.Value(clampedHeight: geo.size.height, naturalHeight: 0)
                    )
                }
            )
            .background(
                textView(lines: nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: TextSizePairKey.self,
                                value: TextSizePairKey.Value(clampedHeight: 0, naturalHeight: geo.size.height)
                            )
                        }
                    )
            )
    }

    @ViewBuilder
    private func textView(lines: Int?) -> some View {
        switch content {
        case .plain(let s):
            Text(s)
                .lineLimit(lines)
                .truncationMode(.tail)
        case .attributed(let a):
            if #available(iOS 15, *), let attributed = a as? AttributedString {
                Text(attributed)
                    .lineLimit(lines)
                    .truncationMode(.tail)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Mention & link tap handling

enum ChatInternalLinkRouter {
    /// Consumes every `AmityInternalLink` and returns true; returns false for genuine web links.
    static func handle(_ url: URL, sourceViewController: UIViewController?) -> Bool {
        guard AmityInternalLink.isInternal(url) else { return false }

        // Hashtag & product tag links have no destination in chat.
        if case .mention(let userId)? = AmityInternalLink(url: url) {
            let context = AmityMessageBubbleBehavior.Context(
                userId: userId,
                sourceViewController: sourceViewController
            )
            AmityUIKit4Manager.behaviour.messageBubbleBehavior?.onMentionUserTap(context: context)
        }
        return true
    }
}

@available(iOS 15, *)
private struct ChatUrlTapModifier: ViewModifier {

    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    /// Message bubbles hand plain links to the system browser; the full text page opens them in-app.
    let opensLinkInAppBrowser: Bool

    func body(content: Content) -> some View {
        content.environment(\.openURL, OpenURLAction { url in
            if ChatInternalLinkRouter.handle(url, sourceViewController: host.controller) {
                return .discarded
            }

            guard opensLinkInAppBrowser else { return .systemAction }

            let browserVC = SFSafariViewController(url: url)
            browserVC.modalPresentationStyle = .pageSheet
            UIApplication.topViewController()?.present(browserVC, animated: true)
            return .discarded
        })
    }
}

@available(iOS 15, *)
extension View {
    func handleChatUrlTap(opensLinkInAppBrowser: Bool = false) -> some View {
        modifier(ChatUrlTapModifier(opensLinkInAppBrowser: opensLinkInAppBrowser))
    }
}
