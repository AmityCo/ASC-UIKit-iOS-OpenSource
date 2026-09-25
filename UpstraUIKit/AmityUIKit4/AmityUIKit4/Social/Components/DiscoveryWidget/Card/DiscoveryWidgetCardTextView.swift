//
//  DiscoveryWidgetCardTextView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// The card's text slot — the only variable slot in the 480 budget, and it takes exactly one of two
/// values: `392` with no media or poll, `96` with. It is not a free remainder.
///
/// Whichever text runs out of room truncates with a trailing *See more*. That affordance is
/// **decoration, not a control**: it never expands the card, it is not focusable, and tapping it
/// does exactly what tapping anywhere else on the card does. Mentions and hashtags render as plain
/// styled text — they are not tappable links inside the widget.
struct DiscoveryWidgetCardTextView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme

    /// The title's *rendered* height, not its reserved one. The body's line count is derived from
    /// whatever the title actually leaves behind; see `bodyLineLimit`.
    @State private var measuredTitleHeight: CGFloat = 0

    let post: AmityPostModel
    let variant: DiscoveryWidgetCardVariant
    /// The slot height. Ignored on a media card, where the block hugs its content outright so the
    /// media can absorb the remainder; the exact height everywhere else.
    let height: CGFloat
    let onSeeMore: () -> Void

    /// Only a media card's text hugs — the poll block is fixed at `296` and a text-only card has the
    /// whole remainder to itself, so in both of those the text fills its slot.
    private var hugsContent: Bool {
        variant == .image || variant == .video
    }

    /// Beside media or a poll, title and body each cap independently — one line and two lines — and
    /// otherwise hug. That is what the design measures: `8 + 24 + 16 + 40 + 8 = 96` at the cap, a
    /// one-line caption alone at `36`, a two-line one at `56`. A text-only card has no competitor
    /// for the space, so its title may run to four lines and its body takes the rest.
    private var capsIndependently: Bool {
        variant == .image || variant == .video || variant == .poll
    }

    /// For a poll post the title slot carries the **question** — the poll block itself begins at the
    /// options list.
    private var titleText: String {
        if variant == .poll, let poll = post.poll {
            return poll.question
        }
        return post.title
    }

    private var bodyText: String {
        variant == .poll ? "" : post.text
    }

    /// Content box after the 8 top and 8 bottom padding.
    private var contentHeight: CGFloat {
        height - (DiscoveryWidgetMetrics.textBlockVerticalPadding * 2)
    }

    /// The link preview is a child of the text slot, not a sibling, so it eats into the same budget.
    private var showsLinkPreview: Bool {
        variant == .link
    }

    /// Space the texts actually get, once the preview and its gap are taken out.
    private var textAreaHeight: CGFloat {
        guard showsLinkPreview else { return contentHeight }
        return contentHeight - DiscoveryWidgetMetrics.linkPreviewHeight - DiscoveryWidgetMetrics.linkPreviewTopGap
    }

    /// The title's own cap. Beside media or a poll it is one line flat; in the tall slot it wraps up
    /// to four before the body takes the remainder — unless there is no body, in which case nothing
    /// is competing for the space and the title simply fills it.
    private var titleLineLimit: Int {
        guard !titleText.isEmpty else { return 0 }

        if capsIndependently {
            return DiscoveryWidgetMetrics.titleLineLimitBesideMedia
        }

        let maxLines = max(1, Int(textAreaHeight / DiscoveryWidgetMetrics.renderedTitleLineHeight))
        guard !bodyText.isEmpty else { return maxLines }
        return min(DiscoveryWidgetMetrics.titleMaxLinesInTallSlot, maxLines)
    }

    /// How many body lines fit **under the title as drawn**.
    ///
    /// This used to reserve the title's cap — four lines, 96 points — whatever the title actually
    /// measured. A one-line title therefore cost the body four lines' worth of budget, and the *See
    /// more* landed three or four lines above the bottom of the slot with visible empty space beneath
    /// it. The title's height does not depend on the body, so reading it back is a settled one-way
    /// measurement, not a layout loop.
    private var bodyLineLimit: Int {
        guard !bodyText.isEmpty else { return 0 }

        if capsIndependently {
            return DiscoveryWidgetMetrics.bodyLineLimitBesideMedia
        }

        guard !titleText.isEmpty else {
            return max(1, Int(textAreaHeight / DiscoveryWidgetMetrics.renderedBodyLineHeight))
        }

        // The estimate is only what the first pass draws with, before the measurement lands.
        let titleHeight = measuredTitleHeight > 0
            ? measuredTitleHeight
            : CGFloat(titleLineLimit) * DiscoveryWidgetMetrics.renderedTitleLineHeight

        let remaining = textAreaHeight - titleHeight - DiscoveryWidgetMetrics.textTitleToBodyGap
        return max(1, Int(remaining / DiscoveryWidgetMetrics.renderedBodyLineHeight))
    }

    var body: some View {
        // Two nested stacks rather than one: the 16 title→body gap must not also apply to the gap
        // before the preview. A `Spacer` in a spaced stack is spaced on *both* sides, so the flat
        // version charged `16 + spacer + 16` where the budget had reserved a single gap, and the
        // preview overflowed the slot by that much and was clipped by the card.
        VStack(alignment: .leading, spacing: 0) {
            texts

            if showsLinkPreview {
                // Slack collects above the preview; it stays flush with the bottom of the slot,
                // which is where the design's exactly-filled 392 puts it.
                Spacer(minLength: DiscoveryWidgetMetrics.linkPreviewTopGap)

                DiscoveryWidgetLinkPreviewView(post: post)
                    .frame(height: DiscoveryWidgetMetrics.linkPreviewHeight)
            } else if !hugsContent {
                // Pushes the text to the top of a slot it does not fill. A hugging block has no
                // slack to push into, and a Spacer there would stop it hugging at all.
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, DiscoveryWidgetMetrics.textBlockVerticalPadding)
        // No height constraint at all when hugging. A `maxHeight` here would let a mis-sized line
        // budget clamp the block to the cap and hand the media a constant `296`, which is exactly
        // how the thumbnail stopped growing before: the caps bound the text, not a frame.
        .frame(height: hugsContent ? nil : height, alignment: .top)
    }

    @ViewBuilder
    private var texts: some View {
        VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.textTitleToBodyGap) {
            if !titleText.isEmpty {
                Text(titleText)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(titleLineLimit)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear { measuredTitleHeight = geometry.size.height }
                                .onChange(of: geometry.size.height) { measuredTitleHeight = $0 }
                        }
                    )
            }

            if !bodyText.isEmpty {
                // `defaultAction` is what makes *See more* inert: ExpandableText defers to it instead
                // of toggling `isExpanded`, so the tap falls through to the card exactly as REQ-021
                // requires.
                ExpandableText(bodyText,
                               defaultAction: onSeeMore,
                               metadata: post.metadata,
                               mentionees: post.mentionees,
                               productTags: nil,
                               links: post.links,
                               fadeTruncatedText: false)
                    .lineLimit(bodyLineLimit)
                    .moreButtonText(AmityLocalizedStringSet.Social.expandableTextSeeMore.localizedString)
                    .font(AmityTextStyle.body(.clear).getFont())
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .attributedColor(UIColor.defaultAttributeColor(viewConfig: viewConfig, colorScheme: colorScheme))
                    .hashtagColor(UIColor.defaultAttributeColor(viewConfig: viewConfig, colorScheme: colorScheme))
                    .moreButtonColor(Color(viewConfig.theme.primaryColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
