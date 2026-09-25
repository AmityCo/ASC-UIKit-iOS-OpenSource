//
//  DiscoveryWidgetEngagementBarView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Engagement bar — 36 tall, 16 horizontal inset, its 20-tall stat row vertically centred.
///
/// **Counts only.** The react / comment / share row the feed carries is not built here at all, and
/// neither count is independently tappable — the comment count does not open a comment tray.
///
/// The bar renders even at zero reactions and zero comments, so the card's height budget stays
/// deterministic. Every Figma specimen shows a non-zero count, so the zero rendering is inferred
/// (Plan 39 Q14).
struct DiscoveryWidgetEngagementBarView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let post: AmityPostModel

    var body: some View {
        HStack(spacing: DiscoveryWidgetMetrics.engagementGap) {
            reactionSummary

            Spacer(minLength: 0)

            Text(commentCountText)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                .lineLimit(1)
        }
        .frame(height: DiscoveryWidgetMetrics.engagementRowHeight)
        .padding(.vertical, DiscoveryWidgetMetrics.engagementVerticalPadding)
        .frame(height: DiscoveryWidgetMetrics.engagementHeight)
        .accessibilityHidden(true)
    }

    private var hasReactions: Bool {
        post.reactionsCount > 0
    }

    /// Stacked reaction glyphs, then the aggregate. Both counts are `Base/Shade2` — the reaction
    /// aggregate is *not* `Base/Default`.
    ///
    /// At zero the glyph stack is gone and the bare number is replaced by *0 reactions*, which is
    /// how Figma draws it (`I1072:128120;20484:29801`, annotated *empty reactions and comments*):
    /// a lone `0` beside `0 comments` reads as a broken value rather than an empty one.
    @ViewBuilder
    private var reactionSummary: some View {
        HStack(spacing: 4) {
            if hasReactions {
                HStack(spacing: -8) {
                    ForEach(Array(post.allReactions.prefix(SocialReactionConfiguration.shared.renderReactionCount).enumerated()), id: \.element) { index, reaction in
                        let reactionType = SocialReactionConfiguration.shared.getReaction(withName: reaction)
                        Circle()
                            .fill(Color(viewConfig.theme.backgroundColor))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(reactionType.image)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                            )
                            .zIndex(Double(post.allReactions.count - index))
                    }
                }
            }

            Text(reactionCountText)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                .lineLimit(1)
        }
    }

    /// Only the empty state is worded — with glyphs beside it the number stands on its own, which is
    /// what every non-zero specimen shows.
    private var reactionCountText: String {
        let count = post.reactionsCount.formattedCountString
        return hasReactions
            ? count
            : AmityLocalizedStringSet.Social.discoveryWidgetReactionCountPlural.localized(arguments: count)
    }

    private var commentCountText: String {
        post.allCommentCount == 1
            ? AmityLocalizedStringSet.Social.postCommentCountSingular.localized(arguments: post.allCommentCount.formattedCountString)
            : AmityLocalizedStringSet.Social.postCommentCountPlural.localized(arguments: post.allCommentCount.formattedCountString)
    }
}
