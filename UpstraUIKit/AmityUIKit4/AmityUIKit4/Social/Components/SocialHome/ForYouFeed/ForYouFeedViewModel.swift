//
//  ForYouFeedViewModel.swift
//  AmityUIKit4
//
//  Created by Claude on 4/6/26.
//

import Foundation
import AmitySDK
import Combine

class ForYouFeedViewModel: ObservableObject {

    @Published var postItems: [PaginatedItem<AmityPostModel>] = []
    @Published var feedLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var didLoadFirstPage: Bool = false
    @Published var isFeedExhausted: Bool = false

    // Stories rail
    @Published var storyTargets: [AmityStoryTarget] = []
    @Published var roomPosts: [AmityPostModel] = []
    @Published var isStoryTabLoading: Bool = true

    var onFeatureDisabled: (() -> Void)? {
        didSet {
            if pendingFeatureDisabled, let onFeatureDisabled {
                pendingFeatureDisabled = false
                onFeatureDisabled()
            }
        }
    }

    private let feedManager = FeedManager()
    private let postManager = PostManager()
    private let storyManager = StoryManager()

    private var collection: AmityCollection<AmityPost>?
    private var paginator: UIKitPaginator<AmityPost>?

    private var feedCancellable: AnyCancellable?
    private var loadingCancellable: AnyCancellable?
    private var errorCancellable: AnyCancellable?

    // Global pinned (featured) posts
    private var pinnedPostCollection: AmityCollection<AmityPinnedPost>?
    private var pinnedPostCancellable: AnyCancellable?
    private var globalPinnedPosts: [AmityPost] = []
    private var globalPinnedPostsIds: Set<String> = []
    private var recentlyCreatedPosts: [AmityPost] = []
    private var feedPosts: [PaginatedItem<AmityPost>] = []

    // Stories rail collections
    private var storyTargetCollection: AmityCollection<AmityStoryTarget>?
    private var storyTargetCancellable: AnyCancellable?
    private var storyTargetLoadingCancellable: AnyCancellable?
    private var roomPostCollection: AmityCollection<AmityPost>?
    private var roomPostCancellable: AnyCancellable?
    private var roomPostLoadingCancellable: AnyCancellable?

    private var seenPostIds = Set<String>()
    private var meaningfullyViewedPostIds = Set<String>()
    private var dwellTimers: [String: DispatchWorkItem] = [:]
    private var renderPositionByPostId: [String: Int] = [:]

    private let meaningfulViewDwell: TimeInterval = 1.0
    private let meaningfulViewVisibility: CGFloat = 50
    private let impressionVisibility: CGFloat = 60

    private var pendingFeatureDisabled = false
    private var didAttemptSnapshotRecovery = false

    init() {
        loadFeed()
        loadStoryTargets()
        loadRoomPosts()

        NotificationCenter.default.addObserver(self, selector: #selector(didPostCreated(_:)), name: .didPostCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPostEdited(_:)), name: .didPostEdited, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPostDeleted(_:)), name: .didPostDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPostReacted(_:)), name: .didPostReacted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didPollUpdated(_:)), name: .didPollUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLivestreamStatusUpdated(_:)), name: .didLivestreamStatusUpdated, object: nil)
    }

    func loadFeed() {
        fetchGlobalPinnedPost()

        let collection = feedManager.getForYouFeedPosts()
        self.collection = collection

        let paginator = UIKitPaginator(liveCollection: collection, adPlacement: .feed, modelIdentifier: { $0.postId })
        paginator.load()
        self.paginator = paginator

        feedCancellable = paginator.$snapshots.sink { [weak self] items in
            guard let self else { return }
            self.feedPosts = items
            self.renderFeed()
            self.refreshFeedState()
        }

        loadingCancellable = collection.$loadingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.feedLoadingStatus = status
                if status == .loaded {
                    self.didLoadFirstPage = true
                    self.didAttemptSnapshotRecovery = false
                }
                self.refreshFeedState()
            }

        errorCancellable = collection.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self, let error else { return }
                let nsError = error as NSError
                let httpStatusCode = nsError.userInfo["httpStatusCode"] as? Int

                if httpStatusCode == 403 {
                    if let onFeatureDisabled = self.onFeatureDisabled {
                        onFeatureDisabled()
                    } else {
                        self.pendingFeatureDisabled = true
                    }
                } else if httpStatusCode == 400 || nsError.code == 400322 {
                    guard !self.didAttemptSnapshotRecovery else { return }
                    self.didAttemptSnapshotRecovery = true
                    self.loadFeed()
                }
            }
    }

    func loadMore() {
        guard let paginator, paginator.hasNextPage() else { return }
        paginator.nextPage()
    }

    private func refreshFeedState() {
        guard let paginator else { return }
        guard didLoadFirstPage, feedLoadingStatus != .loading else {
            isFeedExhausted = false
            return
        }
        isFeedExhausted = !paginator.hasNextPage()
    }

    // MARK: - Recently created posts (current user)

    @objc private func didPostCreated(_ notification: Notification) {
        guard let object = notification.object as? AmityPost else { return }

        if let community = object.targetCommunity, community.isPostReviewEnabled { return }

        if !recentlyCreatedPosts.contains(where: { $0.postId == object.postId }) {
            recentlyCreatedPosts.append(object)
            renderFeed()
        }
    }

    @objc private func didPostDeleted(_ notification: Notification) {
        guard let info = notification.userInfo, let postId = info["postId"] as? String else { return }
        if recentlyCreatedPosts.contains(where: { $0.postId == postId }) {
            recentlyCreatedPosts.removeAll { $0.postId == postId }
            renderFeed()
        }
    }

    @objc private func didPostEdited(_ notification: Notification) { refreshRecentlyCreatedPost(notification.object) }
    @objc private func didPostReacted(_ notification: Notification) { refreshRecentlyCreatedPost(notification.object) }
    @objc private func didPollUpdated(_ notification: Notification) { refreshRecentlyCreatedPost(notification.object) }
    @objc private func didLivestreamStatusUpdated(_ notification: Notification) { refreshRecentlyCreatedPost(notification.object) }

    private func refreshRecentlyCreatedPost(_ object: Any?) {
        guard let post = object as? AmityPost,
              let index = recentlyCreatedPosts.firstIndex(where: { $0.postId == post.postId }),
              let snapshot = postManager.getPost(withId: post.postId).snapshot else { return }
        recentlyCreatedPosts[index] = snapshot
        renderFeed()
    }

    // MARK: - Stories rail (global stories + live rooms)

    func loadStoryTargets() {
        storyTargetCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
        storyTargetCancellable = storyTargetCollection?.$snapshots
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { [weak self] targets in
                self?.storyTargets = targets
            }

        storyTargetLoadingCancellable = storyTargetCollection?.$loadingStatus
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.isStoryTabLoading = status == .loading
            })
    }

    func loadRoomPosts() {
        roomPostCollection = postManager.getGlobalLiveRoomPosts()
        roomPostCancellable = roomPostCollection?.$snapshots
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.roomPosts = posts.flatMap({ post -> [AmityPostModel] in
                    let targetCommunity = post.targetCommunity

                    return post.childrenPosts.compactMap({ post -> AmityPostModel? in
                        guard post.dataType == "room" && post.getRoomInfo()?.status == .live else { return nil }
                        let model = AmityPostModel(post: post)
                        model.targetCommunity = targetCommunity
                        return model
                    })
                })
            }

        roomPostLoadingCancellable = roomPostCollection?.$loadingStatus
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.isStoryTabLoading = status == .loading
            })
    }

    // MARK: - Featured (global pinned) posts

    private func fetchGlobalPinnedPost() {
        pinnedPostCancellable = nil
        globalPinnedPosts = []
        globalPinnedPostsIds = []

        pinnedPostCollection = postManager.getGlobalPinnedPost()
        pinnedPostCancellable = pinnedPostCollection?.$snapshots.sink { [weak self] result in
            guard let self else { return }

            var pinnedPostIds = Set<String>()
            let pinnedPosts = result.compactMap { pinned -> AmityPost? in
                if let postId = pinned.post?.postId {
                    pinnedPostIds.insert(postId)
                }
                return pinned.post
            }

            self.globalPinnedPosts = pinnedPosts
            self.globalPinnedPostsIds = pinnedPostIds

            self.renderFeed()
        }
    }

    // MARK: - Feed assembly

    private func renderFeed() {
        var listItems = [PaginatedItem<AmityPostModel>]()
        var positions: [String: Int] = [:]
        var rankedIndex = 0
        var injectedIds = Set<String>()

        for post in globalPinnedPosts {
            guard canRenderPost(post: post) else { continue }
            injectedIds.insert(post.postId)
            listItems.append(.init(id: post.postId, type: .content(AmityPostModel(post: post, isPinned: true))))
        }

        for post in recentlyCreatedPosts {
            guard canRenderPost(post: post), !injectedIds.contains(post.postId) else { continue }
            injectedIds.insert(post.postId)
            listItems.append(.init(id: post.postId, type: .content(AmityPostModel(post: post))))
        }

        feedPosts.forEach { item in
            switch item.type {
            case .ad(let ad):
                listItems.append(PaginatedItem(id: item.id, type: .ad(ad)))
            case .content(let post):
                guard !injectedIds.contains(post.postId) else { return }
                positions[post.postId] = rankedIndex
                rankedIndex += 1
                listItems.append(PaginatedItem(id: item.id, type: .content(AmityPostModel(post: post))))
            }
        }

        self.renderPositionByPostId = positions
        self.postItems = listItems
    }

    private func canRenderPost(post: AmityPost) -> Bool {
        guard !post.isDeleted else { return false }
        return !post.childrenPosts.contains { $0.dataType == "file" || $0.dataType == "audio" || $0.structureType == "mixed" }
    }

    // MARK: - Analytics

    func updateVisibility(post: AmityPostModel, visiblePercentage: CGFloat) {
        let postId = post.postId
        guard let renderPosition = renderPositionByPostId[postId] else { return }

        if visiblePercentage > impressionVisibility, !seenPostIds.contains(postId) {
            seenPostIds.insert(postId)
            post.analytic.markAsViewed()
        }

        if visiblePercentage >= meaningfulViewVisibility {
            guard !meaningfullyViewedPostIds.contains(postId), dwellTimers[postId] == nil else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.dwellTimers[postId] = nil
                guard !self.meaningfullyViewedPostIds.contains(postId) else { return }
                self.meaningfullyViewedPostIds.insert(postId)
                post.analytic.markAsMeaningfullyViewed(feedRenderPosition: renderPosition)
            }
            dwellTimers[postId] = work
            DispatchQueue.main.asyncAfter(deadline: .now() + meaningfulViewDwell, execute: work)
        } else {
            dwellTimers[postId]?.cancel()
            dwellTimers[postId] = nil
        }
    }

    deinit {
        dwellTimers.values.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }
}
