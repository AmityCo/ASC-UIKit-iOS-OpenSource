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
    
    @Published var startedScrollingToBottom: Bool = false
    @Published var showErrorState = false

    @Published var joinStatus: CommunityJoinState = .notJoined
    @Published var joinRequest: AmityJoinRequest?
    
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
    @Published var hasCreatePostPermission = false
    @Published var hasCreateEventPermission = false
    
    let firstLoadTask = OneTimeTask()

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
            
            let community = AmityCommunityModel(object: communityObject)
            self.community = community
            
            // Update joined status
            if community.isJoined {
                self.joinStatus = .joined
            }
            self.pendingPostCount = community.pendingPostCount
            
            // Community observer is triggered multiple times. We want to fetch
            // these data one time only otherwise we hit rate limit error
            self.firstLoadTask.perform {
                self.fetchOtherData()
            }
            
            // Check StoryManage Permission
            Task { @MainActor [weak self] in
                let hasPermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: community.communityId)
                let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
               
                self?.hasStoryManagePermission = (allowAllUserCreation || hasPermission) && community.isJoined
            }
            
            if communityObject.onlyAdminCanPost {
                AmityUIKit4Manager.client.hasPermission(.createPrivilegedPost, forCommunity: community.communityId) { success in
                    self.hasCreatePostPermission = success && community.isJoined
                }
            } else {
                self.hasCreatePostPermission = community.isJoined
            }
            
            AmityUIKit4Manager.client.hasPermission(.createEvent, forCommunity: community.communityId) { [weak self] hasPermission in
                guard let self else { return }
                self.hasCreateEventPermission = hasPermission
            }
            
            // If the user leave the community after approved the join request, refresh the feed.
            if self.joinStatus == .joined && community.isJoined == false {
                self.refreshFeed()
            }
        }
        
        // Note:
        // `pendingPostCount` in community model includes pending posts from other members in that community.
        // So we query for "our" pending posts & determine whether to show banner or not based on its count.
        pendingPostToken = nil
        pendingPostToken = feedManager.getPendingCommunityFeedPosts(communityId: communityId).observe{ [weak self] collection, change, error in
            if let _ = error {
                return
            }
            
            self?.shouldShowPendingBanner = collection.count() != 0
        }
    }
    
    func loadStories() {
        storyToken = nil
        storyCollection = storyManager.getActiveStories(in: communityId)
        storyToken = storyCollection?.observe({ [weak self] collection, _, error in
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
        roomPostsToken = roomPostCollection?.observe { [weak self] collection, _, error in
            let posts = collection.snapshots
            self?.roomPosts = posts.flatMap({ post -> [AmityPostModel] in
                // community linked object is only available in parent post
                let targetCommunity = post.targetCommunity
                
                // Parent post are text posts, we need to filter children posts which are live rooms
                return post.childrenPosts.compactMap({ post -> AmityPostModel? in
                    guard post.dataType == "room" && post.getRoomInfo()?.status == .live else { return nil }
                    let model = AmityPostModel(post: post)
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
        
        pinnedPostToken = collection?.observe { [weak self] collection, _, error in
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
        case .pending:
            self.joinStatus = .requested
        case .success:
            self.joinStatus = .joined
        default:
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
    
    func fetchPendingJoinRequests() {
        guard let community = self.community?.object, community.requiresJoinApproval else { return }
        
        joinRequestsToken = community.getJoinRequests(status: .pending).observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let _ = error { return }
            
            self.joinRequestCount = liveCollection.count()
            self.updatePendingBannerState()
        }
    }
    
    func updatePendingBannerState() {
        self.shouldShowPendingBanner = joinRequestCount > 0 || pendingPostCount > 0
    }
    
    func fetchMyJoinRequest() {
        guard let community = self.community else { return }
        
        // If it doesnot require join approval, no need to query for join requests
        if !community.requiresJoinApproval {
            self.joinStatus = community.isJoined ? .joined : .notJoined
            return
        }
        
        Task { @MainActor in
            do {
                let result = try await community.object.getMyJoinRequest()
                self.joinRequest = result
                                
                switch result.status {
                case .approved:
                    self.joinStatus = .joined
                case .pending:
                    self.joinStatus = .requested
                case .rejected:
                    self.joinStatus = .notJoined
                case .cancelled:
                    break
                @unknown default:
                    break
                }
                
            } catch {
                Log.add(event: .error, "Error while querying user join request for this community")
            }
        }
    }
    
    @MainActor
    func cancelJoinRequest() async {
        self.joinStatus = .notJoined
        
        try? await joinRequest?.cancel()
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
