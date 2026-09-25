//
//  DiscoveryWidgetSkeletonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// The loading treatment — skeleton cards in place of posts, drawn in Figma at `1176:92972`.
///
/// A skeleton card is **two slots only**: header `52` → text `428`, summing to the standard `480`.
/// The media, poll and **engagement** blocks are all hidden while loading, and the text slot absorbs
/// the engagement bar's `36` — which is why it is `428` here and never `392`. The skeleton shows no
/// counts of any kind: no reaction summary, no comment count, and nothing standing in for them.
///
/// Every bar and the avatar block bind `Base/Shade4` at `cornerRadius: 40` — fully rounded pills,
/// not rectangles.
struct DiscoveryWidgetSkeletonView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let layout: DiscoveryWidgetLayout

    /// Enough to overflow both breakpoints, matching the four drawn in the Figma frame.
    private let placeholderCardCount = 4

    private let barHeight: CGFloat = 8

    var body: some View {
        // A horizontal ScrollView, disabled — the same primitive the rendered track uses.
        //
        // A bare HStack reports its *intrinsic* width, and four cards is 1428pt compact / 1548pt
        // expanded. That width propagated up through the widget's VStack to the GeometryReader that
        // measures `containerWidth`, which then read ~1548 and selected the expanded breakpoint on a
        // 440pt phone — which in turn made the skeleton wider still. `.clipped()` did not stop it:
        // clipping changes what is drawn, not what is reported. A ScrollView always reports the
        // width it was proposed and never its content's, so the loop cannot start.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DiscoveryWidgetMetrics.cardGap(layout)) {
                ForEach(Array(0..<placeholderCardCount), id: \.self) { _ in
                    skeletonCard
                }
            }
            .padding(.horizontal, DiscoveryWidgetMetrics.trackInset(layout))
        }
        // Nothing to navigate yet, and the nav buttons are disabled while loading.
        .disabled(true)
        .frame(height: DiscoveryWidgetMetrics.cardHeight)
        .accessibilityHidden(true)
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSlot
            textSlot
            Spacer(minLength: 0)
        }
        .frame(width: DiscoveryWidgetMetrics.cardWidth(layout), height: DiscoveryWidgetMetrics.cardHeight, alignment: .topLeading)
        .background(Color(viewConfig.theme.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
    }

    /// `Post / Header` 52 — avatar block at `(16, 12)`, two bars at `(56, 16)` and `(56, 32)`.
    /// The content column starts at `16 + 32 + 8 = 56`, and its `16` top inset puts the first bar
    /// four points below the avatar's.
    private var headerSlot: some View {
        HStack(alignment: .top, spacing: DiscoveryWidgetMetrics.avatarToContentGap) {
            pill(width: DiscoveryWidgetMetrics.avatarSize, height: DiscoveryWidgetMetrics.avatarSize)
                .padding(.top, DiscoveryWidgetMetrics.headerTopPadding)

            VStack(alignment: .leading, spacing: 8) {
                pill(width: 180, height: barHeight)
                pill(width: 64, height: barHeight)
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
        }
        .padding(.leading, DiscoveryWidgetMetrics.cardHorizontalInset)
        .frame(height: DiscoveryWidgetMetrics.headerHeight, alignment: .top)
    }

    /// `Post / Text` 428 — three bars at `(16, 64)`, `(16, 84)` and `(16, 104)`. The slot starts at
    /// `52`, so a `12` top inset and a `12` gap put them exactly there.
    private var textSlot: some View {
        VStack(alignment: .leading, spacing: 12) {
            pill(width: 240, height: barHeight)
            pill(width: 180, height: barHeight)
            pill(width: 297, height: barHeight)
        }
        .padding(.top, 12)
        .padding(.leading, DiscoveryWidgetMetrics.cardHorizontalInset)
        .frame(height: DiscoveryWidgetMetrics.skeletonTextBlockHeight, alignment: .top)
    }

    /// A solid `Base/Shade4` pill. `cornerRadius: 40` on both an 8-tall bar and a 32-square is a
    /// full round, which is what `Capsule` gives at either size.
    ///
    /// **No shimmer.** The house `shimmering(gradient:)` masks with alpha `0.2…0.4`, which the feed's
    /// skeleton can afford because it fills with `Base/Shade3` (`#A5A9B5` → `#DBDDE1` masked). The
    /// design binds `Base/Shade4` here, and `#EBECEF` masked the same way lands on `#F7F7F9`–
    /// `#FBFBFC` against a white card — the pills all but disappear. The design draws them solid.
    private func pill(width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(width: width, height: height)
    }
}

