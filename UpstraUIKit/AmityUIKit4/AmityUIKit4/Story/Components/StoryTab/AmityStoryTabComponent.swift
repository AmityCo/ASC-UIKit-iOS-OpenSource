//
//  AmitStoryTabComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import SwiftUI
import AmitySDK
import Combine

public enum AmityStoryTabComponentType {
    case globalFeed
    case communityFeed(String)
}

public struct AmityStoryTabComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .storyTabComponent
    }
    
    @StateObject private var viewModel: AmityStoryTabComponentViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    private let storyFeedType: AmityStoryTabComponentType
    
    // MARK: - Initializer
    public init(type: AmityStoryTabComponentType, pageId: PageId? = nil) {
        self.pageId = pageId
        self.storyFeedType = type
        self._viewModel = StateObject(wrappedValue: AmityStoryTabComponentViewModel(type: type))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .storyTabComponent))
    }
    
    
    // MARK: - ViewModel
    
    public var body: some View {
        AmityView(configId: configId,
                  config: { configDict in
            //
        }) { config in
            switch storyFeedType {
                
            case .globalFeed:
                StoryGlobalFeedView(id: id, viewModel: viewModel, storyTabComponent: self)
                
            case .communityFeed(_):
                StoryCommunityFeedView(id: id, viewModel: viewModel, storyTabComponent: self)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}

class AmityStoryTabComponentViewModel: ObservableObject {
    @Published var globalFeedStoryTargets: [AmityStoryTargetModel] = []
    private var globalFeedCollection: AmityCollection<AmityStoryTarget>?
    
    @Published var communityFeedStoryTarget: AmityStoryTargetModel?
    private var storyTargetObject: AmityObject<AmityStoryTarget>?
    
    @Published var hasManagePermission: Bool = true
    
    private var storyFeedType: AmityStoryTabComponentType
    private let storyManager = StoryManager()
    private let postManager = PostManager()
    private var cancellable: AnyCancellable?
    
    // Live Stream Room posts
    @Published var liveStreamPosts: [AmityPostModel] = []
    private var liveStreamPostCollection: AmityCollection<AmityPost>?
    private var liveStreamPostCancellable: AnyCancellable?
    
    public init(type: AmityStoryTabComponentType) {
        self.storyFeedType = type
        
        switch storyFeedType {
        case .globalFeed:
            loadGlobalFeedStoryTargets()
            loadGlobalLiveStreamPosts()
            
        case .communityFeed(let communityId):
            loadCommunityStoryTarget(communityId)
            loadCommunityLiveStreamPosts(communityId)
        }
    }
    
    private func loadGlobalFeedStoryTargets() {
        globalFeedCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
        cancellable = nil
        cancellable = globalFeedCollection?.$snapshots
            .map { targets in
                return targets.compactMap { target -> AmityStoryTargetModel? in
                    return AmityStoryTargetModel(target)
                }.removeDuplicates()
            }
            .assign(to: \.globalFeedStoryTargets, on: self)
    }
    
    private func loadCommunityStoryTarget(_ communityId: String) {
        storyTargetObject = storyManager.getStoryTarget(targetType: .community, targetId: communityId)
        cancellable = nil
        cancellable = storyTargetObject?.$snapshot
            .sink(receiveValue: { [weak self] target in
                guard let target else { return }
                
                // Check StoryManage Permission
                Task { @MainActor [weak self] in
                    let hasPermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: communityId)
                    let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
                   
                    guard let community = target.community else {
                        self?.hasManagePermission = false
                        return
                    }
                        
                    self?.hasManagePermission = (allowAllUserCreation || hasPermission) && community.isJoined
                }
                
                if let existingModel = self?.communityFeedStoryTarget {
                    existingModel.updateModel(target)
                } else {
                    self?.communityFeedStoryTarget = AmityStoryTargetModel(target)
                    self?.communityFeedStoryTarget?.fetchStory()
                }
            })
    }
    
    func loadMoreGlobalFeedTargetIfHas(_ index: Int) {
        guard let collection = globalFeedCollection else { return }
        if index == collection.snapshots.count - 1 && collection.hasNext {
            collection.nextPage()
        }
    }
    
    private func loadGlobalLiveStreamPosts() {
        liveStreamPostCollection = postManager.getGlobalLiveRoomPosts()
        observeRoomPosts(liveStreamPostCollection)
    }
    
    private func loadCommunityLiveStreamPosts(_ communityId: String) {
        liveStreamPostCollection = postManager.getCommunityLiveRoomPosts(communityId: communityId)
        observeRoomPosts(liveStreamPostCollection)
    }
    
    private func observeRoomPosts(_ collection: AmityCollection<AmityPost>?) {
        liveStreamPostCancellable = collection?.$snapshots
            .sink { [weak self] posts in
                self?.liveStreamPosts = posts.flatMap({ post -> [AmityPostModel] in
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
    }
    
    func loadMoreLiveStreamPostsIfHas(_ index: Int) {
        guard let collection = liveStreamPostCollection else { return }
        if index == collection.snapshots.count - 1 && collection.hasNext {
            collection.nextPage()
        }
    }
}
