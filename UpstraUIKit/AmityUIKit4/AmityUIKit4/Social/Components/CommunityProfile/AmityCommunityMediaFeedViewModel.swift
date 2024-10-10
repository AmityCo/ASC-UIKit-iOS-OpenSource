//
//  AmityCommunityMediaFeedViewModel.swift
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
    private let feedType: MediaFeedType
    private var token: AmityNotificationToken?
    private var myFollowInfoObject: AmityObject<AmityMyFollowInfo>?
    private var userFollowInfoObject: AmityObject<AmityUserFollowInfo>?
    private var cancellable: AnyCancellable?
    private let postManager = PostManager()
    private let userManager = UserManager()
    private var postCollection: AmityCollection<AmityPost>?
    private let postType: PostTypeFilter
    
    @Published var showMediaViewer: Bool = false
    var selectedMediaIndex: Int = 0
    var videoURL: URL? = nil
    
    init(feedType: MediaFeedType, postType: PostTypeFilter) {
        self.feedType = feedType
        self.postType = postType
        loadMediaFeed()
    }
    
    func loadMediaFeed() {
        self.medias.removeAll()
        let queryOptions: AmityPostQueryOptions
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: [postType.rawValue])
            loadPosts(queryOptions)
        case .user(let userId):
            queryOptions = AmityPostQueryOptions(targetType: .user, targetId: userId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: [postType.rawValue])
            loadFollowInfo(userId: userId, queryOptions: queryOptions)
        }
        
    }
    
    private func loadFollowInfo(userId: String, queryOptions: AmityPostQueryOptions) {
        if AmityUIKitManagerInternal.shared.currentUserId == userId {
            myFollowInfoObject = userManager.getMyFollowInfo()
            cancellable = myFollowInfoObject?.$snapshot
                .sink(receiveValue: { [weak self] followInfo in
                    guard let followInfo else { return }
                    let model = AmityFollowInfoModel(followInfo)
                    self?.blockedFeedState = model.status == .blocked ? .blocked : nil
                    if model.status != .blocked {
                        self?.loadPosts(queryOptions)
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
                        self?.loadPosts(queryOptions)
                    }
                })
        }
    }
    
    private func loadPosts(_ queryOptions: AmityPostQueryOptions) {
        postCollection = postManager.getPosts(options: queryOptions)
        token = postCollection?.observe({ [weak self] (collection, changes, error) in
            self?.medias.removeAll()
            
            if let error {
                self?.debouner.run {
                    if AmityError(error: error) == .noUserAccessPermission {
                        self?.emptyFeedState = .private
                    }
                }
                return
            }
            
            self?.debouner.run {
                guard !collection.allObjects().isEmpty else {
                    self?.emptyFeedState = .empty
                    return
                }
                
                self?.emptyFeedState = nil
                // Traverse all post to prepare the data soruce.
                self?.medias.append(contentsOf: collection.allObjects().flatMap { post -> [AmityMedia] in
                    let model = AmityPostModel(post: post)
                    return model.medias
                })
            }
        })
        
        postCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func loadMore() {
        guard let postCollection, postCollection.hasNext else { return }
        postCollection.nextPage()
    }
}
