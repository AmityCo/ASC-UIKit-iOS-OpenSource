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
        
    private var postCollection: AmityCollection<AmityPost>?
    private let feedManager = FeedManager()
    private let postManager = PostManager()
    
    private var paginator: UIKitPaginator<AmityPost>?
    var seenPostIds: Set<String> = Set()
    
    // loadGlobalFeed can be called multiple times. We only want one subscriber at a time
    private var feedCancellable: AnyCancellable?
    private var loadingStateCancellable: AnyCancellable?
    
    // cached recently created post by current user to show on top of post feed
    private var recentlyCreatedPosts: [AmityPost] = []
    private let feedType: FeedType
    
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
            
            let normalizedPosts: [PaginatedItem<AmityPost>] = items.filter { item in
                switch item.type {
                case .ad:
                    return true
                case .content(let post):
                    var filterCondition = !post.childrenPosts.contains { $0.dataType == "poll" || $0.dataType == "liveStream" || $0.dataType == "file" }
                    return filterCondition
                }
            }
            
            self.postItems = normalizedPosts.map {
                switch $0.type {
                case .content(let post):
                    return PaginatedItem(id: $0.id, type: .content(AmityPostModel(post: post)))
                case .ad(let ad):
                    return PaginatedItem(id: $0.id, type: .ad(ad))
                }
            }
            
            /// Append recently created posts at first to show at the top of global feed.
            if !recentlyCreatedPosts.isEmpty, feedType == .globalFeed {
                let newPosts = recentlyCreatedPosts.map { PaginatedItem(id: $0.postId, type: .content(AmityPostModel(post: $0)))}
                self.postItems = newPosts + postItems
            }
        }
        
        loadingStateCancellable = nil
        loadingStateCancellable = postCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                guard let self else { return }
                self.feedLoadingStatus = status
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
    }
    
    func loadMorePosts() {
        if let paginator, paginator.hasNextPage() {
            paginator.nextPage()
        }
    }
    
    @objc private func didPostCreated(_ notification: Notification) {
        if let object = notification.object as? AmityPost, feedType == .globalFeed, let community = object.targetCommunity, !community.isPostReviewEnabled {
            /// Ensure recentlyCreatedPosts is not having the post to prevent duplication in data source
            if !recentlyCreatedPosts.contains(where: { $0.postId == object.postId }) {
                recentlyCreatedPosts.append(object)
                
                let newPost = PaginatedItem(id: object.postId, type: .content(AmityPostModel(post: object)))
                self.postItems = [newPost] + postItems
            }
        }
    }
    
    @objc private func didPostDeleted(_ notification: Notification) {
        if let info = notification.userInfo, let postId = info["postId"] as? String, feedType == .globalFeed {
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
}
