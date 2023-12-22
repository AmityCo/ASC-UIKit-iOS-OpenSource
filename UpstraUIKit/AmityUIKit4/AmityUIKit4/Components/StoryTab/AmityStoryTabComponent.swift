//
//  AmitStoryTabComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import SwiftUI

public struct AmityStoryTabComponent: AmityComponentView {
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .storyTabComponentId
    }
    
    @ObservedObject public var viewModel: AmityStoryTabComponentViewModel
    
    // MARK: - Initializer
    public init(pageId: PageId? = nil, viewModel: AmityStoryTabComponentViewModel) {
        self.pageId = pageId
        self.viewModel = viewModel
    }
    
    
    // MARK: - ViewModel
    
    public var body: some View {
        AmityView(configType: .component(configId),
                  config: { configDict in
            //
        }) { config in
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    
                    // Note: Refactor this to handle creation from same StoryTargetView.
                    // Show this avatar if story creation is allowed + there is no previous stories.
                    if !viewModel.hideStoryCreation && viewModel.storyTargets.isEmpty {
                        let storyCreationViewModel = StoryCreationViewModel(avartar: viewModel.creatorAvatar, name: "Story", animateRing: false)
                        
                        StoryCreationView(componentId: id, viewModel: storyCreationViewModel)
                            .frame(width: 64, height: 64)
                            .padding(.leading, 2)
                            .onTapGesture {
                                let context = StoryTabComponentBehaviour.Context(component: self, storyTargets: nil, storyCreationTargetId: viewModel.storyCreationTargetId, storyCreationAvatar: viewModel.creatorAvatar)
                                AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCameraPage(context: context)
                            }
                    }
                    
                    // story viewing section
                    ForEach(0..<viewModel.storyTargets.count, id: \.self) { index in
                        let storyTarget = viewModel.storyTargets[index]
                        
                        StoryTargetView(componentId: id, storyTarget: storyTarget, cornerImage: {
                            viewModel.hideStoryCreation ? nil :
                            AmityCreateNewStoryButtonElement(componentId: id)
                                .frame(width: 22.0, height: 22.0)
                                .offset(x: 22, y: 22)
                            
                            // Use this when global feed is implemented.
                            // Image(AmityIcon.verifiedBadge.getImageResource())
                        })
                        .frame(width: 64, height: 64)
                        .padding(.leading, 2)
                        .onTapGesture {
                            Log.add(event: .info, "Index: \(index)")
                            let context = StoryTabComponentBehaviour.Context(component: self, storyTargets: viewModel.storyTargets, storyCreationTargetId: viewModel.storyCreationTargetId, storyCreationAvatar: viewModel.creatorAvatar)
                            AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                        }
                        .onAppear {
                            Log.add(event: .info, "StoryTab appeared!!!")
                        }
                    }
                    
                }.padding([.top, .bottom], 13)
            }
            
        }
        .background(Color.white)
    }
}


public class AmityStoryTabComponentViewModel: ObservableObject {
    @Published public var creatorAvatar: UIImage?
    @Published public var storyTargets: [StoryTarget] = []
    @Published public var hideStoryCreation: Bool = true
    @Published public var isGlobalFeed: Bool = false
    @Published public var storyCreationTargetId: String = ""
    
    public init(storyTargets: [StoryTarget], hideStoryCreation: Bool, creatorAvatar: UIImage?, isGlobalFeed: Bool, storyCreationTargetId: String) {
        self.storyTargets = storyTargets
        self.hideStoryCreation = hideStoryCreation
        self.creatorAvatar = creatorAvatar
        self.isGlobalFeed = isGlobalFeed
        self.storyCreationTargetId = storyCreationTargetId
    }
    
}
