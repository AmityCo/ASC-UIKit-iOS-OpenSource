//
//  DiscoveryWidgetPollImageOptionView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// One image poll option: a 12-padded card holding a thumbnail with the percentage centred over a
/// scrim, then a caption over a voter line. Two per row.
///
/// The percentage binds `white_color`, **not** `base_inverse_color` — the latter is black in light
/// mode, which would paint the value black on a dark scrim.
struct DiscoveryWidgetPollImageOptionView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let option: DiscoveryWidgetPollResults.Option
    let hasVotes: Bool
    let width: CGFloat

    @State private var imageLoadFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnail

            Text(option.answer.text)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .frame(height: DiscoveryWidgetMetrics.pollImageCaptionHeight, alignment: .leading)
                .padding(.top, DiscoveryWidgetMetrics.pollImageThumbnailToLabelGap)

            Text(voterText)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                .lineLimit(1)
                .frame(height: DiscoveryWidgetMetrics.pollImageVoterRowHeight, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(DiscoveryWidgetMetrics.pollOptionPadding)
        .frame(width: width, height: DiscoveryWidgetMetrics.pollImageOptionHeight, alignment: .top)
        .overlay(
            RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                .stroke(
                    Color(option.isLeading ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade4),
                    lineWidth: option.isLeading ? 2 : 1
                )
        )
    }

    /// A missing thumbnail keeps the option's geometry and still carries the percentage.
    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            AsyncImage(
                placeholderView: {
                    RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.pollImageThumbnailCornerRadius)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                },
                url: URL(string: option.answer.image?.mediumFileURL ?? ""),
                contentMode: .fill
            )
            .onLoaded { isLoaded in
                if !isLoaded { imageLoadFailed = true }
            }
            .frame(height: DiscoveryWidgetMetrics.pollImageThumbnailHeight)
            .cornerRadius(DiscoveryWidgetMetrics.pollImageThumbnailCornerRadius)

            if imageLoadFailed {
                Image(AmityIcon.pollImageNotAvailableIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            }

            // Scrim, so the value stays legible on any image.
            Color.black.opacity(0.3)
                .cornerRadius(DiscoveryWidgetMetrics.pollImageThumbnailCornerRadius)

            Text(option.formattedPercentage)
                .applyTextStyle(.headline(.white))
                .lineLimit(1)

            // Decorative expand glyph. It opens nothing here — the card click applies. Whether it
            // should render at all on a read-only surface is unresolved (Plan 39 Q18).
            VStack {
                HStack {
                    Spacer()
                    Image(AmityIcon.pollImageExpandIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                Spacer()
            }
            .padding(6)
        }
        .frame(height: DiscoveryWidgetMetrics.pollImageThumbnailHeight)
    }

    private var voterText: String {
        guard hasVotes, option.answer.voteCount > 0 else {
            return AmityLocalizedStringSet.Social.pollAnswerResultNoVotes.localizedString
        }
        return AmityLocalizedStringSet.Social.discoveryWidgetPollVotersCount
            .localized(arguments: option.answer.voteCount.formattedCountString)
    }
}
