//
//  DiscoveryWidgetPollTextOptionView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// One 80-tall text option: a 12-padded card holding a label + percentage row, a participant line,
/// and the 8-tall progress bar.
///
/// The *and you* sub-frame the feed renders is not built here — the viewer's own vote is irrelevant
/// to a read-only surface, and the widget never shows it.
struct DiscoveryWidgetPollTextOptionView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let option: DiscoveryWidgetPollResults.Option
    let hasVotes: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.pollOptionGap) {
            // Details block — exactly 40: a 20-tall label row over an 18-tall participant row.
            VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.headerRowGap) {
                HStack {
                    Text(option.answer.text)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)

                    Spacer()

                    Text(option.formattedPercentage)
                        .applyTextStyle(.bodyBold(Color(option.isLeading ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                }
                .frame(height: 20)

                Text(participantText)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .lineLimit(1)
                    .frame(height: 18, alignment: .leading)
            }

            DiscoveryWidgetPollProgressBar(share: option.share, isLeading: option.isLeading)
        }
        .padding(DiscoveryWidgetMetrics.pollOptionPadding)
        .frame(height: DiscoveryWidgetMetrics.pollTextOptionHeight)
        // Leading and non-leading differ in four bound properties; the 2 px vs 1 px stroke is the
        // one that is easy to miss.
        .overlay(
            RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                .stroke(
                    Color(option.isLeading ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade4),
                    lineWidth: option.isLeading ? 2 : 1
                )
        )
    }

    /// *No votes* replaces the participant line when the poll has none — a zero-vote poll is a
    /// normal state, not an empty one.
    private var participantText: String {
        guard hasVotes, option.answer.voteCount > 0 else {
            return AmityLocalizedStringSet.Social.pollAnswerResultNoVotes.localizedString
        }

        return option.answer.voteCount > 1
            ? AmityLocalizedStringSet.Social.pollAnswerResultVotedByMultipleParticipants.localized(arguments: option.answer.voteCount.formattedCountString)
            : AmityLocalizedStringSet.Social.pollAnswerResultVotedBySingleParticipant.localizedString
    }
}

/// The progress bar is **ten discrete 10% segments**, not a proportional fill: a 34% share lights
/// three segments, not 34% of the bar. Segments up to the option's share carry the fill; the rest
/// are transparent and show the track behind.
struct DiscoveryWidgetPollProgressBar: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let share: Double
    let isLeading: Bool

    private var filledSegments: Int {
        let count = DiscoveryWidgetMetrics.pollProgressSegmentCount
        return min(count, max(0, Int(share * Double(count))))
    }

    private var trackColor: Color {
        Color(isLeading ? viewConfig.theme.primaryColor.blend(.shade3) : viewConfig.theme.baseColorShade4)
    }

    var body: some View {
        GeometryReader { geometry in
            let count = DiscoveryWidgetMetrics.pollProgressSegmentCount
            let segmentWidth = geometry.size.width / CGFloat(count)

            HStack(spacing: 0) {
                ForEach(Array(0..<count), id: \.self) { index in
                    Rectangle()
                        .fill(index < filledSegments ? Color(viewConfig.theme.primaryColor) : Color.clear)
                        .frame(width: segmentWidth)
                }
            }
            .frame(height: DiscoveryWidgetMetrics.pollProgressBarHeight)
            .background(trackColor)
            .clipShape(Capsule())
        }
        .frame(height: DiscoveryWidgetMetrics.pollProgressBarHeight)
    }
}
