//
//  CommunityProfileViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import AmitySDK
import Combine
import SwiftUI

enum CommunityJoinState: String {
    // Default case. isJoined is false
    case notJoined
    // requires moderator approval & isJoined is false
    case requested
    // Joined i.e isJoined for community is true
    case joined
}

public class CommunityProfileViewModel: ObservableObject {
    @Published var currentTab = 0
    @Published var community: AmityCommunityModel?
    @Published var pinnedPosts: [AmityPostModel] = []
    @Published var pinnedFeedLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var pinnedFeedError: Error? = nil
    @Published var pendingCommunityInvitation: AmityInvitation?
    
    @Published var announcementPost: AmityPostModel?
    
    @Published var stories: [AmityStory] = []
    @Published var roomPosts: [AmityPostModel] = []
    @Published var isStoryTabLoading: Bool = true
    private var cancellable: Set<AnyCancellable> = []
    @Published var pendingPostCount: Int = 0
    @Published var joinRequestCount: Int = 0
    @Published var shouldShowPendingBanner: Bool = false
    private var userPendingPostCount: Int = 0
    
    @Published var startedScrollingToBottom: Bool = false
    @Published var showErrorState = false

    @Published var joinRequest: AmityJoinRequest?
    
    var joinStatus: CommunityJoinState {
        guard let community else { return .notJoined }
        
        if community.isJoined { return .joined }
        
        // Note:
        // An `.approved` join request does not imply membership. A user who left the
        // community still has one, so only `isJoined` above can determine that.
        if community.requiresJoinApproval, joinRequest?.status == .pending { return .requested }
        
        return .notJoined
    }
    
    private let communityManger = CommunityManager()
    private let storyManager = StoryManager()
    private let communityId: String
    private let postManager = PostManager()
    private let feedManager = FeedManager()

    private var communityToken: AmityNotificationToken?
    private var pendingPostToken: AmityNotificationToken?
    private var storyToken: AmityNotificationToken?
    private var roomPostsToken: AmityNotificationToken?
    private var pinnedPostToken: AmityNotificationToken?
    private var joinRequestsToken: AmityNotificationToken?
    
    private var collection: AmityCollection<AmityPinnedPost>?
    private var storyCollection: AmityCollection<AmityStory>?
    private var roomPostCollection: AmityCollection<AmityPost>?
    
    @Published var hasStoryManagePermission: Bool = false
    /// Add-user permission is a prerequisite for approving join requests, so it also grants access to the pending join requests.
    @Published var hasAddCommunityUserPermission: Bool = false
    /// REVIEW_COMMUNITY_POST — grants seeing all pending posts and the pending-posts banner.
    @Published var hasReviewPermission: Bool = false
    @Published var hasCreatePostPermission = false
    @Published var hasCreateEventPermission = false
    
    let firstLoadTask = OneTimeTask()
    let refreshFeedAfterUserJoinedCommunityTask = OneTimeTask()

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
    
    /// We fetch associated data with this community.
    /// These data needs to be refreshed when community needs to appear again
    func fetchOtherData() {
        guard let _ = community else { return }
                
        self.loadPendingInvitations()
        self.checkAddCommunityUserPermission()
        self.fetchPendingJoinRequests()
        self.fetchMyJoinRequest()
    }

    func loadCommunity() {
        communityToken = nil
        communityToken = communityManger.getCommunity(withId: communityId).observe { [weak self] community, error in
            guard let self else { return }
            
            if let _ = error {
                self.showErrorState = true
                return
            }
            
            guard let communityObject = community.snapshot else { return }
            
            // Note:
            // Captured before `self.community` is overwritten below. `joinStatus` is
            // derived from it, so it would already reflect the new value afterwards.
            let wasJoined = self.community?.isJoined ?? false
            
            let community = AmityCommunityModel(object: communityObject)
            self.community = community
            
            self.pendingPostCount = community.pendingPostCount
            self.updatePendingBannerState()

            // Community observer is triggered multiple times. We want to fetch
            // these data one time only otherwise we hit rate limit error
            self.firstLoadTask.perform {
                self.fetchOtherData()
            }
            
            // Check StoryManage Permission
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                let hasPermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: community.communityId)
                let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
               
                self.hasStoryManagePermission = (allowAllUserCreation || hasPermission) && community.isJoined
                
                if communityObject.onlyAdminCanPost {
                    Task {
                        self.hasCreatePostPermission = await AmityUIKit4Manager.client.hasPermission(.createPrivilegedPost, forCommunity: community.communityId)
                    }
                } else {
                    self.hasCreatePostPermission = community.isJoined
                }
                
                self.hasCreateEventPermission = await AmityUIKit4Manager.client.hasPermission(.createEvent, forCommunity: community.communityId)
            }
            
            // If the user leave the community after approved the join request, refresh the feed.
            if wasJoined && community.isJoined == false {
                self.refreshFeedAfterUserJoinedCommunityTask.perform {
                    self.refreshFeed()
                }
            }
        }
        
        // Note:
        // `pendingPostCount` in community model includes pending posts from other members in that community.
        // So we query for "our" pending posts & determine whether to show banner or not based on its count.
        pendingPostToken = nil
        pendingPostToken = feedManager.getPendingCommunityFeedPosts(communityId: communityId).observe{ [weak self] collection, error in
            if let _ = error {
                return
            }
            
            self?.userPendingPostCount = collection.snapshots.count
            self?.updatePendingBannerState()
        }
    }
    
    func loadStories() {
        storyToken = nil
        storyCollection = storyManager.getActiveStories(in: communityId)
        storyToken = storyCollection?.observe({ [weak self] collection, error in
            let stories = collection.snapshots
            self?.stories = stories
        })
        
        storyCollection?.$loadingStatus
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.isStoryTabLoading = status == .loading
            })
            .store(in: &cancellable)
        
        roomPostsToken = nil
        roomPostCollection = postManager.getCommunityLiveRoomPosts(communityId: communityId)
        roomPostsToken = roomPostCollection?.observe { [weak self] collection, error in
            let posts = collection.snapshots
            self?.roomPosts = posts.flatMap({ post -> [AmityPostModel] in
                // community linked object is only available in parent post
                let targetCommunity = post.targetCommunity
                
                // Parent post are text posts, we need to filter children posts which are live rooms
                return post.childrenPosts.compactMap({ childPost -> AmityPostModel? in
                    guard childPost.dataType == "room" && childPost.getRoomInfo()?.status == .live && post.getFeedType() == .published else { return nil }
                    let model = AmityPostModel(post: childPost)
                    model.targetCommunity = targetCommunity
                    return model
                })
                
            })
        }
        
        roomPostCollection?.$loadingStatus
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.isStoryTabLoading = status == .loading
            }).store(in: &cancellable)
    }
    
    func loadPinnedFeed() {
        pinnedPostToken?.invalidate()
        pinnedPostToken = nil

        collection =  postManager.getAllPinnedPost(communityId: communityId)
        
        pinnedPostToken = collection?.observe { [weak self] collection, error in
            self?.pinnedPosts = []
            self?.announcementPost = nil
            
            if error != nil {
                self?.pinnedFeedError = error
            }
            
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
    
    public func refreshFeed() {
        firstLoadTask.reset()
        
        loadCommunity()
        loadStories()
        
        // Note:
        // For video tab, loading of videos or clips is handled from inside the component itself.
        if currentTab == 0 {
            loadPinnedFeed()
            postFeedViewModel.loadFeed(feedType: .community(communityId: communityId))
        } else if currentTab == 1 {
            loadPinnedFeed()
        } else if currentTab == 2 {
            imageFeedViewModel.loadMediaFeed()
        }
    }
    
    @MainActor
    func joinCommunity() async throws {
        guard let community else { return }
        
        let joinResult = try await community.object.join()
        
        switch joinResult {
        case .pending(let request):
            // `joinStatus` derives `.requested` from this.
            self.joinRequest = request
        case .success:
            // The join response updates `isJoined`, so the community observer drives
            // `joinStatus` to `.joined`.
            self.joinRequest = nil
            self.refreshFeed()
        @unknown default:
            break
        }
    }
    
    func isAnnouncementPostPinned() -> Bool {
        return pinnedPosts.contains(where: {$0.postId == announcementPost?.postId})
    }
    
    func loadPendingInvitations() {
        Task { @MainActor in
            self.pendingCommunityInvitation = await community?.object.getInvitation()
        }
    }
    
    func checkAddCommunityUserPermission() {
        let communityId = self.communityId
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            self.hasAddCommunityUserPermission = await CommunityPermissionChecker.hasAddCommunityUserPermission(communityId: communityId)
            self.hasReviewPermission = await CommunityPermissionChecker.hasReviewCommunityPostPermission(communityId: communityId)
            self.updatePendingBannerState()
        }
    }
    
    func fetchPendingJoinRequests() {
        guard let community = self.community?.object, community.requiresJoinApproval else { return }
        
        joinRequestsToken = community.getJoinRequests(status: .pending).observe { [weak self] liveCollection, error in
            guard let self else { return }
            
            if let _ = error { return }
            
            self.joinRequestCount = liveCollection.snapshots.count
            self.updatePendingBannerState()
        }
    }
    
    func updatePendingBannerState() {
        guard let community else {
            self.shouldShowPendingBanner = false
            return
        }
        let relevantPostCount = hasReviewPermission ? pendingPostCount : userPendingPostCount
        let postsContribute = community.isPostReviewEnabled && relevantPostCount > 0
        let canReviewJoinRequests = hasAddCommunityUserPermission
        let requestsContribute = canReviewJoinRequests && community.requiresJoinApproval && joinRequestCount > 0
        self.shouldShowPendingBanner = postsContribute || requestsContribute
    }
    
    func fetchMyJoinRequest() {
        guard let community = self.community else { return }
        
        // If it doesnot require join approval, no need to query for join requests
        if !community.requiresJoinApproval {
            self.joinRequest = nil
            return
        }
        
        Task { @MainActor in
            do {
                // We only store it here. `joinStatus` is what interprets it.
                self.joinRequest = try await community.object.getMyJoinRequest()
            } catch {
                // No request exists for this user, i.e it is gone after leaving the community.
                self.joinRequest = nil
                Log.add(event: .error, "Error while querying user join request for this community")
            }
        }
    }
    
    @MainActor
    func cancelJoinRequest() async {
        // Cleared optimistically so the join button comes back right away.
        let request = self.joinRequest
        self.joinRequest = nil
        
        do {
            try await request?.cancel()
        } catch {
            // Restore the real state if the cancellation did not go through.
            fetchMyJoinRequest()
        }
    }
    
    deinit {
        URLImageService.defaultImageService.inMemoryStore?.removeAllImages()
    }
}

// Since we cannot use Task due to ios 14+ support, we create a class to perform one time operation on view appear
class OneTimeTask: ObservableObject {
    
    private var isPerformed = false
    
    func perform(_ task: @escaping () -> Void) {
        guard !isPerformed else { return }
        
        isPerformed = true
        
        task()
    }
    
    func reset() {
        isPerformed = false
    }
}
