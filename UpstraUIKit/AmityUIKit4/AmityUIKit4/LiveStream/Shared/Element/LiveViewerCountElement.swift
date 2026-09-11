//
//  LiveViewerCountElement.swift
//  AmityUIKit4
//
//  Created by Amity. All rights reserved.
//

import SwiftUI
import AmitySDK

// MARK: - LiveViewerCountVisibility


/// Mapped from the SDK config's public `mode` / `threshold`; the SDK model itself cannot be
/// constructed here (its initializer is internal), so the fail-open fallback is `.alwaysShow`.
enum LiveViewerCountVisibility: Equatable {
    case alwaysShow
    case hideEntirely
    case showAboveMinimum(threshold: Int)

    init(config: AmityLiveViewerCountConfig) {
        switch config.mode {
        case .alwaysShow:       self = .alwaysShow
        case .hideEntirely:     self = .hideEntirely
        case .showAboveMinimum: self = .showAboveMinimum(threshold: config.threshold)
        @unknown default:       self = .alwaysShow
        }
    }

    /// Whether the numeric count should be shown for `count`. When `false`, the LIVE-only pill is
    /// rendered instead.
    func shouldShowCount(_ count: Int) -> Bool {
        switch self {
        case .alwaysShow:                      return count > 0
        case .hideEntirely:                    return false
        case .showAboveMinimum(let threshold): return count >= threshold
        }
    }
}

// MARK: - LiveViewerCountElement

/// Pill in the livestream player top bar. Renders the LIVE indicator plus the concurrent viewer
/// count when the visibility rule permits, and the LIVE-only indicator (no number) otherwise.
/// The pill is always present while the stream is live — only the number is gated.
///
/// Element ID: `live_viewer_count_element`
/// Page: livestreamPlayerPage
struct LiveViewerCountElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .liveViewerCount
    }

    /// Resolved visibility rule from the network config (cold-read at mount).
    let visibility: LiveViewerCountVisibility

    /// Current concurrent viewer count.
    let watchingCount: Int

    init(pageId: PageId? = nil,
         componentId: ComponentId? = nil,
         visibility: LiveViewerCountVisibility,
         watchingCount: Int) {
        self.pageId = pageId
        self.componentId = componentId
        self.visibility = visibility
        self.watchingCount = watchingCount
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)

            if visibility.shouldShowCount(watchingCount) {
                Image(AmityIcon.Chat.membersCount.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 16, height: 14)
                    .foregroundColor(Color.white)

                Text("\(watchingCount.formattedCountString)")
                    .applyTextStyle(.captionBold(.white))
            } else {
                Text(AmityLocalizedStringSet.General.live.localizedString)
                    .applyTextStyle(.captionBold(.white))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(4, corners: .allCorners)
    }
}
