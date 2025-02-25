//
//  AmityGlobalFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/3/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityGlobalFeedComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var postFeedViewModel = PostFeedViewModel(feedType: .globalFeed)
    
    public var id: ComponentId {
        .globalFeedComponent
    }
    
    public init(pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .globalFeedComponent))
    }
    
    public var body: some View {
        List {
            ForEach(Array(postFeedViewModel.postItems.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    
                    switch item.type {
                    case .ad(let ad):
                        
                        VStack(spacing: 0) {
                            AmityFeedAdContentComponent(ad: ad)

                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(height: 8)
                        }
                        
                    case .content(let post):
                        
                        VStack(spacing: 0){
                            AmityPostContentComponent(post: post.object, category: post.isPinned ? .global : .general, onTapAction: { postContext in
                                let context = AmityGlobalFeedComponentBehavior.Context(component: self, post: post, showPollResult: postContext?.showPollResults ?? false)
                                AmityUIKitManagerInternal.shared.behavior.globalFeedComponentBehavior?.goToPostDetailPage(context: context)
                            }, pageId: pageId)
                            .contentShape(Rectangle())
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .onChange(of: geometry.frame(in: .global)) { frame in
                                        checkVisibilityAndMarkSeen(postContentFrame: frame, post: post)
                                    }
                            })
                            
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(height: 8)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
                .onAppear {
                    if index == postFeedViewModel.postItems.count - 1 {
                        postFeedViewModel.loadMorePosts()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func checkVisibilityAndMarkSeen(postContentFrame: CGRect, post: AmityPostModel) {
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, postContentFrame.maxY) - max(0, postContentFrame.minY)
        let visiblePercentage = (visibleHeight / postContentFrame.height) * 100
        
        if visiblePercentage > 60 && !postFeedViewModel.seenPostIds.contains(post.postId) {
            postFeedViewModel.seenPostIds.insert(post.postId)
            post.analytic.markAsViewed()
        }
    }
}

