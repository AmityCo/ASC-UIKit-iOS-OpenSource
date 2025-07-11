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
    
    private let debouner = Debouncer(delay: 0.1)
    let feedType: MediaFeedType
    private var token: AmityNotificationToken?
    private var myFollowInfoObject: AmityObject<AmityMyFollowInfo>?
    private var userFollowInfoObject: AmityObject<AmityUserFollowInfo>?
    private var cancellable: AnyCancellable?
    private let postManager = PostManager()
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
        loadMediaFeed()
    }
    
    // Used for querying image feed
    func loadMediaFeed() {
        self.medias.removeAll()
        let queryOptions: AmityPostQueryOptions
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postType.rawValue])
            loadPosts(queryOptions, isClipFeed: false)
        case .user(let userId):
            queryOptions = AmityPostQueryOptions(targetType: .user, targetId: userId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postType.rawValue])
            loadFollowInfo(userId: userId, queryOptions: queryOptions, isClipFeed: false)
        }
    }
    
    // Used for querying videos & clip feed
    func loadMediaFeed(feedTab: VideoFeedTab) {
        self.medias.removeAll()
        self.emptyFeedState = nil

        let queryOptions: AmityPostQueryOptions
        
        let postDataType = feedTab == .videos ? PostTypeFilter.video.rawValue : PostTypeFilter.clip.rawValue
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postDataType])
            loadPosts(queryOptions, isClipFeed: feedTab == .clips)
        case .user(let userId):
            queryOptions = AmityPostQueryOptions(targetType: .user, targetId: userId, sortBy: .lastCreated, deletedOption: .notDeleted, dataTypes: [postDataType])
            loadFollowInfo(userId: userId, queryOptions: queryOptions, isClipFeed: feedTab == .clips)
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
        } else {
            userFollowInfoObject = userManager.getFollowInfo(withId: userId)
            cancellable = userFollowInfoObject?.$snapshot
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
    
    func processMedias(posts: [AmityPost]) {
        let items = posts.flatMap { post -> [AmityMedia] in
            let model = AmityPostModel(post: post)
            return model.medias
        }
        
        self.medias = items
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
    
    func getClipContent(at index: Int) -> AmityPostModel.ClipContent? {
        guard let postCollection, let post = postCollection.object(at: index) else { return nil }
        
        let model = AmityPostModel(post: post)
        
        if case let .clip(clipContent) = model.content {
            return clipContent
        }
        
        return nil
    }
}
