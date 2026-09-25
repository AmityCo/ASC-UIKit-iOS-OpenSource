//
//  AmityDiscoveryWidgetComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI
import AmitySDK

/// The **Discovery Widget** — a read-only horizontal carousel of topic-ranked community posts that a
/// client embeds on a page they own, using a snippet generated in the console for a configured topic.
///
/// Three properties set it apart from every other UIKit feed surface:
///
/// 1. **It is not interactive.** No reactions, no voting, no commenting, no post menu, no media
///    playback. The entire card is a single click target that hands the visitor to the destination.
/// 2. **It hides rather than degrades.** Below-threshold pool, or a failed / timed-out content call,
///    and the widget renders *nothing* and occupies **zero layout height** — no empty state, no
///    skeleton left behind, no broken frame on the client's page.
/// 3. **It is topic-scoped, not community-scoped.** The pool is assembled server-side from a console
///    topic configuration. The integrator passes a topic id and nothing else about content selection,
///    so changing filters in the console never invalidates a placed snippet.
///
/// ## Host-container contract
///
/// - Give the widget **wrap-content** or a **minimum height**. Its own height is content-derived
///   (552 compact / 584 expanded) and it imposes no height on its parent.
/// - A container shorter than the widget clips the track — most visibly the engagement bar, the last
///   36 points of every card. The widget does not detect or compensate for this.
/// - A container with zero or indeterminate height renders the widget invisible while it still
///   fetches, still meets its threshold and still fires its impression. Analytics then report a
///   visible widget nobody can see.
/// - 🚫 **A horizontally-scrolling parent is not supported.** The track is itself a horizontal
///   scroller; nesting it inside another one leaves the two competing for the same drag. Mount the
///   widget in a vertically-scrolling or non-scrolling container. This is a documented limitation,
///   not a guard — the widget cannot reliably detect such an ancestor, so it does not try.
public struct AmityDiscoveryWidgetComponent: AmityComponentView {

    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var pageId: PageId?

    public var id: ComponentId {
        .discoveryWidgetComponent
    }

    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = DiscoveryWidgetViewModel()

    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width
    /// Last known position on screen. Held because the impression has two independent triggers —
    /// the widget moving into view, and the pool resolving while it is already in view — and the
    /// second one has no frame of its own to read.
    @State private var widgetFrame: CGRect = .zero

    private let topicId: String
    private let showHeader: Bool
    private let minVisibilityThreshold: Int
    private let onCardClick: ((String, AmityPost) -> Void)?

    /// - Parameters:
    ///   - topicId: The topic slug the console pre-populates into the embed snippet. The only
    ///     content-selection input an integrator supplies — every filter, sort, sentiment,
    ///     author-type and exclusion lives in the topic configuration instead, so the snippet stays
    ///     valid across configuration changes.
    ///   - showHeader: Shows or hides the heading row, which on mobile is the topic title and
    ///     nothing else — the web widget's arrow paging has no counterpart here, so hiding the
    ///     heading costs no navigation affordance. The track is swiped at both breakpoints.
    ///   - minVisibilityThreshold: Minimum renderable posts required to show the widget; below it the
    ///     widget renders nothing. Overridable in the embed snippet; values under 1 are clamped to 1.
    ///   - onCardClick: Fires after the card-click analytics event, carrying the topic id alongside
    ///     the post so a host can attribute the click without threading the topic through its own
    ///     state. When absent, `AmityDiscoveryWidgetComponentBehavior` handles the destination.
    public init(topicId: String,
                showHeader: Bool = true,
                minVisibilityThreshold: Int = 3,
                onCardClick: ((String, AmityPost) -> Void)? = nil,
                pageId: PageId? = nil) {
        self.topicId = topicId
        self.showHeader = showHeader
        self.minVisibilityThreshold = max(1, minVisibilityThreshold)
        self.onCardClick = onCardClick
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .discoveryWidgetComponent))
    }

    public var body: some View {
        Group {
            switch viewModel.phase {
            case .absent:
                // Zero layout height. Not a collapsed wrapper, not a retained margin, not a
                // zero-opacity frame — the client's page must look as though the widget was never
                // placed, and the component leaves the accessibility tree entirely.
                EmptyView()

            case .loading, .rendered:
                widgetBody
            }
        }
        .updateTheme(with: viewConfig)
        .onAppear {
            Task { await viewModel.load(topicId: topicId, minVisibilityThreshold: minVisibilityThreshold) }
        }
    }

    private var layout: DiscoveryWidgetLayout {
        DiscoveryWidgetLayout(containerWidth: containerWidth)
    }

    @ViewBuilder
    private var widgetBody: some View {
        VStack(spacing: DiscoveryWidgetMetrics.headingToTrackGap(layout)) {
            // Measures the width the widget is *offered*, not the width it lays out to. A zero-height
            // child takes the stack's proposal, so an over-wide sibling cannot inflate it — which is
            // what previously drove the breakpoint to expanded on a 440pt phone and then fed back
            // into the track's own width.
            Color.clear
                .frame(height: 0)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { updateContainerWidth(geometry.size.width) }
                            .onChange(of: geometry.size.width) { updateContainerWidth($0) }
                    }
                )

            if showHeader {
                DiscoveryWidgetHeaderView(
                    title: viewModel.topic?.topicName ?? "",
                    layout: layout,
                    isLoading: viewModel.phase == .loading
                )
                .environmentObject(viewConfig)
            }

            track
        }
        .padding(.vertical, DiscoveryWidgetMetrics.containerVerticalPadding(layout))
        .frame(maxWidth: .infinity)
        .background(Color(viewConfig.theme.backgroundColor))
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { recordFrame(geometry.frame(in: .global)) }
                    .onChange(of: geometry.frame(in: .global)) { recordFrame($0) }
            }
        )
        // The pool usually resolves while the widget is already on screen, and the loading track is
        // the same height as the rendered one — so the frame never changes and a frame-only trigger
        // would miss the impression entirely.
        .onChange(of: viewModel.phase) { _ in attemptWidgetImpression() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.topic?.topicName ?? "")
    }

    @ViewBuilder
    private var track: some View {
        switch viewModel.phase {
        case .rendered:
            // Swipe is the only way through the track, at both breakpoints. The web widget's arrow
            // paging is deliberately not mirrored here, so nothing drives the scroll position
            // programmatically and the view needs no scroll proxy.
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DiscoveryWidgetMetrics.cardGap(layout)) {
                    // Server order, exactly as received. The component never re-sorts, re-ranks,
                    // re-filters or de-duplicates the pool — ordering is a topic-relevance
                    // concern the backend owns.
                    ForEach(viewModel.posts, id: \.postId) { post in
                        AmityDiscoveryWidgetPostCardComponent(
                            post: post,
                            layout: layout,
                            pageId: pageId,
                            onClick: { handleCardClick(post) }
                        )
                        .environmentObject(viewConfig)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        handleCardVisibility(frame: geometry.frame(in: .global), postId: post.postId)
                                    }
                                    .onChange(of: geometry.frame(in: .global)) { frame in
                                        handleCardVisibility(frame: frame, postId: post.postId)
                                    }
                            }
                        )
                    }
                }
                .padding(.horizontal, DiscoveryWidgetMetrics.trackInset(layout))
            }
            .frame(height: DiscoveryWidgetMetrics.cardHeight)

        case .loading:
            DiscoveryWidgetSkeletonView(layout: layout)
                .environmentObject(viewConfig)

        case .absent:
            EmptyView()
        }
    }

    // MARK: - Layout

    /// A mid-session resize re-lays out immediately and does not refetch. The scroll offset is the
    /// ScrollView's own and survives the breakpoint change untouched.
    private func updateContainerWidth(_ width: CGFloat) {
        guard width > 0, width != containerWidth else { return }
        containerWidth = width
    }

    // MARK: - Analytics

    private func recordFrame(_ frame: CGRect) {
        widgetFrame = frame
        attemptWidgetImpression()
    }

    /// Fires once per page load — the guard lives in the view model, and has no backstop anywhere
    /// else, so calling this repeatedly is safe and expected.
    private func attemptWidgetImpression() {
        guard isInViewport(widgetFrame) else { return }
        viewModel.markWidgetVisible()
    }

    private func isInViewport(_ frame: CGRect) -> Bool {
        guard frame.height > 0 else { return false }
        let screen = UIScreen.main.bounds
        return frame.maxY > 0 && frame.minY < screen.height
    }

    private func handleCardVisibility(frame: CGRect, postId: String) {
        guard frame.width > 0 else { return }
        let screen = UIScreen.main.bounds
        let visibleWidth = min(screen.width, frame.maxX) - max(0, frame.minX)
        let visiblePercentage = max(0, (visibleWidth / frame.width) * 100)
        viewModel.updateCardVisibility(postId: postId, visiblePercentage: visiblePercentage)
    }

    private func handleCardClick(_ post: AmityPostModel) {
        // Never awaited — telemetry must not block or delay the destination.
        viewModel.markCardClicked(postId: post.postId)

        if let onCardClick {
            onCardClick(topicId, post.object)
            return
        }

        let context = AmityDiscoveryWidgetComponentBehavior.Context(component: self, topicId: topicId, post: post)
        AmityUIKit4Manager.behaviour.discoveryWidgetComponentBehavior?.goToDestination(context: context)
    }
}
