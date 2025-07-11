//
//  GlobalFeedClipService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 27/6/25.
//

import AmitySDK
import SwiftUI
import Foundation

/* Usecases:
 #1: Open Clip Feed
 #2: Tap on clip post from news feed
 */
class GlobalFeedClipService: ClipService {
    
    let feedManager = FeedManager()
    
    var clipFeedCollection: AmityCollection<AmityPost>?
    var token: AmityNotificationToken?
    
    var isLoaded = false
    var isPaginationInProgress = false // To prevent pagination query multiple times when user reaches the last index.
    var isFirstLoad = true
    
    // For global feed, if user reaches the last available clip, we show the same clip again
    var isEndlessLoopingActive = false
    
    private let firstClip: ClipPost?
    
    init(clipPost: ClipPost) {
        self.firstClip = clipPost
        super.init()
        
        self.clips = [clipPost]
        self.startIndex = 0
        self.currentIndex = 0
    }
    
    override init() {
        self.firstClip = nil
        super.init()
    }
    
    override func load() {
        Log.add(event: .info, "Loading clip feed data")
        // If the feed is opened after tapping on certain clip, display that clip immediately.
        if let _ = firstClip, isFirstLoad {
            self.loadingState = .loaded
            self.isFirstLoad = false
            onLoadCompletion?()
        }
        
        fetchClipPosts()
    }
    
    func fetchClipPosts() {
        Log.add(event: .info, "Fetching clip posts for global feed")
        
        clipFeedCollection = feedManager.getGlobalFeedPosts(dataTypes: ["clip", "video"])
        token = clipFeedCollection?.observe{ [weak self] liveCollection, _, error in
            guard let self, liveCollection.dataStatus == .fresh, !isEndlessLoopingActive else { return }
            
            Log.add(event: .info, "Clip Posts fetched, \(liveCollection.count())")
            isPaginationInProgress = false
            
            // Handle error
            if let error {
                self.loadingState = .error
                Log.add(event: .warn, "Error while retrieving clips for news feed \(error.localizedDescription)")
                return
            }
            
            // In global feed, the snapshots returned follows Parent - Child relationship. So we do not need to query parent posts again.
            let snapshots = liveCollection.snapshots
            let excludeId = firstClip?.model.postId ?? ""
            
            if excludeId.isEmpty {
                processSnapshots(snapshots: snapshots)
            } else {
                let filteredSnapshots = snapshots.filter { $0.postId != excludeId }
                Log.add(event: .info, "FilteredSnapshotsCount: \(filteredSnapshots.count) | OriginalSnapshotsCount: \(snapshots.count)")
                processSnapshots(snapshots: filteredSnapshots)
            }
        }
    }
    
    func processSnapshots(snapshots: [AmityPost]) {
        let clipPosts: [ClipPost] = snapshots.compactMap { post in
            let model = AmityPostModel(post: post)
            
            if let media = model.medias.first {
                if model.dataTypeInternal == .clip, let mediaURL = URL(string: media.clip?.fileURL ?? "") {
                    let clipPost = ClipPost(id: model.postId, url: mediaURL, model: model)
                    return clipPost
                    
                } else if model.dataTypeInternal == .video, let mediaURL = URL(string: media.video?.fileURL ?? "") {
                    let clipPost = ClipPost(id: model.postId, url: mediaURL, model: model)
                    return clipPost
                }
            }
            
            return nil
        }
        
        var finalList: [ClipPost] = []
        if let firstClip {
            finalList.append(firstClip)
        }
        finalList.append(contentsOf: clipPosts)
        
        self.clips = finalList
        self.onLoadCompletion?()
        self.loadingState = .loaded
    }
    
    override func loadMore() {
        if canLoadMore() && !isPaginationInProgress {
            
            isPaginationInProgress = true
            
            if isEndlessLoopingActive {
                var newList = clips
                newList.append(contentsOf: clips)
                self.clips = newList
                self.onLoadCompletion?()
                
                // Give some time for the feed to reload
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isPaginationInProgress = false
                }
            } else {
                clipFeedCollection?.nextPage()
            }
        }
    }
    
    override func canLoadMore() -> Bool {
        guard let clipFeedCollection else { return false }
        
        if clipFeedCollection.hasNext {
            return true
        }
        
        // We loop the same content again for global feed
        if !clipFeedCollection.hasNext && clips.count >= 10 {
            isEndlessLoopingActive = true
            Log.add(event: .info, "Endless looping is active in global feed")
            return true
        }
        
        return false
    }
}
