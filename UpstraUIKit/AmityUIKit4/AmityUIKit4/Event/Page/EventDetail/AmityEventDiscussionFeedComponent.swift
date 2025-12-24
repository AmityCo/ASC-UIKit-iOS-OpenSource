//
//  AmityEventDiscussionFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI
import AmitySDK

struct AmityEventDiscussionFeedComponent: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @ObservedObject var viewModel: AmityEventDetailPageViewModel
    
    @StateObject private var viewConfig: AmityViewConfigController = .init(pageId: .socialHomePage)
    
    init(viewModel: AmityEventDetailPageViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            loadingState
                .visibleWhen(viewModel.loadingStatus == .loading && viewModel.posts.isEmpty)
            
            emptyState
                .visibleWhen(viewModel.loadingStatus == .loaded && viewModel.posts.isEmpty)
            
            discussionFeed
                .visibleWhen(!viewModel.posts.isEmpty)
        }
        .onAppear {
            viewModel.loadDiscussionFeed()
        }
        .updateTheme(with: viewConfig)
    }
    
    var discussionFeed: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.posts, id: \.postId) { post in
                VStack(spacing: 0 ) {
                    AmityPostContentComponent(post: post, context: .init(shouldHideTarget: true, event: viewModel.event))
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                }
                .onAppear {
                    if let lastItem = viewModel.posts.last, lastItem.postId == post.postId {
                        viewModel.loadMoreFeedItems()
                    }
                }
            }
            
            // Extra space at the bottom
            Rectangle()
                .fill(Color.clear)
                .frame(height: 100)
        }
    }
    
    var emptyState: some View {
        HStack {
            Spacer()
            
            AmityEmptyStateView(configuration: .init(image: AmityIcon.communityProfileEmptyPostIcon.rawValue, title: AmityLocalizedStringSet.Social.eventDiscussionFeedNoPostsYet.localizedString, subtitle: nil, iconSize: .init(width: 60, height: 60), renderingMode: .original, imageBottomPadding: 12, tapAction: nil))
            
            Spacer()
        }
        .padding(.top, 100)
    }
    
    var loadingState: some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<2, id: \.self) { index in
                PostContentSkeletonView()
            }
            
            Spacer()
        }
    }
}
