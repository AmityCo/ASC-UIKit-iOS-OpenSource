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
        self.currentIndex = index
    }
    
    /// Returns AmityPostModel for active clip post
    func getActiveClipPost() -> AmityPostModel? {
        guard !clips.isEmpty else { return nil }
        
        return clips[currentIndex].model
    }
}
