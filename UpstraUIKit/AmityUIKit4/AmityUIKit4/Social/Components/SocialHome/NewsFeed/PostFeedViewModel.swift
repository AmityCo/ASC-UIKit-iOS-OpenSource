//
//  PostFeedViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/8/24.
//

import Foundation
import AmitySDK
import Combine

class PostFeedViewModel: ObservableObject {
    @Published var feedLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var postItems: [PaginatedItem<AmityPostModel>] = []
    @Published var feedError: Error? = nil
        
    private var postCollection: AmityCollection<AmityPost>?
    private var pinnedPostCollection: AmityCollection<AmityPinnedPost>?
    private let feedManager = FeedManager()
    private let postManager = PostManager()
    
    private var paginator: UIKitPaginator<AmityPost>?
    var seenPostIds: Set<String> = Set()
    
    // loadGlobalFeed can be called multiple times. We only want one subscriber at a time
    private var feedCancellable: AnyCancellable?
    private var loadingStateCancellable: AnyCancellable?
    private var errorCancellable: AnyCancellable?
    private var pinnedPostCancellable: AnyCancellable?
    
    // cached recently created post by current user to show on top of post feed
    private var recentlyCreatedPosts: [AmityPost] = []
    private let feedType: FeedType
    private var globalPinnedPosts: [AmityPost] = [] // pinned posts
    private var globalPinnedPostsIds: Set<String> = []
    private var feedPosts: [PaginatedItem<AmityPost>] = []
    
    public enum FeedType: Equatable {
        case community(communityId: String)
        case globalFeed
    }
        
    init(feedType: FeedType) {
        self.feedType = feedType
        loadFeed(feedType: feedType)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didPostCreated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostReacted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didLivestreamStatusUpdated, object: nil)
    }
    
    func loadFeed(feedType: FeedType) {
        /// Clear out recentlyCreatedPosts on fresh data loading
        recentlyCreatedPosts.removeAll()
        
        let collection: AmityCollection<AmityPost>
        
        var paginatorCommunityId: String? = nil
        
        switch feedType {
        case .community(let communityId):
            collection = feedManager.getCommunityFeedPosts(communityId: communityId)
            paginatorCommunityId = communityId
        case .globalFeed:
            // Fetch pinned posts in global feed
            fetchGlobalPinnedPost()
            
            // Fetch normal posts in global feed
            collection = feedManager.getGlobalFeedPosts()
        }
        
        paginator = UIKitPaginator(liveCollection: collection, adPlacement: .feed, communityId: paginatorCommunityId, modelIdentifier: { model in
            return model.postId
        })
        paginator?.load()
        
        postCollection = collection
        
        feedCancellable = nil
        feedCancellable = paginator?.$snapshots.sink { [weak self] items in
            guard let self else { return }
            
            self.feedPosts = items
            self.renderFeed()
        }
        
        loadingStateCancellable = nil
        loadingStateCancellable = postCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                guard let self else { return }
                self.feedLoadingStatus = status
            })
        
        errorCancellable = nil
        errorCancellable = postCollection?.$error
            .sink(receiveValue: { [weak self] error in
                guard let self else { return }
                self.feedError = error
            })
        
        /// Observe didPostCreated event sent from AmityPostCreationPage
        /// We need to add the newly created post at the top of global feed.
        NotificationCenter.default.addObserver(self, selector: #selector(didPostCreated(_:)), name: .didPostCreated, object: nil)
        
        /// Observe didPostDeleted event sent from AmityPostContentComponent and AmityPostDetailPage
        /// If the post is the modded one that is not from liveCollection, we need to update directly to the dataSource to be reactive.
        NotificationCenter.default.addObserver(self, selector: #selector(didPostDeleted(_:)), name: .didPostDeleted, object: nil)
        
        /// Observe didPostReacted event sent from AmityPostContentComponent
        /// If the post is the modded one that is not from liveCollection, we need to update directly to the dataSource to be reactive.
        NotificationCenter.default.addObserver(self, selector: #selector(didPostReacted(_:)), name: .didPostReacted, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didLivestreamStatusUpdated(_:)), name: .didLivestreamStatusUpdated, object: nil)
    }
    
    func loadMorePosts() {
        if let paginator, paginator.hasNextPage() {
            paginator.nextPage()
        }
    }
    
    @objc private func didPostCreated(_ notification: Notification) {
        if let object = notification.object as? AmityPost, feedType == .globalFeed {
            
            // If the post targets community & requires post review, don't show it on feed.
            if let community = object.targetCommunity, community.isPostReviewEnabled {
                return
            }
            
            /// Rest assured all post object models are not invalidated at this point
            guard recentlyCreatedPosts.allSatisfy({ post in !post.isInvalidated }) else { return }
            
            /// Ensure recentlyCreatedPosts is not having the post to prevent duplication in data source
            if !recentlyCreatedPosts.contains(where: { $0.postId == object.postId }) {
                
                // Add to recently created lists & render feed.
                self.recentlyCreatedPosts.append(object)
                self.renderFeed()
            }
        }
    }
    
    @objc private func didPostDeleted(_ notification: Notification) {
        if let info = notification.userInfo, let postId = info["postId"] as? String, feedType == .globalFeed {
            
            /// Rest assured all post object models are not invalidated at this point
            guard recentlyCreatedPosts.allSatisfy({ post in !post.isInvalidated }) else { return }
            
            /// Check recentlyCreatedPosts is deleted
            if recentlyCreatedPosts.contains(where: { $0.postId == postId }) {
                
                /// Delete post from recentlyCreatedPosts cache and the actual data source
                recentlyCreatedPosts.removeAll { $0.postId == postId }
                postItems.removeAll { item in
                    if case let .content(postModel) = item.type, postModel.postId == postId {
                        return true
                    } else { return false }
                }
                
            }
        }
    }
    
    @objc private func didPostReacted(_ notification: Notification) {
        if let object = notification.object as? AmityPost, feedType == .globalFeed {
            /// Check recentlyCreatedPosts is reacted
            if recentlyCreatedPosts.contains(where: { $0.postId == object.postId }) {
                self.objectWillChange.send()
            }
        }
    }
    
    @objc private func didLivestreamStatusUpdated(_ notification: Notification) {
        self.objectWillChange.send()
    }
}

// Global Pinned Post
extension PostFeedViewModel {
    
    func fetchGlobalPinnedPost() {
        // reset state
        postCollection = nil
        pinnedPostCancellable = nil
        globalPinnedPosts = []
        globalPinnedPostsIds = []
        
        pinnedPostCollection = postManager.getGlobalPinnedPost()
        pinnedPostCancellable = pinnedPostCollection?.$snapshots.sink { [weak self] result in
            guard let self else { return }
                        
            var pinnedPostIds = Set<String>()
            let pinnedPosts = result.compactMap {
                // To filter out pinned post from regular feed
                if let postId = $0.post?.postId {
                    pinnedPostIds.insert(postId)
                }
                
                return $0.post
            }
            
            self.globalPinnedPosts = pinnedPosts
            self.globalPinnedPostsIds = pinnedPostIds
                        
            // Ask to render feed
            renderFeed()
        }
    }
    
    private func renderFeed() {
        var listItems = [PaginatedItem<AmityPostModel>]()
        
        // Pinned post at the top of the feed
        let pinnedPosts = prepareGlobalPinnedPosts()
        listItems.append(contentsOf: pinnedPosts)
        
        // Newly created post
        /// Append recently created posts at first to show at the top of global feed.
        if !recentlyCreatedPosts.isEmpty, feedType == .globalFeed {
            let newPosts = recentlyCreatedPosts.map { PaginatedItem(id: $0.postId, type: .content(AmityPostModel(post: $0)))}
            listItems.append(contentsOf: newPosts)
        }
        
        // Rest of the global feed.
        let feedPosts = prepareFeedPosts()
        listItems.append(contentsOf: feedPosts)
        
        self.postItems = listItems
    }
    
    private func prepareGlobalPinnedPosts() -> [PaginatedItem<AmityPostModel>]{
        guard feedType == .globalFeed else { return [] }
        
        var pinnedPosts = [PaginatedItem<AmityPostModel>]()
        
        for globalPinnedPost in self.globalPinnedPosts {
            guard canRenderPost(post: globalPinnedPost) else { continue }
            
            pinnedPosts.append(.init(id: globalPinnedPost.postId, type: .content(AmityPostModel(post: globalPinnedPost, isPinned: true))))
        }
        
        return pinnedPosts
    }
    
    private func prepareFeedPosts() -> [PaginatedItem<AmityPostModel>] {
        var finalItems = [PaginatedItem<AmityPostModel>]()
        
        // Filter out posts which we do not support yet.
        feedPosts.forEach {
            switch $0.type {
            case .ad(let ad):
                finalItems.append(PaginatedItem(id: $0.id, type: .ad(ad)))
            case .content(let post):
                if canRenderPost(post: post) && !globalPinnedPostsIds.contains(post.postId) {
                    finalItems.append(PaginatedItem(id: $0.id, type: .content(AmityPostModel(post: post))))
                }
            }
        }
        
        return finalItems
    }
    
    private func canRenderPost(post: AmityPost) -> Bool {
        let filterCondition = !post.childrenPosts.contains { $0.dataType == "file" }
        return filterCondition
    }
}


