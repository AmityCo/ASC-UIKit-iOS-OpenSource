//
//  DiscoveryWidgetViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI
import AmitySDK

/// The widget has three states and no others — there is deliberately no empty state and no error
/// state. Below-threshold and a failed content call produce the *same* outcome: nothing.
enum DiscoveryWidgetPhase {
    case loading
    case rendered
    case absent
}

@MainActor
class DiscoveryWidgetViewModel: ObservableObject {

    @Published private(set) var phase: DiscoveryWidgetPhase = .loading
    /// Server-ordered pool, never re-sorted, re-ranked, re-filtered or de-duplicated by the widget.
    @Published private(set) var posts: [AmityPostModel] = []
    @Published private(set) var topic: AmityCuratedContentTopic?

    /// Page-load-scoped guard for the widget impression. The only thing standing between a
    /// re-entering viewport and inflated numbers — core does not de-duplicate.
    private var impressionFired = false
    /// Page-load-scoped guard per `postId` for card impressions.
    private var postImpressionsFired: Set<String> = []

    private var hasFetched = false
    private let curatedContentManager = CuratedContentManager()

    /// What "a card became visible" means. Neither PDT-4024 nor the telemetry contract defines it
    /// (Plan 39 Q32), so this matches the For You feed's existing meaningful-view threshold rather
    /// than inventing a third number. Revisit once Q32 is answered.
    private let cardImpressionVisibility: CGFloat = 50

    /// The post types the widget can draw. The console's topic filters offer exactly these
    /// (PDT-4021); anything else in the pool is dropped rather than rendered as a gap.
    private static let renderableTypes: Set<AmityPostModel.DataType> = [.text, .image, .video, .poll, .clip]

    // MARK: - Content

    /// One-shot. Evaluation is per page load: no live collection, no mid-session re-evaluation.
    func load(topicId: String, minVisibilityThreshold: Int) async {
        guard !hasFetched else { return }
        hasFetched = true

        do {
            let pool = try await curatedContentManager.getPool(topicId: topicId)
            let renderable = pool.posts
                .map { AmityPostModel(post: $0) }
                .filter { Self.isRenderable($0) }

            topic = pool.topic
            posts = renderable
            // Dropping happens *before* the threshold test: a pool of 4 with 2 unrenderable counts
            // as 2, so the widget can hide on post types alone.
            phase = renderable.count >= max(1, minVisibilityThreshold) ? .rendered : .absent
        } catch {
            // Failure and below-threshold render identically — the widget hides either way. The SDK
            // no longer classifies these, so neither does this: a disabled feature, a missing topic,
            // a visitor session and a dropped connection are one outcome here, and the error text is
            // the only thing that separates them for whoever is debugging.
            Log.add(event: .error, "[DiscoveryWidget] pool fetch failed for topic \(topicId): \(error)")
            posts = []
            phase = .absent
        }
    }

    /// A supported type whose required side collection never arrived is unrenderable too — the
    /// client-side safety net for a poll post whose poll did not come back in the payload.
    private static func isRenderable(_ post: AmityPostModel) -> Bool {
        guard !post.isDeleted else { return false }
        guard renderableTypes.contains(post.dataTypeInternal) else { return false }

        switch post.dataTypeInternal {
        case .poll:
            return post.poll != nil
        case .image, .video, .clip:
            return !post.medias.isEmpty
        default:
            return true
        }
    }

    // MARK: - Analytics

    /// Fires on the widget's first viewport entry, once per page load. Not fired at all when the
    /// widget does not render.
    func markWidgetVisible() {
        guard phase == .rendered, !impressionFired, let topic else { return }
        impressionFired = true
        // Reached through the topic, never as a free call taking a topic id — the binding is what
        // makes a mismatched attribution impossible to write.
        topic.analytics.markAsViewed()
    }

    /// One widget impression legitimately produces many post impressions — a viewer swiping a
    /// compact carousel exposes card after card. A card scrolled out and back does not re-fire.
    func updateCardVisibility(postId: String, visiblePercentage: CGFloat) {
        guard phase == .rendered,
              visiblePercentage >= cardImpressionVisibility,
              !postImpressionsFired.contains(postId),
              let topic else { return }

        postImpressionsFired.insert(postId)
        topic.analytics.markPostAsViewed(postId: postId)
    }

    /// Clicks are not de-duplicated — repeat clicks are real engagement. Never awaited: telemetry
    /// must not delay the destination.
    func markCardClicked(postId: String) {
        guard let topic else { return }
        topic.analytics.markPostClick(postId: postId)
    }
}
