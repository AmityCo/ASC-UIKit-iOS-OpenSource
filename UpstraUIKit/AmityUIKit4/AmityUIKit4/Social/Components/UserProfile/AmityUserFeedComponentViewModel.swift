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
    @Published var blockedFeedState: EmptyUserFeedViewState?
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
    
    private var isOwnUser: Bool {
        return AmityUIKitManagerInternal.shared.currentUserId == userId
    }
    
    init(_ userId: String) {
        self.userId = userId
    }
    
    func loadPostFeed() {
        loadFollowInfo()
    }
    
    private func loadFollowInfo() {
        if isOwnUser {
            myFollowInfoObject = userManager.getMyFollowInfo()
            cancellable = myFollowInfoObject?.$snapshot
                .sink(receiveValue: { [weak self] followInfo in
                    guard let followInfo else { return }
                    let model = AmityFollowInfoModel(followInfo)
                    self?.blockedFeedState = model.status == .blocked ? .blocked : nil
                    if model.status != .blocked {
                        self?.loadPosts()
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
                        self?.loadPosts()
                    }
                })
        }
    }
    
    private func loadPosts() {
        userFeedCollection = feedManager.getUserFeed(userId: userId)
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
                
                self?.posts = posts.filter { !$0.childrenPosts.contains { $0.dataType == "liveStream" || $0.dataType == "file" } }
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
