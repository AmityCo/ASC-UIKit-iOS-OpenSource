//
//  TargetFeedClipService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 27/6/25.
//

import SwiftUI
import AmitySDK
import Foundation

class TargetFeedClipService: ClipService {
        
    private let postCollection: AmityCollection<AmityPost>
    private let targetId: String
    private let targetType: AmityPostTargetType
    private let firstClip: ClipPost?
    
    var token: AmityNotificationToken?
    var parentPostsToken: AmityNotificationToken?
    
    var isFirstLoad = true
    var isPaginationInProgress = false
    var isFetchingParentPosts = false
    
    private let postManager = PostManager()
    
    var postsCache = [String: AmityPost]()   // ParentPostId: Post
    
    init(targetId: String, targetType: AmityPostTargetType, clipPost: ClipPost) {
        self.targetId = targetId
        self.targetType = targetType
        let queryOptions = AmityPostQueryOptions(targetType: targetType, targetId: targetId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: ["clip"])
        self.postCollection = postManager.getPosts(options: queryOptions)
        self.firstClip = clipPost
        
        super.init()
        
        self.clips = [clipPost]
        self.startIndex = 0
        self.currentIndex = 0
    }
    
    init(targetId: String, targetType: AmityPostTargetType, postCollection: AmityCollection<AmityPost>, startIndex: Int, postsCache: [String: AmityPost]) {
        self.targetId = targetId
        self.targetType = targetType
        self.postCollection = postCollection
        self.firstClip = nil
        self.postsCache = postsCache
        
        super.init()
        
        self.startIndex = startIndex
        self.currentIndex = startIndex
    }
    
    override func load() {
        // Notify immediately after opening feed if there is first clip available
        if let firstClip, isFirstLoad {
            self.loadingState = .loaded
            self.isFirstLoad = false
            self.postsCache[firstClip.model.postId] = firstClip.model.object
            onLoadCompletion?()
        }
        
        if isFirstLoad {
            self.isFirstLoad = false
            let cachedSnapshots = postCollection.snapshots
            self.processSnapshots(snapshots: cachedSnapshots)
        }
        
        fetchClipPosts()
    }
    
    func fetchClipPosts() {
        Log.add(event: .info, "Fetching clip posts for \(targetType.rawValue) feed")
        token?.invalidate()
        token = nil
        
        token = postCollection.observe { [weak self ] liveCollection, _, error in
            guard let self, liveCollection.dataStatus == .fresh && !isFetchingParentPosts else { return }
            
            Log.add(event: .info, "Clip Posts fetched, \(liveCollection.count())")
            
            // Handle error
            if let error {
                self.loadingState = .error
                Log.add(event: .warn, "Error while retrieving clips for news feed \(error.localizedDescription)")
                return
            }
            
            // In posts feed, the snapshots returned does not follow Parent - Child relationship. So we need to query parent posts again to map the relationship.
            let snapshots = liveCollection.snapshots
            let excludeId = firstClip?.model.postId ?? ""
            
            if excludeId.isEmpty {
                self.processSnapshots(snapshots: snapshots)
            } else {
                let filteredSnapshots = snapshots.filter { $0.parentPostId != excludeId }
                Log.add(event: .info, "Original Snapshots Count: \(snapshots.count) | Filtered Snapshots Count: \(filteredSnapshots.count)")

                self.processSnapshots(snapshots: filteredSnapshots)
            }
        }
    }
    
    func processSnapshots(snapshots: [AmityPost]) {
        let idsToFetch: [String] = snapshots.compactMap { post in
            let parentId = post.parentPostId ?? ""
            if let _ = postsCache[parentId] {
                return nil
            } else {
                return parentId
            }
        }
        
        if idsToFetch.isEmpty {
            Log.add(event: .info, "Found parent posts in cache. No posts to fetch")
            
            // Get posts from cache. This post already maintains Parent-Child relationship
            let posts = snapshots.compactMap {
                let parentId = $0.parentPostId ?? ""
                return postsCache[parentId]
            }
            let clipPosts = extractClipPosts(snapshots: posts)
            
            var finalList: [ClipPost] = []
            if let firstClip {
                finalList.append(firstClip)
            }
            finalList.append(contentsOf: clipPosts)
            
            self.clips = finalList
            self.onLoadCompletion?()
            self.loadingState = .loaded
            
        } else {
            Log.add(event: .info, "Fetching parent posts \(idsToFetch.count)")
            
            isFetchingParentPosts = true
            fetchParentPosts(ids: idsToFetch, completion: { [weak self] in
                guard let self else { return }
                
                isFetchingParentPosts = false
                
                let posts = snapshots.compactMap {
                    let parentId = $0.parentPostId ?? ""
                    return self.postsCache[parentId]
                }
                let clipPosts = extractClipPosts(snapshots: posts)
                
                var finalList: [ClipPost] = []
                if let firstClip {
                    finalList.append(firstClip)
                }
                finalList.append(contentsOf: clipPosts)
                
                self.clips = finalList
                self.onLoadCompletion?()
                self.loadingState = .loaded
            })
        }
    }
    
    func fetchParentPosts(ids: [String], completion: @escaping () -> Void) {
        Log.add(event: .info, "Fetching parent posts \(ids)")
        parentPostsToken = postManager.getPosts(ids: ids).observe { [weak self] liveCollection, _, error in
            guard let self, liveCollection.dataStatus == .fresh else { return }
            
            Log.add(event: .info, "Fetched parent posts: \(liveCollection.count())")
            
            parentPostsToken?.invalidate()
            parentPostsToken = nil
            
            if let error {
                Log.warn("Error while returning parent posts \(error.localizedDescription)")
                completion()
                return
            }
            
            // Map this with clip post id
            let snapshots = liveCollection.snapshots
            snapshots.forEach { post in
                let postId = post.postId // This is parent posts
                self.postsCache[postId] = post
            }
            
            completion()
        }
    }
    
    func extractClipPosts(snapshots: [AmityPost]) -> [ClipPost]{
        let clipPosts: [ClipPost] = snapshots.compactMap { post in
            let model = AmityPostModel(post: post)
            
            if let media = model.medias.first, let mediaURL = URL(string: media.clip?.fileURL ?? "") {
                let clipPost = ClipPost(id: model.postId, url: mediaURL, model: model)
                return clipPost
            } else {
                return nil
            }
        }
        return clipPosts
    }
    
    override func loadMore() {
        if postCollection.hasNext && !isPaginationInProgress {
            postCollection.nextPage()
        }
    }
    
    override func canLoadMore() -> Bool {
        return postCollection.hasNext
    }
}
