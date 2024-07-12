//
//  AmityCommunityFeedComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import SwiftUI

public struct AmityCommunityFeedComponent: AmityComponentView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    private let communityId: String
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var postFeedViewModel: PostFeedViewModel
    
    public var id: ComponentId {
        .communityFeed
    }
    
    public init(communityId: String, pageId: PageId? = nil) {
        self.communityId = communityId
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityFeed))
        self._postFeedViewModel = StateObject(wrappedValue: PostFeedViewModel(feedType: .community(communityId: communityId)))
    }
    
    
    @ViewBuilder
    func getContentView() -> some View {
        if #available(iOS 15.0, *) {
            getPostListView()
                .refreshable {
                    // just to show/hide story view
                    //                viewModel.loadStoryTargets()
                    // refresh global feed
                    // swiftUI cannot update properly if we use nested Observable Object
                    // that is the reason why postFeedViewModel is not moved into viewModel
                    postFeedViewModel.loadFeed(feedType: .community(communityId: communityId))
                }
        } else {
            getPostListView()
        }
    }
    
    @ViewBuilder
    func getPostListView() -> some View {
        List {
            if postFeedViewModel.postItems.isEmpty {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 0) {
                        PostContentSkeletonView()
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
            } else {
                
                if let announcementPost = postFeedViewModel.announcementPost {
                    VStack(spacing: 0){
                        AmityPostContentComponent(post: announcementPost.object, style: .announcement_feed, hideTarget: true, onTapAction: {
                            let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: announcementPost.object, style: .announcement_detail))
                            host.controller?.navigationController?.pushViewController(vc, animated: true)
                        }, pageId: pageId)
                        .contentShape(Rectangle())
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
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
                                AmityPostContentComponent(post: post.object, hideTarget: true, onTapAction: {
                                    let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object))
                                    host.controller?.navigationController?.pushViewController(vc, animated: true)
                                }, pageId: pageId)
                                .contentShape(Rectangle())
                                
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
        }
        .listStyle(.plain)
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            getContentView()
                .opacity(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded ? 0 : 1)
            
            AmityEmptyNewsFeedComponent(pageId: pageId)
                .opacity(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded ? 1 : 0)
        }
        .updateTheme(with: viewConfig)
    }
}
