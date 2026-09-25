//
//  DiscoveryWidgetCardHeaderView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Card header — 52 tall, `pad=12/16/0/16`. Avatar, then a 20-tall title row over an 18-tall
/// subtitle row.
///
/// Three slots the feed's header carries are **not built here**: the author role badge, its
/// separator dot, and the post-options ellipsis. They are suppressed at composition, not hidden
/// after mounting. The brand badge is *not* one of them — it rides with the author name and is drawn
/// wherever the name is (`UserDisplayNameLabel`). Nothing in the header is independently tappable —
/// the avatar does not open a profile and the community name does not open a community.
struct DiscoveryWidgetCardHeaderView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let post: AmityPostModel

    var body: some View {
        HStack(alignment: .top, spacing: DiscoveryWidgetMetrics.avatarToContentGap) {
            AmityUserProfileImageView(
                displayName: post.postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString,
                avatarURL: URL(string: post.postedUser?.avatarURL ?? "")
            )
            .frame(width: DiscoveryWidgetMetrics.avatarSize, height: DiscoveryWidgetMetrics.avatarSize)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.headerRowGap) {
                titleRow
                    .frame(height: 20)

                Text(post.timestamp)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .lineLimit(1)
                    .frame(height: 18, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, DiscoveryWidgetMetrics.headerTopPadding)
        .frame(height: DiscoveryWidgetMetrics.headerHeight, alignment: .top)
    }

    /// Display name › community name, with the verified badge trailing. Both names truncate; the
    /// community name gives way first so the author is never fully lost.
    @ViewBuilder
    private var titleRow: some View {
        HStack(spacing: DiscoveryWidgetMetrics.headerNameGap) {
            UserDisplayNameLabel(name: post.displayName, isBrand: post.isFromBrand)
                .layoutPriority(1)

            if let community = post.targetCommunity {
                Image(AmityIcon.arrowIcon.getImageResource())
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    // Glyph inside box, not glyph *as* box — see `toArrowGlyphSize`.
                    .frame(width: DiscoveryWidgetMetrics.toArrowGlyphSize,
                           height: DiscoveryWidgetMetrics.toArrowGlyphSize)
                    .frame(width: DiscoveryWidgetMetrics.toArrowSize, height: DiscoveryWidgetMetrics.toArrowSize)

                Text(community.displayName)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)

                if post.isTargetOfficialCommunity {
                    Image(AmityIcon.getImageResource(named: "verifiedBadge"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
