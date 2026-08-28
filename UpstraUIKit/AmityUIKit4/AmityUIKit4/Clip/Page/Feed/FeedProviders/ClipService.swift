//
//  ClipService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import SwiftUI
import Foundation
import AmitySDK
import Combine

struct ClipPost: Identifiable {
    let id: String
    let url: URL
    let model: AmityPostModel
    let isInteractionEnabled: Bool
    
    init(id: String, url: URL, model: AmityPostModel, isInteractionEnabled: Bool = true) {
        self.id = model.postId
        self.url = url
        self.model = model
        self.isInteractionEnabled = isInteractionEnabled
    }
}

enum ClipFeedLoadingState: String {
    case loading
    case loaded
    case error
}

public class ClipService: ObservableObject {
    
    @Published
    var loadingState: ClipFeedLoadingState = .loading
    
    // Index of active clip
    @Published
    var currentIndex: Int = 0
    
    // Index at which clip feed is started. If user taps on particular video in clip tab, collection view will scroll to start from this index.
    var startIndex: Int = 0

    @Published
    var clips = [ClipPost]()

    // Callback to notify loading completion
    var onLoadCompletion: (() -> Void)?

    init() {
        /// Observe didPostDeleted event sent from PostBottomSheetView so a clip deleted from
        /// post detail page disappears from the feed we return to.
        NotificationCenter.default.addObserver(self, selector: #selector(didPostDeleted(_:)), name: .didPostDeleted, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didPostDeleted, object: nil)
    }

    @objc private func didPostDeleted(_ notification: Notification) {
        guard let postId = notification.userInfo?["postId"] as? String else { return }

        removeClip(id: postId)
    }

    /// Removes a deleted clip from the feed. Subclasses holding their own copy of a clip should
    /// override this and clear it too, else it comes back on the next snapshot.
    func removeClip(id: String) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }

        clips.remove(at: index)

        // Keep pointing at the same clip the user was on, or the last one if it was removed
        if index < currentIndex {
            currentIndex -= 1
        }
        currentIndex = clampedIndex(currentIndex)

        onLoadCompletion?()
    }

    /// Gets called when clip feed appears. Should be overridden in subclass
    func load() {

    }
    
    /// Gets called when last items appears in clip feed collection view. Should be overridden in subclass
    func canLoadMore() -> Bool {
        return false
    }
    
    /// Gets called when last items appears in clip feed collection view. Should be overridden in subclass
    func loadMore() {
        
    }
    
    /// Keep track of active clip. When isPaging is enabled in collection view, its delegate & dataSource methods such as cellForItemAt, willDisplay, didEndDisplaying becomes unreliable.
    // Note: Collection View Cell Behavior
    // 1. cellForItemAt can get called for both visible & non-visible cells.
    // 2. willDisplayCell gets called for visible cells. But it is also called if user tries to scroll but do not go to next page.
    // 3. didEndDisplaying for current cell does not get called immediately after user scrolls to next page.
    // 4. didEndDisplaying does not mean that cell as been deallocated. If we move back to cell whose didEndDisplaying has been called, cellForItemAt does not get called for that particular cell. Only willDisplayCell gets called.
    func setActiveClipIndex(index: Int) {
        self.currentIndex = clampedIndex(index)
    }

    /// Returns AmityPostModel for active clip post
    func getActiveClipPost() -> AmityPostModel? {
        return clip(at: currentIndex)?.model
    }

    /// `clips` and `currentIndex` are published separately and the list can shrink underneath the
    /// index — a live collection snapshot or a deleted clip both reassign `clips` while SwiftUI is
    /// still holding the old index. Every read goes through here so a stale index cannot trap.
    func clip(at index: Int) -> ClipPost? {
        guard clips.indices.contains(index) else { return clips.last }

        return clips[index]
    }

    private func clampedIndex(_ index: Int) -> Int {
        return max(0, min(index, clips.count - 1))
    }
}
