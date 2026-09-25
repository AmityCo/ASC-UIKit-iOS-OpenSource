//
//  AmityDiscoveryWidgetPostCardComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI
import AmitySDK

/// The five content shapes one card can take. Derived from the post, never passed in.
/// Resolution order: poll → media (image / video / clip) → URL in body → text.
enum DiscoveryWidgetCardVariant {
    case text
    case link
    case image
    case video   // covers clip
    case poll

    /// A post with both a body URL and its own media attachments renders the **media** block — media
    /// wins because it is the post's own content, where a link preview is content about somewhere
    /// else. Not shown in Figma (Plan 39 Q13).
    static func resolve(for post: AmityPostModel) -> DiscoveryWidgetCardVariant {
        switch post.dataTypeInternal {
        case .poll:
            return .poll
        case .video, .clip:
            return .video
        case .image:
            return .image
        default:
            return post.links.isEmpty && !containsURL(post.text) ? .text : .link
        }
    }

    private static func containsURL(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        return !AmityPreviewLinkWizard.shared.detectLinks(text: text).isEmpty
    }

    var hasMediaOrPollBlock: Bool {
        switch self {
        case .image, .video, .poll: return true
        case .text, .link: return false
        }
    }
}

/// One cell of the Discovery Widget track: a fixed-width, fixed-height card that renders a post as a
/// **preview**, not as a post.
///
/// It is best understood as the feed's post surface with every interactive affordance removed and
/// every overflow clipped. The whole card is a single tap target; nothing inside it is separately
/// tappable or separately focusable.
///
/// Every suppressed affordance — post menu, author badges, the react/comment/share row, poll vote
/// targets, *Close poll* — is **absent from the composition**, never built-then-hidden. A hidden but
/// mounted control is still reachable by assistive technology, which would break the read-only
/// contract in exactly the place nobody screenshots.
///
/// The **frame** is fixed at 480; the split inside it is not. Header `52` and engagement `36` are
/// constant, and what is left over — `392` — is divided like this:
///
///     text 392                     (no media / poll: the text has the remainder to itself)
///     text  96 + poll 296          (the poll is the one block that does not flex)
///     text ≤96 + media = remainder (the text hugs its caption, the media absorbs the rest)
///
/// So a media post with a one-line caption gets a `36` text block and a `356` media slot, not a `96`
/// block it cannot fill. The media stops shrinking at a `296` slot, past which a long caption
/// truncates instead.
struct AmityDiscoveryWidgetPostCardComponent: AmityComponentView {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var pageId: PageId?

    var id: ComponentId {
        .discoveryWidgetPostCardComponent
    }

    let post: AmityPostModel
    let layout: DiscoveryWidgetLayout
    let onClick: () -> Void

    private let variant: DiscoveryWidgetCardVariant

    init(post: AmityPostModel,
         layout: DiscoveryWidgetLayout,
         pageId: PageId? = nil,
         onClick: @escaping () -> Void) {
        self.post = post
        self.layout = layout
        self.pageId = pageId
        self.onClick = onClick
        self.variant = DiscoveryWidgetCardVariant.resolve(for: post)
    }

    private var cardWidth: CGFloat {
        DiscoveryWidgetMetrics.cardWidth(layout)
    }

    private var hasTextBlock: Bool {
        // A post with media and no caption omits the text block entirely.
        !post.title.isEmpty || !post.text.isEmpty || variant == .poll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiscoveryWidgetCardHeaderView(post: post)

            if hasTextBlock {
                DiscoveryWidgetCardTextView(
                    post: post,
                    variant: variant,
                    height: DiscoveryWidgetMetrics.textBlockHeight(for: variant),
                    onSeeMore: onClick
                )
            }

            // No Spacer: on a media card the media block is the greedy one and takes whatever the
            // caption leaves. A Spacer here would steal that remainder and pin the thumbnail at its
            // floor, which is the bug the fixed-slot reading produced on device.
            contentBlock

            DiscoveryWidgetEngagementBarView(post: post)
        }
        // The card owns the horizontal inset for every slot, so there is one source of truth for it
        // rather than five that can drift apart. Media opts out with a negative inset — the same
        // full-bleed pattern `AmityPostContentComponent` uses in the feed.
        .padding(.horizontal, DiscoveryWidgetMetrics.cardHorizontalInset)
        // `.topLeading`, not `.top`. `.top` centres horizontally, so a child that ends up wider than
        // the card is pulled out past BOTH borders — which reads as the header, title and body
        // losing their inset while full-bleed media looks unchanged, since media covers the card
        // edge to edge either way. Anchoring leading keeps the padded slots put and sends any
        // overflow to the trailing side, where the card's clip removes it.
        .frame(width: cardWidth, height: DiscoveryWidgetMetrics.cardHeight, alignment: .topLeading)
        .background(Color(viewConfig.theme.backgroundColor))
        // The card clips its content — nothing overflows the rounded border.
        .clipShape(RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
        // One focusable element with an activatable role, and one composed name. There is no
        // long-press, context menu, hover card or swipe gesture on the card.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isLink)
    }

    @ViewBuilder
    private var contentBlock: some View {
        switch variant {
        case .text, .link:
            // The link preview renders inside the text slot's budget, not as a sibling block —
            // Figma has it as a child of `Post / Text`. Adding it here would push the engagement
            // bar past the fixed 480.
            EmptyView()

        case .image, .video:
            // Full-bleed: spans the card edge to edge with no inset and no radius of its own; the
            // card's clip provides the rounding at the edges it touches.
            DiscoveryWidgetCardMediaView(post: post, showsPlayIndicator: variant == .video)
                .padding(.horizontal, -DiscoveryWidgetMetrics.cardHorizontalInset)

        case .poll:
            DiscoveryWidgetPollView(post: post, cardWidth: cardWidth)
        }
    }

    /// Composed in reading order. Truncated *visible* text does not truncate the accessible name.
    private var accessibilityLabel: String {
        var parts: [String] = []
        parts.append(post.displayName)

        if let community = post.targetCommunity?.displayName, !community.isEmpty {
            parts.append(community)
        }

        if !post.title.isEmpty { parts.append(post.title) }
        if !post.text.isEmpty { parts.append(post.text) }

        if variant == .poll, let poll = post.poll {
            let results = DiscoveryWidgetPollResults(poll: poll)
            parts.append(poll.question)
            // Percentages are announced as text: the leading option's emphasis is colour and border
            // only, so its leadership must survive without them.
            parts.append(contentsOf: results.visibleOptions.map { "\($0.answer.text) \($0.formattedPercentage)" })
            parts.append(results.statusText)
        }

        parts.append(post.reactionsCount.formattedCountString)
        parts.append(post.allCommentCount.formattedCountString)

        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
