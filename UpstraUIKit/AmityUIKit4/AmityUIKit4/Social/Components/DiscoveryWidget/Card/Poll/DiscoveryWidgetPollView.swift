//
//  DiscoveryWidgetPollView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Read-only poll results — the fixed 296 block.
///
/// The widget **inverts two rules** that hold everywhere else in the product:
///
/// 1. **Results are always revealed.** In the feed a viewer must vote, or the poll must close,
///    before results appear. Here every viewer sees percentages immediately — ongoing or ended,
///    voted or not. There is no reveal transition, no blur, no "tap to see results", no *Vote*
///    control.
/// 2. **Options are re-ordered.** The leading option is always shown first, regardless of the
///    authored order. This is the only surface in the product that re-orders poll options.
///
/// Everything here is inert: no option is selectable or focusable, *See full results* is not a
/// button, and the *Close poll* slot the feed carries is not built at all — poll moderation is never
/// available in the widget, even to an author viewing their own poll.
struct DiscoveryWidgetPollView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let post: AmityPostModel
    let cardWidth: CGFloat

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        if let poll = post.poll {
            let results = DiscoveryWidgetPollResults(poll: poll)

            VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.pollOptionsToFooterGap) {
                if poll.isImagePoll {
                    LazyVGrid(columns: columns, spacing: DiscoveryWidgetMetrics.pollOptionGap) {
                        ForEach(results.visibleOptions) { option in
                            DiscoveryWidgetPollImageOptionView(
                                option: option,
                                hasVotes: results.hasVotes,
                                width: DiscoveryWidgetMetrics.pollImageOptionWidth(cardWidth: cardWidth)
                            )
                        }
                    }
                } else {
                    VStack(spacing: DiscoveryWidgetMetrics.pollOptionGap) {
                        ForEach(results.visibleOptions) { option in
                            DiscoveryWidgetPollTextOptionView(option: option, hasVotes: results.hasVotes)
                        }
                    }
                }

                DiscoveryWidgetPollFooterView(statusText: results.statusText)
            }
            .padding(.top, DiscoveryWidgetMetrics.pollTopPadding)
            .frame(height: DiscoveryWidgetMetrics.pollBlockHeight, alignment: .top)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// *See full results* is always rendered, regardless of poll status or vote count — which is what
/// makes capping the visible options acceptable. It is **not a control**: it is inside the card's
/// single tap target, is not focusable, and is hidden from assistive technology.
struct DiscoveryWidgetPollFooterView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let statusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.pollFooterRowGap) {
            HStack {
                Spacer()
                Text(AmityLocalizedStringSet.Social.pollSeeFullResultsLabel.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                Spacer()
            }
            .frame(height: DiscoveryWidgetMetrics.pollSeeFullResultsHeight)
            .overlay(
                RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                    .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 1)
            )

            Text(statusText)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                .lineLimit(1)
                .frame(height: DiscoveryWidgetMetrics.pollStatusRowHeight, alignment: .leading)
        }
        .frame(height: DiscoveryWidgetMetrics.pollFooterHeight, alignment: .top)
    }
}
