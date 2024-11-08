//
//  AmityUserFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/19/24.
//

import SwiftUI
import AmitySDK

public struct AmityUserFeedComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userFeed
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityUserFeedComponentViewModel
    
    public init(userId: String, userProfilePageViewModel: AmityUserProfilePageViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .userFeed))
        if let userProfilePageViewModel {
            self._viewModel = StateObject(wrappedValue: userProfilePageViewModel.userFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: AmityUserFeedComponentViewModel(userId))
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            userFeedView
                .isHidden(viewModel.blockedFeedState != nil || viewModel.emptyFeedState != nil)
            
            if let _ = viewModel.blockedFeedState {
                EmptyUserFeedView(feedType: .post, feedState: .blocked, viewConfig: viewConfig)
            } else if let feedState = viewModel.emptyFeedState {
                EmptyUserFeedView(feedType: .post, feedState: feedState, viewConfig: viewConfig)
            }
        }
        .onAppear {
            viewModel.loadPostFeed()
        }
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private var userFeedView: some View {
        if viewModel.loadingStatus == .loading && viewModel.posts.isEmpty {
            LazyVStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 0) {
                        PostContentSkeletonView()
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                }
            }
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.postId) { index, post in
                    VStack(spacing: 0){
                        AmityPostContentComponent(post: post, onTapAction: { context in
                            let page = AmityPostDetailPage(post: post, context: context)
                            let vc = AmitySwiftUIHostingController(rootView: page)
                            host.controller?.navigationController?.pushViewController(vc, animated: true)
                        }, pageId: pageId)
                        .contentShape(Rectangle())
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                    .onAppear {
                        if index == viewModel.posts.count - 1 {
                            viewModel.loadMore()
                        }
                    }
                }
            }
        }
    }
}
