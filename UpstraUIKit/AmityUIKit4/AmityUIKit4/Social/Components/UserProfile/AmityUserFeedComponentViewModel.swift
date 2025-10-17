//
//  AmityUserFeedComponentViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/19/24.
//

import Foundation
import Combine
import AmitySDK

class AmityUserFeedComponentViewModel: ObservableObject {
    @Published var posts: [AmityPost] = []
    @Published var emptyFeedState: EmptyUserFeedViewState?
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    private let userId: String
    
    private let debouner = Debouncer(delay: 0.2)
    private let feedManager = FeedManager()
    private let userManager = UserManager()
    private var userFeedCollection: AmityCollection<AmityPost>?
    private var myFollowInfoObject: AmityObject<AmityMyFollowInfo>?
    private var userFollowInfoObject: AmityObject<AmityUserFollowInfo>?
    private var cancellable: AnyCancellable?
    private var token: AmityNotificationToken?
    private var userFollowInfoToken: AmityNotificationToken?
    
    private var isOwnUser: Bool {
        return AmityUIKitManagerInternal.shared.currentUserId == userId
    }
    
    var currentFeedSources: [AmityFeedSource]
    
    init(_ userId: String) {
        self.userId = userId
        self.currentFeedSources = [.user, .community]
    }
    
    func loadPostFeed(feedSources: [AmityFeedSource]? = nil) {
        if let feedSources {
            currentFeedSources = feedSources
        }
        loadFollowInfo(feedSources: currentFeedSources)
    }
    
    private func loadFollowInfo(feedSources: [AmityFeedSource]) {
        if isOwnUser {
            myFollowInfoObject = userManager.getMyFollowInfo()
            cancellable = myFollowInfoObject?.$snapshot
                .sink(receiveValue: { [weak self] followInfo in
                    guard let followInfo else { return }
                    let model = AmityFollowInfoModel(followInfo)
                    self?.emptyFeedState = model.status == .blocked ? .blocked : nil
                    if model.status != .blocked {
                        self?.loadPosts(feedSources: feedSources)
                    }
                })
        } else {
            userFollowInfoObject = userManager.getFollowInfo(withId: userId)
            userFollowInfoToken = userFollowInfoObject?.observe({ [weak self] liveObject, error in
                guard let self else { return }
                if let error, error.isAmityErrorCode(.visitorPermissionDenied) {
                    self.emptyFeedState = .private
                    return
                }
                
                if let followInfo = liveObject.snapshot {
                    let model = AmityFollowInfoModel(followInfo)
                    self.emptyFeedState = model.status == .blocked ? .blocked : nil
                    if model.status != .blocked {
                        self.loadPosts(feedSources: feedSources)
                    }
                }
            })
        }
    }
    
    private func loadPosts(feedSources: [AmityFeedSource]) {
        userFeedCollection = feedManager.getUserFeed(userId: userId, feedSources: feedSources)
        token = userFeedCollection?.observe({ [weak self] (collection, changes, error) in
            if let error {
                self?.debouner.run {
                    self?.posts.removeAll()
                    if AmityError(error: error) == .noUserAccessPermission {
                        self?.emptyFeedState = .private
                    }
                }
                return
            }
            
            self?.debouner.run {
                guard !collection.allObjects().isEmpty else {
                    self?.posts.removeAll()
                    self?.emptyFeedState = .empty
                    return
                }
                
                self?.emptyFeedState = nil
                let posts = collection.allObjects()
                
                self?.posts = posts.filter { !$0.childrenPosts.contains { $0.dataType == "file" || $0.dataType == "audio" || $0.structureType == "mixed" } }
            }
        })
        
        userFeedCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func loadMore() {
        guard let userFeedCollection, userFeedCollection.hasNext else { return }
        userFeedCollection.nextPage()
    }
}
