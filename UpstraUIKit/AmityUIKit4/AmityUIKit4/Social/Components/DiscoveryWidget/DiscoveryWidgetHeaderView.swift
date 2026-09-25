//
//  DiscoveryWidgetHeaderView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Widget heading: a single-line title, at both breakpoints.
///
/// The web widget pairs this title with arrow paging at its expanded breakpoint. Mobile has no
/// counterpart — the track is navigated by swipe everywhere, so there is no navigation control here
/// and nothing for `showHeader` to hide beyond the title itself.
struct DiscoveryWidgetHeaderView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let title: String
    let layout: DiscoveryWidgetLayout
    /// While the pool is outstanding the title is unknown — `topicName` is API-sourced — so the
    /// design hides the text and shows a pill in its place rather than an empty heading.
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                Capsule()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: DiscoveryWidgetMetrics.headingSkeletonWidth,
                           height: DiscoveryWidgetMetrics.headingSkeletonHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            } else {
                Text(title)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .frame(height: DiscoveryWidgetMetrics.headingHeight(layout))
        .padding(.horizontal, DiscoveryWidgetMetrics.headingHorizontalInset(layout))
    }
}
