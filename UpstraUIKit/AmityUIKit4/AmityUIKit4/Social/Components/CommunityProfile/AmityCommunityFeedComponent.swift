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
    @StateObject private var communityProfileViewModel: CommunityProfileViewModel
    
    public var id: ComponentId {
        .communityFeed
    }
    
    var onTapAction: ((AmityPostModel, AmityPostContentComponent.Context?) -> Void)?

    public init(communityId: String, pageId: PageId? = nil, communityProfileViewModel: CommunityProfileViewModel? = nil, onTapAction: ((AmityPostModel, AmityPostContentComponent.Context?) -> Void)? = nil) {
        self.communityId = communityId
        self.pageId = pageId
        self.onTapAction = onTapAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityFeed))
        if let communityProfileViewModel {
            self._postFeedViewModel = StateObject(wrappedValue: communityProfileViewModel.postFeedViewModel)
            self._communityProfileViewModel = StateObject(wrappedValue: communityProfileViewModel)
        } else {
            self._postFeedViewModel = StateObject(wrappedValue: PostFeedViewModel(feedType: .community(communityId: communityId)))
            self._communityProfileViewModel = StateObject(wrappedValue: CommunityProfileViewModel(communityId: communityId))
        }
    }
    
    @ViewBuilder
    func getContentView() -> some View {
        getPostListView()
    }
    
    @ViewBuilder
    func getPostListView() -> some View {
        LazyVStack(spacing: 0) {
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
                
                if let announcementPost = communityProfileViewModel.announcementPost {
                    VStack(spacing: 0) {
                        let category: AmityPostCategory = communityProfileViewModel.isAnnouncementPostPinned() ? .pinAndAnnouncement : .announcement
                        AmityPostContentComponent(post: announcementPost.object, style: .feed, category: category, hideTarget: true, onTapAction: { postContext in
                            onTapAction?(AmityPostModel(post: announcementPost.object), postContext)
                        }, pageId: pageId)
                        .contentShape(Rectangle())
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
                
                ForEach(Array(postFeedViewModel.postItems.filter({$0.id != communityProfileViewModel.announcementPost?.postId ?? ""}).enumerated()), id: \.element.id) { index, item in
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
                            
                            VStack(spacing: 0) {
                                let category: AmityPostCategory = communityProfileViewModel.pinnedPosts.contains(where: {$0.postId == post.postId}) ? .pin : .general
                                AmityPostContentComponent(post: post.object, category: category, hideTarget: true, onTapAction: { postContext in
                                    onTapAction?(post, postContext)
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
                        if index == postFeedViewModel.postItems.filter({$0.id != communityProfileViewModel.announcementPost?.postId ?? ""}).count - 1 {
                            postFeedViewModel.loadMorePosts()
                        }
                    }
                }
            }
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            getContentView()
                .isHidden(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded)
            
            EmptyCommunityFeedView()
                .isHidden(!(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded))
        }
        .updateTheme(with: viewConfig)
    }
    
    
    private func checkVisibilityAndMarkSeen(postContentFrame: CGRect, post: AmityPostModel) {
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, postContentFrame.maxY) - max(0, postContentFrame.minY)
        let visiblePercentage = (visibleHeight / postContentFrame.height) * 100
        
        if visiblePercentage > 60 && !postFeedViewModel.seenPostIds.contains(post.postId) {
            postFeedViewModel.seenPostIds.insert(post.postId)
            DispatchQueue.main.async {
                post.analytic.markAsViewed()
            }
        }
    }
}
