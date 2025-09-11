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
    
    private var userCancellable: AnyCancellable?
    private var feedStateCancellable: AnyCancellable?
    private var liveObject: AmityObject<AmityUser>?
    private let userManager = UserManager()
    private let userId: String
    
    let profileHeaderViewModel: AmityUserProfileHeaderComponentViewModel
    let imageFeedViewModel: MediaFeedViewModel
    let videoFeedViewModel: MediaFeedViewModel
    let userFeedViewModel: AmityUserFeedComponentViewModel
    
    @Published var feedState: EmptyUserFeedViewState = .empty
    
    enum ProfileFeedSource {
        case all, community, user
        
        var feedSources: [AmityFeedSource] {
            switch self {
            case .all:
                return [.community, .user]
            case .community:
                return [.community]
            case .user:
                return [.user]
            }
        }
        
        var text: String {
            switch self {
            case .all:
                return AmityLocalizedStringSet.Social.userProfileAllPostTitle.localizedString
            case .community:
                return AmityLocalizedStringSet.Social.userProfileCommunityPostTitle.localizedString
            case .user:
                return AmityLocalizedStringSet.Social.userProfileUserPostTitle.localizedString
            }
        }
    }
    
    var currentFeedSource: ProfileFeedSource = .all
    
    public init(_ userId: String) {
        self.profileHeaderViewModel = AmityUserProfileHeaderComponentViewModel(userId)
        self.imageFeedViewModel = MediaFeedViewModel(feedType: .user(userId: userId), postType: .image)
        self.videoFeedViewModel = MediaFeedViewModel(feedType: .user(userId: userId), postType: .video)
        self.userFeedViewModel = AmityUserFeedComponentViewModel(userId)
        self.userId = userId
    }
    
    func loadUser() {
        self.liveObject = userManager.getUser(withId: userId)
        self.userCancellable = liveObject?.$snapshot
            .sink(receiveValue: { [weak self] user in
                guard let user else { return }
                self?.user = AmityUserModel(user: user)
        })
        
        feedStateCancellable = userFeedViewModel.$emptyFeedState.sink { state in
            self.feedState = state ?? .empty
        }
    }
    
    func refreshFeed(currentTab: Int, feedSources: [AmityFeedSource]? = nil) {
        profileHeaderViewModel.load()
        // Note:
        // For video tab, loading of videos or clips is handled from inside the component itself.
        if currentTab == 0 {
            userFeedViewModel.loadPostFeed()
        } else if currentTab == 1 {
            imageFeedViewModel.loadMediaFeed()
        }
    }
    
    func refreshAllFeeds(profileFeedSource: ProfileFeedSource) {
        profileHeaderViewModel.load()
        
        currentFeedSource = profileFeedSource
        
        userFeedViewModel.loadPostFeed(feedSources: profileFeedSource.feedSources)
        imageFeedViewModel.loadMediaFeed(feedSources: profileFeedSource.feedSources)
        videoFeedViewModel.currentFeedSources = profileFeedSource.feedSources
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
