//
//  StoryCommunityFeedView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/25/25.
//

import SwiftUI

struct StoryCommunityFeedView: View {
    let id: ComponentId
    @ObservedObject var viewModel: AmityStoryTabComponentViewModel
    let storyTabComponent: AmityStoryTabComponent
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                Color.clear.frame(height: 1)
                
                storyTargetView
                communityRoomTargetViews
            }
        }
    }
    
    @ViewBuilder
    private var storyTargetView: some View {
        if let storyTarget = viewModel.communityFeedStoryTarget {
            StoryTargetView(radius: 56.0, componentId: id, storyTarget: storyTarget, storyTargetName: "Story", hideLockIcon: true, cornerImage: {
                viewModel.hasManagePermission ? AmityCreateNewStoryButtonElement(componentId: id)
                    .frame(width: 18, height: 18)
                    .offset(x: 19, y: 19) : nil
                
            })
            .frame(width: 56, height: 56)
            .padding(EdgeInsets(top: 13, leading: 0, bottom: 13, trailing: 0))
            .contentShape(Rectangle())
            .onTapGesture {
                if storyTarget.itemCount == 0 && viewModel.hasManagePermission {
                    let context = AmityStoryTabComponentBehaviour.Context(component: storyTabComponent,
                                                                          storyFeedType: .communityFeed(storyTarget.targetId),
                                                                          targetId: storyTarget.targetId,
                                                                          targetType: .community)
                    AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToCreateStoryPage(context: context)
                } else {
                    let context = AmityStoryTabComponentBehaviour.Context(component: storyTabComponent,
                                                                          storyFeedType: .communityFeed(storyTarget.targetId),
                                                                          targetId: storyTarget.targetId,
                                                                          targetType: .community)
                    AmityUIKitManagerInternal.shared.behavior.storyTabComponentBehaviour?.goToViewStoryPage(context: context)
                }
            }
            .isHidden(storyTarget.itemCount == 0 && !viewModel.hasManagePermission)
            .onAppear {
                viewModel.communityFeedStoryTarget?.fetchStory()
            }
        }
    }
    
    @ViewBuilder
    private var communityRoomTargetViews: some View {
        ForEach(Array(viewModel.liveStreamPosts.enumerated()), id: \.element.postId)  { index, post in
            LiveRoomCommunityTargetView(post: post)
                .frame(width: 56, height: 56)
                .padding(.leading, 2)
                .onAppear {
                    viewModel.loadMoreLiveStreamPostsIfHas(index)
                }
                .onTapGesture {
                    let livestreamPlayerPage = AmityLivestreamPlayerPage(postModel: post)
                    let hostController = AmitySwiftUIHostingNavigationController(rootView: livestreamPlayerPage)
                    hostController.isNavigationBarHidden = true
                    hostController.modalPresentationStyle = .overFullScreen
                    storyTabComponent.host.controller?.present(hostController, animated: true)
                }
        }
    }
}
