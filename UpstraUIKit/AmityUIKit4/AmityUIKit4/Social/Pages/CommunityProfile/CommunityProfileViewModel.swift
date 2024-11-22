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
    @Published var pendingPostCount: Int = 0
    @Published var shouldShowPendingBanner: Bool = false
    
    private let communityManger = CommunityManager()
    private let storyManager = StoryManager()
    private let communityId: String
    private let postManager = PostManager()
    private let feedManager = FeedManager()

    private var communityToken: AmityNotificationToken?
    private var pendingPostToken: AmityNotificationToken?
    private var storyToken: AmityNotificationToken?
    private var pinnedPostToken: AmityNotificationToken?
    
    private var collection: AmityCollection<AmityPinnedPost>?
    
    var hasStoryManagePermission: Bool = false
    @Published var hasCreatePostPermission = false

    
    var postFeedViewModel: PostFeedViewModel
    var imageFeedViewModel: MediaFeedViewModel
    var videoFeedViewModel: MediaFeedViewModel
    
    public init(communityId: String) {
        self.communityId = communityId
        self.postFeedViewModel = PostFeedViewModel(feedType: .community(communityId: communityId))
        self.imageFeedViewModel = MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .image)
        self.videoFeedViewModel = MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .video)
        
        loadCommunity()
        loadStories()
        loadPinnedFeed()
        
    }
    
    deinit {
        URLImageService.defaultImageService.inMemoryStore?.removeAllImages()
    }
    
    func loadCommunity() {
        communityToken = nil
        communityToken = communityManger.getCommunity(withId: communityId).observe { [weak self] community, error in
            guard let communityObject = community.snapshot else { return }
            let community = AmityCommunityModel(object: communityObject)
            self?.community = community
            
            self?.pendingPostCount = community.pendingPostCount
            
            // Check StoryManage Permission
            Task { @MainActor [weak self] in
                let hasPermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: community.communityId)
                let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
               
                self?.hasStoryManagePermission = (allowAllUserCreation || hasPermission) && community.isJoined
            }
            
            if communityObject.onlyAdminCanPost {
                AmityUIKit4Manager.client.hasPermission(.createPrivilegedPost, forCommunity: community.communityId) { success in
                    self?.hasCreatePostPermission = success && community.isJoined
                }
            } else {
                self?.hasCreatePostPermission = community.isJoined
            }
        }
        
        
        pendingPostToken = nil
        pendingPostToken = feedManager.getPendingCommunityFeedPosts(communityId: communityId).observe{ [weak self] collection, change, error in
            self?.shouldShowPendingBanner = collection.count() != 0
        }
    }
    
    func loadStories() {
        storyToken = nil
        storyToken = storyManager.getActiveStories(in: communityId).observe({ [weak self] collection, _, error in
            let stories = collection.snapshots
            self?.stories = stories
        })
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
                if let post = pinnedpost.post, !post.childrenPosts.contains(where: { $0.dataType == "file" }), !post.isDeleted {
                    if pinnedpost.placement == AmityPinPlacement.announcement.rawValue {
                        self?.announcementPost = AmityPostModel(post: post)
                    } else {
                        self?.pinnedPosts.append(AmityPostModel(post: post, isPinned: true))
                    }
                }
            }
        }
    }
    
    func refreshFeed(currentTab: Int) {
        loadCommunity()
        loadStories()
        
        if currentTab == 0 {
            loadPinnedFeed()
            postFeedViewModel.loadFeed(feedType: .community(communityId: communityId))
        } else if currentTab == 1 {
            loadPinnedFeed()
        } else if currentTab == 2 {
            imageFeedViewModel.loadMediaFeed()
        } else if currentTab == 3 {
            videoFeedViewModel.loadMediaFeed()
        }
    }
    
    func updateHeaderHeight(height: CGFloat) {
        headerHeight = height
    }
    
    @MainActor
    func joinCommunity() async throws {
        try await communityManger.joinCommunity(withId: communityId)
    }
    
    func isAnnouncementPostPinned() -> Bool {
        return pinnedPosts.contains(where: {$0.postId == announcementPost?.postId})
    }
}
