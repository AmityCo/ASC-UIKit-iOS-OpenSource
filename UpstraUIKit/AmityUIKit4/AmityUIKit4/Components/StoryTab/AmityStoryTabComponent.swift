//
//  AmitStoryTabComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import SwiftUI
import AmitySDK
import Combine

public enum StoryFeedType {
    case global
    case community(AmityCommunity)
}

public struct AmityStoryTabComponent: AmityComponentView {
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .storyTabComponent
    }
    
    @StateObject private var viewModel: AmityStoryTabComponentViewModel
    private let storyFeedType: StoryFeedType
    
    // MARK: - Initializer
    public init(pageId: PageId? = nil, storyFeedType: StoryFeedType) {
        self.pageId = pageId
        self.storyFeedType = storyFeedType
        self._viewModel = StateObject(wrappedValue: AmityStoryTabComponentViewModel(storyFeedType: storyFeedType))
    }
    
    
    // MARK: - ViewModel
    
    public var body: some View {
        AmityView(configId: configId,
                  config: { configDict in
            //
        }) { config in
            switch storyFeedType {
                
            case .global:
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        
                        // Note: Refactor this to handle creation from same StoryTargetView.
                        // Show this avatar if story creation is allowed + there is no previous stories.
                        if viewModel.hasManagePermission {
                            let storyCreationViewModel = StoryCreationViewModel(avartar: nil, name: "Story", animateRing: false)
                            
                            StoryCreationView(componentId: id, viewModel: storyCreationViewModel)
                                .frame(width: 64, height: 64)
                                .padding(.leading, 2)
                                .onTapGesture {
                                    let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                     storyTargets: nil,
                                                                                     storyCreationTargetId: "",
                                                                                     storyCreationAvatar: nil)
                                    AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCreateStoryPage(context: context)
                                }
                        }
                        
                        // story viewing section
                        ForEach(0..<viewModel.globalFeedStoryTargets.count, id: \.self) { index in
                            let storyTarget = viewModel.globalFeedStoryTargets[index]
                            
                            StoryTargetView(componentId: id, storyTarget: storyTarget, cornerImage: {
                                storyTarget.isVerifiedTarget ? Image(AmityIcon.verifiedBadge.getImageResource())
                                    .frame(width: 22.0, height: 22.0)
                                    .offset(x: 22, y: 22) : nil
                            })
                            .frame(width: 64, height: 64)
                            .padding(.leading, 2)
                            .onTapGesture {
                                Log.add(event: .info, "Index: \(index)")
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                 storyTargets: viewModel.globalFeedStoryTargets,
                                                                                 storyCreationTargetId: storyTarget.targetId,
                                                                                 storyCreationAvatar: storyTarget.avatar)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                            }
                            .onAppear {
                                Log.add(event: .info, "StoryTab appeared!!!")
                            }
                        }
                        
                    }.padding([.top, .bottom], 13)
                }
                
            case .community(_):
                if let storyTarget = viewModel.communityFeedStoryTarget {
                    HStack {
                        StoryTargetView(componentId: id, storyTarget: storyTarget, storyTargetName: "Story", cornerImage: {
                            viewModel.hasManagePermission ? AmityCreateNewStoryButtonElement(componentId: id)
                                .frame(width: 22.0, height: 22.0)
                                .offset(x: 22, y: 22) : nil
                            
                        })
                        .frame(width: 64, height: 64)
                        .padding(EdgeInsets(top: 13, leading: 2, bottom: 13, trailing: 0))
                        .onTapGesture {
                            if storyTarget.storyCount == 0 && viewModel.hasManagePermission {
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                 storyTargets: nil,
                                                                                 storyCreationTargetId: storyTarget.targetId,
                                                                                 storyCreationAvatar: storyTarget.avatar)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCreateStoryPage(context: context)
                            } else {
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                 storyTargets: [storyTarget],
                                                                                 storyCreationTargetId: storyTarget.targetId,
                                                                                 storyCreationAvatar: storyTarget.avatar)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                            }
                        }
                        .onAppear {
                            Log.add(event: .info, "StoryTab appeared!!!")
                        }
                        Spacer()
                    }
                }
            }
        }
        .background(Color.white)
    }
}


class AmityStoryTabComponentViewModel: ObservableObject {
    @Published var globalFeedStoryTargets: [StoryTarget] = []
    @Published var communityFeedStoryTarget: StoryTarget?
    @Published var hasManagePermission: Bool = true
    
    private var storyFeedType: StoryFeedType
    private let storyManager = StoryManager()
    private var cancellable: AnyCancellable?
    
    public init(storyFeedType: StoryFeedType) {
        self.storyFeedType = storyFeedType
        
        switch storyFeedType {
        case .global: break
            
        case .community(let community):
            Task {
                do {
                    let avatar = try await AmityUIKitManagerInternal.shared.fileService.loadImage(imageURL: community.avatar?.fileURL ?? "", size: .medium)
                    await loadCommunityStoryTarget(community: community, avatar: avatar)
                } catch {
                    await loadCommunityStoryTarget(community: community, avatar: AmityIcon.defaultCommunityAvatar.getImage())
                }
                
            }
        }
    }
    
    @MainActor
    private func loadCommunityStoryTarget(community: AmityCommunity, avatar: UIImage?) {
        let collection = storyManager.getActiveStories(in: community.communityId)
        let storyTarget = StoryTarget(targetId: community.communityId,
                                      targetName: community.displayName,
                                      isVerifiedTarget: community.isOfficial,
                                      avatar: avatar,
                                      stories: collection)
        self.communityFeedStoryTarget = storyTarget
        self.hasManagePermission = StoryPermissionChecker.shared.checkUserHasManagePermission()
        
        cancellable = nil
        cancellable = collection.$snapshots
            .sink { stories in
                storyTarget.storyCount = stories.count
                
                guard stories.count > 0 else {
                    storyTarget.hasUnseenStory = false
                    storyTarget.hasFailedStory = false
                    storyTarget.hasSyncingStory = false
                    
                    return
                }
                
                if let hasUnseen = stories.first?.storyTarget?.hasUnseen {
                    storyTarget.hasUnseenStory = hasUnseen
                }
                
                if let failedStoryCount = stories.first?.storyTarget?.failedStoriesCount {
                    Log.add(event: .info, "FailedStoryCount: \(failedStoryCount)")
                    storyTarget.hasFailedStory = failedStoryCount != 0
                }
                
                if let syncingStoryCount = stories.first?.storyTarget?.syncingStoriesCount {
                    Log.add(event: .info, "SyncingStoryCount: \(syncingStoryCount)")
                    storyTarget.hasSyncingStory = syncingStoryCount != 0
                }
                
                
            }
    }
    
}
