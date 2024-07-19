//
//  CommunityProfileViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import AmitySDK
import Combine

public class CommunityProfileViewModel: ObservableObject {
    @Published var community: AmityCommunityModel?
    @Published var pinnedPosts: [AmityPostModel] = []
    @Published var pinnedFeedLoadingStatus: AmityLoadingStatus = .notLoading
    
    @Published var announcementPost: AmityPostModel?
    
    @Published var headerHeight: CGFloat = 0
    @Published var stories: [AmityStory] = []
    
    private let communityManger = CommunityManager()
    private let storyManager = StoryManager()
    private let communityId: String
    private let postManager = PostManager()

    private var communityToken: AmityNotificationToken?
    private var storyToken: AmityNotificationToken?
    private var pinnedPostToken: AmityNotificationToken?
    
    private var collection: AmityCollection<AmityPinnedPost>?
    
    var hasStoryManagePermission: Bool = false
    
    var postFeedViewModel: PostFeedViewModel
    
    public init(communityId: String) {
        self.communityId = communityId
        self.postFeedViewModel = PostFeedViewModel(feedType: .community(communityId: communityId))
        
        communityToken = communityManger.getCommunity(withId: communityId).observe { [weak self] community, error in
            guard let communityObject = community.snapshot else { return }
            let community = AmityCommunityModel(object: communityObject)
            self?.community = community
        }
        
        storyToken = storyManager.getActiveStories(in: communityId).observe({ [weak self] collection, _, error in
            let stories = collection.snapshots
            self?.stories = stories
        })
        
        Task {
            hasStoryManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: communityId)
        }

        loadPinnedFeed()
        
    }
    
    func loadPinnedFeed() {
        pinnedPostToken?.invalidate()
        pinnedPostToken = nil

        collection =  postManager.getAllPinnedPost(communityId: communityId)
        
        pinnedPostToken = collection?.observe { [weak self] collection, _, error in
            self?.pinnedPosts = []
            self?.announcementPost = nil

            self?.pinnedFeedLoadingStatus = collection.loadingStatus
            for pinnedpost in collection.snapshots {
                if let post = pinnedpost.post, !post.childrenPosts.contains(where: { $0.dataType == "poll" || $0.dataType == "liveStream" || $0.dataType == "file" }), !post.isDeleted {
                    if pinnedpost.placement == AmityPinPlacement.announcement.rawValue {
                        self?.announcementPost = AmityPostModel(post: post)
                    } else {
                        if let announcementPost = self?.announcementPost, post.postId == announcementPost.postId {
                            continue
                        } else {
                            self?.pinnedPosts.append(AmityPostModel(post: post, isPinned: true))
                        }
                    }
                }
            }
        }
    }
    
    func refreshFeed(currentTab: Int) {
        if currentTab == 0 {
            loadPinnedFeed()
            postFeedViewModel.loadFeed(feedType: .community(communityId: communityId))
        } else {
            loadPinnedFeed()
        }
    }
    
    func getPendingPostCount() -> Int {
        guard let community = community, community.isPostReviewEnabled else {
            return 0
        }
        return community.object.getPostCount(feedType: .reviewing)
    }
    
    func updateHeaderHeight(height: CGFloat) {
        headerHeight = height
    }
    
    @MainActor
    func joinCommunity() async throws {
        try await communityManger.joinCommunity(withId: communityId)
    }
    
    func hasModeratorRole() -> Bool {
        if let communityMember = community?.object.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId) {
            return communityMember.hasModeratorRole
        }
        return false
    }
}
