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
                if let storyTarget = viewModel.communityFeedStoryTarget {
                    HStack {
                        StoryTargetView(componentId: id, storyTarget: storyTarget, storyTargetName: "Story", hideLockIcon: true, cornerImage: {
                            viewModel.hasManagePermission ? AmityCreateNewStoryButtonElement(componentId: id)
                                .frame(width: 20.0, height: 20.0)
                                .offset(x: 22, y: 22) : nil
                            
                        })
                        .frame(width: 64, height: 64)
                        .padding(EdgeInsets(top: 13, leading: 2, bottom: 13, trailing: 0))
                        .onTapGesture {
                            if storyTarget.itemCount == 0 && viewModel.hasManagePermission {
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                      storyFeedType: .communityFeed(storyTarget.targetId),
                                                                                      targetId: storyTarget.targetId,
                                                                                      targetType: .community)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCreateStoryPage(context: context)
                            } else {
                                let context = AmityStoryTabComponentBehaviour.Context(component: self, 
                                                                                      storyFeedType: .communityFeed(storyTarget.targetId),
                                                                                      targetId: storyTarget.targetId,
                                                                                      targetType: .community)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                            }
                        }
                        .onAppear {
                            viewModel.communityFeedStoryTarget?.fetchStory()
                        }
                        Spacer()
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
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
                    
                    StoryTargetView(componentId: id, storyTarget: storyTarget, hideLockIcon: storyTarget.isPublicTarget, cornerImage: {
                        storyTarget.isVerifiedTarget ? Image(AmityIcon.verifiedBadge.getImageResource())
                            .frame(width: 22.0, height: 22.0)
                            .offset(x: 22, y: 22) : nil
                    })
                    .frame(width: 64, height: 64)
                    .padding(.leading, 2)
                    .onTapGesture {
                        Log.add(event: .info, "Tapped StoryTargetIndex: \(index)")
                        let context = AmityStoryTabComponentBehaviour.Context(component: storyTabComponent,
                                                                         storyFeedType: .globalFeed,
                                                                         targetId: storyTarget.targetId,
                                                                         targetType: .community)
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
    private var storyTargetObject: AmityObject<AmityStoryTarget>?
    
    @Published var hasManagePermission: Bool = true
    
    private var storyFeedType: AmityStoryTabComponentType
    private let storyManager = StoryManager()
    private var cancellable: AnyCancellable?
    
    public init(type: AmityStoryTabComponentType) {
        self.storyFeedType = type
        
        switch storyFeedType {
        case .globalFeed:
            loadGlobalFeedStoryTargets()
            
        case .communityFeed(let communityId):
            loadCommunityStoryTarget(communityId)
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
}
