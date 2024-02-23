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
    @EnvironmentObject public var host: SwiftUIHostWrapper
    
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
                StoryGlobalFeedView(id: id, viewModel: viewModel, storyTabComponent: self)
                
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
                                                                                 storyTargets: [],
                                                                                 storyCreationTargetId: storyTarget.targetId,
                                                                                 storyCreationAvatar: storyTarget.avatar,
                                                                                 startFromTargetIndex: 0)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCreateStoryPage(context: context)
                            } else {
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                 storyTargets: [storyTarget],
                                                                                 storyCreationTargetId: storyTarget.targetId,
                                                                                 storyCreationAvatar: storyTarget.avatar,
                                                                                 startFromTargetIndex: 0)
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

struct StoryGlobalFeedView: View {
    let id: ComponentId
    @ObservedObject var viewModel: AmityStoryTabComponentViewModel
    let storyTabComponent: AmityStoryTabComponent
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(Array(viewModel.globalFeedStoryTargets.enumerated()), id: \.element.targetId)  { index, storyTarget in
                    
                    StoryTargetView(componentId: id, storyTarget: storyTarget, cornerImage: {
                        storyTarget.isVerifiedTarget ? Image(AmityIcon.verifiedBadge.getImageResource())
                            .frame(width: 22.0, height: 22.0)
                            .offset(x: 22, y: 22) : nil
                    })
                    .frame(width: 64, height: 64)
                    .padding(.leading, 2)
                    .onTapGesture {
                        Log.add(event: .info, "Tapped StoryTargetIndex: \(index)")
                        let context = AmityStoryTabComponentBehaviour.Context(component: storyTabComponent,
                                                                         storyTargets: viewModel.globalFeedStoryTargets,
                                                                         storyCreationTargetId: storyTarget.targetId,
                                                                         storyCreationAvatar: storyTarget.avatar,
                                                                         startFromTargetIndex: index)
                        AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                    }
                    .onAppear {
                        viewModel.loadMoreGlobalFeedTargetIfHas(index)
                    }
                    .tag(index)
                }
            }
            .padding([.top, .bottom], 30)
            .padding([.leading, .trailing], 18)
        }
    }
}


class AmityStoryTabComponentViewModel: ObservableObject {
    @Published var globalFeedStoryTargets: [AmityStoryTargetModel] = []
    private var globalFeedCollection: AmityCollection<AmityStoryTarget>?
    @Published var communityFeedStoryTarget: AmityStoryTargetModel?
    @Published var hasManagePermission: Bool = true
    
    private var storyFeedType: StoryFeedType
    private let storyManager = StoryManager()
    private var cancellable: AnyCancellable?
    
    public init(storyFeedType: StoryFeedType) {
        self.storyFeedType = storyFeedType
        
        switch storyFeedType {
        case .global:
            loadGlobalFeedStoryTargets()
            
        case .community(let community):
            loadCommunityStoryTarget(community: community)
        }
    }
    
    private func loadGlobalFeedStoryTargets() {
        globalFeedCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
        cancellable = nil
        cancellable = globalFeedCollection?.$snapshots
            .map { targets in
                return targets.compactMap { target -> AmityStoryTargetModel? in
                    guard let community = target.community else { return nil }
                    return AmityStoryTargetModel(storyTarget: target, 
                                       targetId: community.communityId,
                                       targetName: community.displayName,
                                       isVerifiedTarget: community.isOfficial,
                                       isPublicTarget: community.isPublic,
                                       avatar: URL(string: community.avatar?.fileURL ?? ""))
                }.removeDuplicates()
            }
            .assign(to: \.globalFeedStoryTargets, on: self)
    }
    
    
    private func loadCommunityStoryTarget(community: AmityCommunity) {
        let storyTarget = AmityStoryTargetModel(targetId: community.communityId,
                                      targetName: community.displayName,
                                      isVerifiedTarget: community.isOfficial,
                                      isPublicTarget: community.isPublic,
                                      avatar: URL(string: community.avatar?.fileURL ?? ""))
        storyTarget.fetchStory()
        self.communityFeedStoryTarget = storyTarget
        Task { @MainActor in
            self.hasManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: storyTarget.targetId)
        }
    }
    
    func loadMoreGlobalFeedTargetIfHas(_ index: Int) {
        guard let collection = globalFeedCollection else { return }
        if index == collection.snapshots.count - 1 && collection.hasPrevious {
            collection.previousPage()
        }
    }
}
