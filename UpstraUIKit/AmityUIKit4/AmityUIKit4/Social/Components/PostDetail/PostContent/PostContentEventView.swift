//
//  PostContentEventView.swift
//  AmityUIKit4
//
//  The event card embedded inside a feed post (an "event post").
//
//  The loaded + loading states REUSE `EventCardView` / `EventCardSkeletonView`
//  from the Event tabs (per the design: "this card is reused from Event tabs"),
//  so the same event renders identically in the tabs and in the feed, and edits
//  to the event reflect in both. The "no longer available" state is post-specific
//  (the Event tabs have no deleted state), so it lives here.
//
//  Social intentionally still uses the legacy `viewConfig.theme.*` palette.
//

import SwiftUI
import AmitySDK

/// The live-data state of the embedded event.
enum PostContentEventState {
    case loading
    case loaded(AmityEvent)
    case unavailable
}

class PostContentEventViewModel: ObservableObject {

    @Published var state: PostContentEventState

    init(event: AmityEvent?) {
        if let event, !event.isDeleted, event.status != .cancelled {
            self.state = .loaded(event)
        } else {
            self.state = .unavailable
        }
    }
}

/// Event card shown inside a feed post. Dispatches by live-data state:
/// loading (skeleton), loaded (event card), unavailable (deleted).
struct PostContentEventView: View {

    /// Whether the feed should render an event card for this post
    /// (i.e. the post is linked to an event).
    static func shouldRender(for post: AmityPostModel) -> Bool {
        if let eventId = post.eventId, !eventId.isEmpty { return true }
        return false
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PostContentEventViewModel

    private let onTapEvent: ((AmityEvent) -> Void)?

    // Feed / pending / edit: read the event linked object from the post.
    init(post: AmityPostModel,
         onTapEvent: ((AmityEvent) -> Void)? = nil) {
        self.onTapEvent = onTapEvent
        self._viewModel = StateObject(wrappedValue: PostContentEventViewModel(event: post.event))
    }

    // Create-composer preview: the in-hand event.
    init(event: AmityEvent,
         onTapEvent: ((AmityEvent) -> Void)? = nil) {
        self.onTapEvent = onTapEvent
        self._viewModel = StateObject(wrappedValue: PostContentEventViewModel(event: event))
    }

    @ViewBuilder
    var body: some View {
        switch viewModel.state {
        case .loading:
            EventPostCardSkeleton()
        case .loaded(let event):
            EventCardView(style: .large, event: event,   // reused from Event tabs
                          largeInfoPadding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture { onTapEvent?(event) }
        case .unavailable:
            // "No longer available" card is not interactive — there is nowhere useful
            // to navigate for a deleted/cancelled/absent event.
            EventPostCardUnavailable()
        }
    }
}

// MARK: - Skeleton (post-specific: bordered card + text strip)

private struct EventPostCardSkeleton: View {

    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 177)
                .cornerRadius(8, corners: [.topLeft, .topRight])

            VStack(alignment: .leading) {
                SkeletonRectangle(height: 12, width: 112)
                SkeletonRectangle(height: 12, width: 196)
                SkeletonRectangle(height: 12, width: 80)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
    }
}

// MARK: - Unavailable (deleted event) — post-specific

private struct EventPostCardUnavailable: View {

    @EnvironmentObject var viewConfig: AmityViewConfigController

    private static let placeholderHeight: CGFloat = 194

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image-placeholder area: grey surface with a broken-image glyph.
            ZStack {
                Color(viewConfig.theme.baseColorShade4)

                Image(AmityIcon.DesignSystem.imageSlashR.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 48)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.placeholderHeight)

            // Text strip.
            Text(AmityLocalizedStringSet.Social.eventPostNoLongerAvailable.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade2)))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 30)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
    }
}
