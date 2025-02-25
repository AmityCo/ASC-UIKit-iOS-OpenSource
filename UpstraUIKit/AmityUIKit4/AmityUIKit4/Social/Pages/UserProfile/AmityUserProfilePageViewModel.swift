//
//  AmityUserProfilePageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/18/24.
//

import Combine
import AmitySDK

public class AmityUserProfilePageViewModel: ObservableObject {
    @Published var user: AmityUserModel?
    
    private var cancellable: AnyCancellable?
    private var liveObject: AmityObject<AmityUser>
    private let userManager = UserManager()
    private let userId: String
    
    let profileHeaderViewModel: AmityUserProfileHeaderComponentViewModel
    let imageFeedViewModel: MediaFeedViewModel
    let videoFeedViewModel: MediaFeedViewModel
    let userFeedViewModel: AmityUserFeedComponentViewModel
    
    public init(_ userId: String) {
        self.profileHeaderViewModel = AmityUserProfileHeaderComponentViewModel(userId)
        self.imageFeedViewModel = MediaFeedViewModel(feedType: .user(userId: userId), postType: .image)
        self.videoFeedViewModel = MediaFeedViewModel(feedType: .user(userId: userId), postType: .video)
        self.userFeedViewModel = AmityUserFeedComponentViewModel(userId)
        self.userId = userId
        
        self.liveObject = userManager.getUser(withId: userId)
        self.cancellable = liveObject.$snapshot
            .sink(receiveValue: { [weak self] user in
                guard let user else { return }
                self?.user = AmityUserModel(user: user)
        })
    }
    
    func refreshFeed(currentTab: Int) {
        profileHeaderViewModel.load()
        if currentTab == 0 {
            userFeedViewModel.loadPostFeed()
        } else if currentTab == 1 {
            imageFeedViewModel.loadMediaFeed()
        } else if currentTab == 2 {
            videoFeedViewModel.loadMediaFeed()
        }
    }
    
    func block() async throws {
        try await userManager.blockUser(withId: userId)
    }
    
    func unblock() async throws {
        try await userManager.unblockUser(withId: userId)
    }
    
    @discardableResult
    func flag() async throws -> Bool {
        try await userManager.flagUser(withId: userId)
    }
    
    @discardableResult
    func unflag() async throws -> Bool {
        try await userManager.unflagUser(withId: userId)
    }

    func isFlaggedByMe() async throws -> Bool {
        try await userManager.isUserFlaggedByMe(withId: userId)
    }
}
