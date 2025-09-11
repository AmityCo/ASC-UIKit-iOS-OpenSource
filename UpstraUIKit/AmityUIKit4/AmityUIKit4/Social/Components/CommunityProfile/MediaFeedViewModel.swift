//
//  MediaFeedViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import Foundation
import AmitySDK
import Combine
import UIKit

enum MediaFeedType: Equatable {
    case community(communityId: String)
    case user(userId: String)
}

class MediaFeedViewModel: ObservableObject {
    @Published var medias: [AmityMedia] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    @Published var emptyFeedState: EmptyUserFeedViewState? = nil
    @Published var blockedFeedState: EmptyUserFeedViewState? = nil
    @Published var currentFeedSources: [AmityFeedSource]
    
    // Keep track of deleted file IDs to filter them out from future updates
    private var deletedFileIds: Set<String> = []
    
    var hasNavigatedToPostDetail: Bool = false
    
    private let debouner = Debouncer(delay: 0.1)
    let feedType: MediaFeedType
    private var token: AmityNotificationToken?
    private var myFollowInfoObject: AmityObject<AmityMyFollowInfo>?
    private var userFollowInfoObject: AmityObject<AmityUserFollowInfo>?
    private var cancellable: AnyCancellable?
    private let postManager = PostManager()
    private let feedManager = FeedManager()
    private let userManager = UserManager()
    var postCollection: AmityCollection<AmityPost>?
    let postType: PostTypeFilter
    
    @Published var showMediaViewer: Bool = false
    var selectedMediaIndex: Int = 0
    var videoURL: URL? = nil
    
    // Parent Post Id : Post
    var postsCache: [String: AmityPost] = [:]
    var parentPostsToken: AmityNotificationToken?
    
    init(feedType: MediaFeedType, postType: PostTypeFilter) {
        self.feedType = feedType
        self.postType = postType
        self.currentFeedSources = [.user, .community]
        loadMediaFeed()
        
        // Observe didPostDeleted event
        NotificationCenter.default.addObserver(self, selector: #selector(didPostDeleted(_:)), name: .didPostDeleted, object: nil)
        
        // Observe didPostImageUpdated event for deleted images
        NotificationCenter.default.addObserver(self, selector: #selector(didPostImageUpdated(_:)), name: .didPostImageUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didPostDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostImageUpdated, object: nil)
    }
    
    // Used for querying image feed
    func loadMediaFeed(feedSources: [AmityFeedSource]? = nil) {
        if let feedSources {
            currentFeedSources = feedSources
        }
        self.medias.removeAll()
        let queryOptions: AmityPostQueryOptions
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postType.rawValue])
            loadPosts(queryOptions, isClipFeed: false)
        case .user(let userId):
            loadUserFollowInfo(userId: userId, dataTypes: [.image], isClipFeed: false)
        }
    }
    
    // Used for querying videos & clip feed
    func loadMediaFeed(feedTab: VideoFeedTab, feedSources: [AmityFeedSource]? = nil) {
        if let feedSources {
            currentFeedSources = feedSources
        }
        self.medias.removeAll()
        self.emptyFeedState = nil

        let queryOptions: AmityPostQueryOptions
        
        let postDataType = feedTab == .videos ? PostTypeFilter.video.rawValue : PostTypeFilter.clip.rawValue
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postDataType])
            loadPosts(queryOptions, isClipFeed: feedTab == .clips)
        case .user(let userId):
            let dataTypes: [AmityPostDataType] = feedTab == .videos ? [AmityPostDataType.video] : [AmityPostDataType.clip]

            loadUserFollowInfo(userId: userId, dataTypes: dataTypes, isClipFeed: feedTab == .clips)
        }
    }
    
    private func loadFollowInfo(userId: String, queryOptions: AmityPostQueryOptions, isClipFeed: Bool) {
        if AmityUIKitManagerInternal.shared.currentUserId == userId {
            myFollowInfoObject = userManager.getMyFollowInfo()
            cancellable = myFollowInfoObject?.$snapshot
                .sink(receiveValue: { [weak self] followInfo in
                    guard let followInfo else { return }
                    let model = AmityFollowInfoModel(followInfo)
                    self?.blockedFeedState = model.status == .blocked ? .blocked : nil
                    if model.status != .blocked {
                        self?.loadPosts(queryOptions, isClipFeed: isClipFeed)
                    }
                })
        }
    }
    
    private func loadUserFollowInfo(userId: String, dataTypes: [AmityPostDataType], isClipFeed: Bool) {
        
        userFollowInfoObject = userManager.getFollowInfo(withId: userId)
        cancellable = userFollowInfoObject?.$snapshot
            .sink(receiveValue: { [weak self] followInfo in
                guard let followInfo else { return }
                let model = AmityFollowInfoModel(followInfo)
                self?.blockedFeedState = model.status == .blocked ? .blocked : nil
                if model.status != .blocked {
                    self?.loadUserPosts(userId: userId, isClipFeed: isClipFeed, dataTypes: dataTypes)
                }
            })
    }
    
    private func loadUserPosts(userId: String, isClipFeed: Bool, dataTypes: [AmityPostDataType]) {

        postCollection = feedManager.getUserFeed(userId: userId, feedSources: currentFeedSources, dataTypes: dataTypes, matchingOnlyParentPost: false)
        token = postCollection?.observe({ [weak self] (collection, changes, error) in
            guard let self else { return }
            
            if let error {
                self.debouner.run {
                    if AmityError(error: error) == .noUserAccessPermission {
                        self.emptyFeedState = .private
                    }
                }
                return
            }
            
            let snapshots = collection.snapshots
            if snapshots.isEmpty {
                self.debouner.run {
                    self.emptyFeedState = .empty
                    return
                }
            } else {
                self.debouner.run {
                    self.emptyFeedState = nil
                    
                    if isClipFeed {
                        let idsToFetch: [String] = snapshots.compactMap { post in
                            let parentId = post.parentPostId ?? ""
                            if let _ = self.postsCache[parentId] {
                                return nil
                            } else {
                                return parentId
                            }
                        }
                        
                        if idsToFetch.isEmpty {
                            self.processMedias(posts: snapshots)
                        } else {
                            self.fetchParentPosts(ids: idsToFetch) {
                                self.processMedias(posts: snapshots)
                            }
                        }
                    } else {
                        self.processMedias(posts: snapshots)
                    }
                }
            }
        })
        
        postCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    // TODO:
    // Investigate further to remove debouncer.
    private func loadPosts(_ queryOptions: AmityPostQueryOptions, isClipFeed: Bool) {
        postCollection = postManager.getPosts(options: queryOptions)
        token = postCollection?.observe({ [weak self] (collection, changes, error) in
            guard let self else { return }
            
            if let error {
                self.debouner.run {
                    if AmityError(error: error) == .noUserAccessPermission {
                        self.emptyFeedState = .private
                    }
                }
                return
            }
            
            let snapshots = collection.snapshots
            if snapshots.isEmpty {
                self.debouner.run {
                    self.emptyFeedState = .empty
                    return
                }
            } else {
                self.debouner.run {
                    self.emptyFeedState = nil
                    
                    let idsToFetch: [String] = snapshots.compactMap { post in
                        let parentId = post.parentPostId ?? ""
                        if let _ = self.postsCache[parentId] {
                            return nil
                        } else {
                            return parentId
                        }
                    }
                    
                    if idsToFetch.isEmpty {
                        self.processMedias(posts: snapshots)
                    } else {
                        self.fetchParentPosts(ids: idsToFetch) {
                            self.processMedias(posts: snapshots)
                        }
                    }
                }
            }
        })
        
        postCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func processMedias(posts: [AmityPost]) {
        let allItems = posts.flatMap { post -> [AmityMedia] in
            let model = AmityPostModel(post: post)
            return model.medias
        }
        
        // Filter out any items that have been marked as deleted
        let filteredItems = allItems.filter { media in
            if let fileId = media.image?.fileId {
                return !deletedFileIds.contains(fileId)
            }
            return true
        }
        
        // Only update if there are new items to avoid UI flicker
        if !filteredItems.isEmpty {
            self.medias = filteredItems
            Log.add(event: .info, "Processed \(filteredItems.count) media items (filtered from \(allItems.count))")
        } else if !allItems.isEmpty && filteredItems.isEmpty {
            // All items were filtered out
            self.medias = []
            Log.add(event: .info, "All \(allItems.count) media items were filtered out")
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
    
    func loadMore() {
        guard let postCollection, postCollection.hasNext else { return }
        postCollection.nextPage()
    }
    
    @objc private func didPostDeleted(_ notification: Notification) {
        if let info = notification.userInfo, let postId = info["postId"] as? String {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Track file IDs from the deleted post to prevent them from reappearing
                let mediaToRemove = self.medias.filter { $0.parentPostId == postId }
                for media in mediaToRemove {
                    if let fileId = media.image?.fileId {
                        self.deletedFileIds.insert(fileId)
                    }
                }
                
                self.medias.removeAll { media in
                    return media.parentPostId == postId
                }
                
            }
        }
    }
    
    @objc private func didPostImageUpdated(_ notification: Notification) {
        if let newDeletedFileIds = notification.userInfo?["deletedFileIds"] as? [String], !newDeletedFileIds.isEmpty {
            Log.add(event: .info, "MediaFeedViewModel received deleted file IDs: \(newDeletedFileIds)")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Add the new deleted file IDs to our tracking set
                for fileId in newDeletedFileIds {
                    self.deletedFileIds.insert(fileId)
                }
                
                self.medias.removeAll { media in
                    if let fileId = media.image?.fileId, newDeletedFileIds.contains(fileId) {
                        Log.add(event: .info, "Removing media with fileId: \(fileId)")
                        return true
                    }
                    return false
                }
                
            }
        }
    }
    func getClipContent(at index: Int) -> AmityPostModel.ClipContent? {
        guard let postCollection, let post = postCollection.object(at: index) else { return nil }
        
        let model = AmityPostModel(post: post)
        
        if case let .clip(clipContent) = model.content {
            return clipContent
        }
        
        return nil
    }

    func getVideoContent(at index: Int) -> AmityPostModel? {
        guard let postCollection, let post = postCollection.object(at: index) else { return nil }
        
        let model = AmityPostModel(post: post)
        
        return model
    }

}
