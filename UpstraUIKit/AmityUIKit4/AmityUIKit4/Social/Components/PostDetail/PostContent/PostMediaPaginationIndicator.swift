//
//  PostMediaPaginationIndicator.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/26.
//

import SwiftUI

/// Which pages get a full dot, and whether the half-size edge dots are visible.
struct PaginationIndicatorConfig: Equatable {
    let window: Range<Int>
    let showLeadingEdge: Bool
    let showTrailingEdge: Bool
}

/// Sliding window over the pages. Six or fewer attachments get a dot each; above that the strip is
/// always exactly 6 elements, edge dots included.
///
/// The asymmetry is intentional: the first two pages share a window and the last three do.
///
///     total 10, current 0 or 1  ->  0...4, trailing edge
///     total 10, current 4       ->  3...6, both edges
///     total 10, current 7..9    ->  5...9, leading edge
func paginationIndicatorConfig(current: Int, total: Int) -> PaginationIndicatorConfig {
    guard total > 0 else {
        return PaginationIndicatorConfig(window: 0..<0, showLeadingEdge: false, showTrailingEdge: false)
    }

    guard total > 6 else {
        return PaginationIndicatorConfig(window: 0..<total, showLeadingEdge: false, showTrailingEdge: false)
    }

    let clamped = min(max(current, 0), total - 1)

    let windowStart: Int
    let windowLength: Int

    if clamped <= 1 {
        windowStart = 0
        windowLength = 5
    } else if clamped >= total - 3 {
        windowStart = total - 5
        windowLength = 5
    } else {
        windowStart = clamped - 1
        windowLength = 4
    }

    let windowEnd = windowStart + windowLength - 1

    return PaginationIndicatorConfig(
        window: windowStart..<(windowStart + windowLength),
        showLeadingEdge: windowStart > 0,
        showTrailingEdge: windowEnd < total - 1
    )
}

/// The dot strip below the media track.
struct PostMediaPaginationIndicatorView: View {

    @ObservedObject var viewConfig: AmityViewConfigController

    let current: Int
    let total: Int

    private enum Dot {
        static let fullSize: CGFloat = 6
        static let edgeSize: CGFloat = 3
        static let gap: CGFloat = 4
        static let slideDistance: CGFloat = 4
        static let animationDuration: Double = 0.3
    }

    private var config: PaginationIndicatorConfig {
        paginationIndicatorConfig(current: current, total: total)
    }

    var body: some View {
        HStack(spacing: Dot.gap) {
            edgeDot(isVisible: config.showLeadingEdge, slideFrom: -Dot.slideDistance)

            ForEach(Array(config.window), id: \.self) { page in
                Circle()
                    .fill(Color(page == current ? viewConfig.theme.baseColor : viewConfig.theme.baseColorShade4))
                    .frame(width: Dot.fullSize, height: Dot.fullSize)
            }

            edgeDot(isVisible: config.showTrailingEdge, slideFrom: Dot.slideDistance)
        }
        .frame(height: Dot.fullSize)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: Dot.animationDuration), value: current)
        .accessibilityHidden(true)   // decorative — the frames carry position
    }

    /// Holds its slot even when hidden, so the strip width never jumps.
    private func edgeDot(isVisible: Bool, slideFrom offset: CGFloat) -> some View {
        Circle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(width: Dot.edgeSize, height: Dot.edgeSize)
            .frame(width: Dot.fullSize, height: Dot.fullSize)
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : offset)
    }
}
