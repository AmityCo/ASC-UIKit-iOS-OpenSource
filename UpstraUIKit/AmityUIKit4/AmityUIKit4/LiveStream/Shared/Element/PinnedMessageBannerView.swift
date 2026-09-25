//
//  PinnedMessageBannerView.swift
//  AmityUIKit4
//
//  The pinned-message banner shown above the live chat for every viewer. Presentational:
//  the parent resolves the byline (display name, badges, muted) and `canPin` and passes them in.
//

import SwiftUI
import AmitySDK

struct PinnedMessageBannerView: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?
    var id: ElementId { .pinnedMessageBanner }

    // MARK: - Inputs (resolved by the parent)

    /// The pinned message body text.
    let messageText: String
    /// Author display name.
    let displayName: String
    /// Author is a verified brand.
    let isBrand: Bool
    /// Author badges.
    let isHost: Bool
    let isCoHost: Bool
    let isModerator: Bool
    /// Author is muted (shows the muted icon in the byline).
    let isMutedAuthor: Bool
    /// Whether the current user may unpin (shows the "X").
    let canPin: Bool
    /// Called when the current user taps "X" to unpin.
    let onUnpin: () -> Void
    /// Expanded state, owned by the parent view model so it survives the banner being rebuilt on
    /// channel churn and only resets when a genuinely new message is pinned.
    @Binding var isExpanded: Bool

    @EnvironmentObject var viewConfig: AmityViewConfigController

    @State private var fullTextHeight: CGFloat = 0
    @State private var singleLineHeight: CGFloat = 0
    /// Width available to the message text — used to pre-truncate the collapsed line so the inline
    /// "more" fits on one line without being clipped.
    @State private var availableWidth: CGFloat = 0

    /// Whether the text spans more than one line (so more/less applies).
    private var isTruncatable: Bool {
        fullTextHeight > singleLineHeight + 1
    }

    // Caption style, resolved once for the concatenated Text runs and for width measurement.
    private var captionFont: Font { AmityTextStyle.caption(.clear).getFont() }
    private var captionUIFont: UIFont { AmityTextStyle.caption(.clear).getUIFont() }
    private var messageColor: Color { Color(viewConfig.theme.baseColor) }
    private var toggleColor: Color { Color(viewConfig.theme.baseColor) }
    private var moreText: String { AmityLocalizedStringSet.LiveChat.pinnedMessageMore.localizedString }
    private var lessText: String { AmityLocalizedStringSet.LiveChat.pinnedMessageLess.localizedString }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            bylineRow
            messageBody
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color(AmityFixedColor.shared.liveStreamChatBubblePinned)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard isTruncatable else { return }
            withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
        }
        .accessibilityIdentifier(AccessibilityID.Chat.LivePinnedMessage.container)
    }

    // MARK: - Byline

    private var bylineRow: some View {
        HStack(spacing: 6) {
            LiveStreamChatBylineView(
                displayName: displayName,
                isBrand: isBrand,
                isHost: isHost,
                isCoHost: isCoHost,
                isModerator: isModerator,
                showMutedIcon: isMutedAuthor
            )

            Spacer(minLength: 8)

            pinnedPill

            if canPin {
                Button(action: onUnpin) {
                    Image(AmityIcon.LiveStream.close.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.Chat.LivePinnedMessage.unpinButton)
            }
        }
    }

    /// The whole "Pinned" pill (background + pin glyph + label) is a single baked image (57×17).
    private var pinnedPill: some View {
        Image(AmityIcon.LiveStream.pinnedLivestreamMessage.imageResource)
            .resizable()
            .scaledToFit()
            .frame(width: 57, height: 17)
            .accessibilityIdentifier(AccessibilityID.Chat.LivePinnedMessage.pinnedPill)
    }

    // MARK: - Message body + more/less

    private var messageBody: some View {
        Group {
            if isExpanded {
                expandedText
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(AccessibilityID.Chat.LivePinnedMessage.messageText)
            } else {
                collapsedText
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(AccessibilityID.Chat.LivePinnedMessage.messageText)
            }
        }
        .background(textMeasurement)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { availableWidth = $0 }
            }
        )
    }

    /// Expanded: full text with "less" flowing directly after the last word (one wrapping Text).
    private var expandedText: Text {
        let body = Text(messageText).font(captionFont).foregroundColor(messageColor)
        guard isTruncatable else { return body }
        let gap = Text("  ").font(captionFont)
        let less = Text(lessText).font(captionFont).foregroundColor(toggleColor).underline()
        return body + gap + less
    }

    /// Collapsed: message pre-truncated to the longest prefix that fits one line alongside "… more",
    /// then "more" appended inline. Because it already fits, `lineLimit(1)` never clips "more".
    private var collapsedText: Text {
        guard isTruncatable, availableWidth > 0 else {
            return Text(messageText).font(captionFont).foregroundColor(messageColor)
        }
        let suffix = "… " + moreText
        let prefix = fittingPrefix(of: messageText, width: availableWidth, suffixWidth: width(of: suffix))
        return Text(prefix + "… ").font(captionFont).foregroundColor(messageColor)
            + Text(moreText).font(captionFont).foregroundColor(toggleColor).underline()
    }

    private func width(of string: String) -> CGFloat {
        (string as NSString).size(withAttributes: [.font: captionUIFont]).width
    }

    /// Longest prefix (by character, emoji-safe) of `text` whose width fits `width - suffixWidth`.
    private func fittingPrefix(of text: String, width: CGFloat, suffixWidth: CGFloat) -> String {
        let available = max(0, width - suffixWidth)
        let chars = Array(text)
        var lo = 0, hi = chars.count, best = 0
        while lo <= hi {
            let mid = (lo + hi) / 2
            if self.width(of: String(chars[0..<mid])) <= available { best = mid; lo = mid + 1 }
            else { hi = mid - 1 }
        }
        var prefix = String(chars[0..<best])
        while prefix.hasSuffix(" ") { prefix.removeLast() }
        return prefix
    }

    /// Hidden measurement: the full (unbounded) text height vs a single line, to detect truncation.
    private var textMeasurement: some View {
        ZStack {
            Text(messageText)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear { fullTextHeight = geo.size.height }
                        .onChange(of: geo.size.height) { fullTextHeight = $0 }
                })
            Text("Ag")
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear { singleLineHeight = geo.size.height }
                        .onChange(of: geo.size.height) { singleLineHeight = $0 }
                })
        }
        .hidden()
    }
}
