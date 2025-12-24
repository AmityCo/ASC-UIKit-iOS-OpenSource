//
//  StoryGlobalFeedView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/25/25.
//

import SwiftUI

struct StoryGlobalFeedView: View {
    let id: ComponentId
    @ObservedObject var viewModel: AmityStoryTabComponentViewModel
    let storyTabComponent: AmityStoryTabComponent
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                globalRoomTargetViews
                storyTargetViews
            }
            .padding([.top, .bottom], 30)
            .padding([.leading, .trailing], 18)
        }
    }
    
    @ViewBuilder
    private var globalRoomTargetViews: some View {
        ForEach(Array(viewModel.liveStreamPosts.enumerated()), id: \.element.postId)  { index, post in
            LiveRoomGlobalTargetView(post: post)
                .frame(width: 64, height: 64)
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
    
    @ViewBuilder
    private var storyTargetViews: some View {
        ForEach(Array(viewModel.globalFeedStoryTargets.enumerated()), id: \.element.targetId)  { index, storyTarget in
            
            StoryTargetView(radius: 64.0, componentId: id, storyTarget: storyTarget, hideLockIcon: storyTarget.isPublicTarget, cornerImage: {
                storyTarget.isVerifiedTarget ? Image(AmityIcon.verifiedBadgeWithBorder.imageResource)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .offset(x: 22, y: 20) : nil
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
}

