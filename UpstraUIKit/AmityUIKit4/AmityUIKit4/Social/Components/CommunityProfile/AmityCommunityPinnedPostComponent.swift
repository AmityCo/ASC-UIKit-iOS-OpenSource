//
//  AmityCommunityPinnedPostComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 17/7/2567 BE.
//

import SwiftUI

public struct AmityCommunityPinnedPostComponent: AmityComponentView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    private let communityId: String
    
    @StateObject private var viewConfig: AmityViewConfigController
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
            self._communityProfileViewModel = StateObject(wrappedValue: communityProfileViewModel)
        } else {
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
            if communityProfileViewModel.pinnedPosts.isEmpty {
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
                if let announcementPost = communityProfileViewModel.announcementPost, communityProfileViewModel.isAnnouncementPostPinned() {
                    VStack(spacing: 0) {
                        AmityPostContentComponent(post: announcementPost.object, style: .feed, category: .pinAndAnnouncement, hideTarget: true, onTapAction: { postContext in
                            
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
                ForEach(Array(communityProfileViewModel.pinnedPosts.filter({$0.postId != communityProfileViewModel.announcementPost?.postId ?? ""}) .enumerated()), id: \.element.id) { index, post in
                    VStack(spacing: 0) {
                        AmityPostContentComponent(post: post.object, category: .pin, hideTarget: true, onTapAction: { postContext in
                            
                            onTapAction?(AmityPostModel(post: post.object), postContext)
                        }, pageId: pageId)
                        .contentShape(Rectangle())
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
            }
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            getContentView()
                .isHidden(communityProfileViewModel.pinnedPosts.isEmpty && communityProfileViewModel.pinnedFeedLoadingStatus == .loaded)
            
            EmptyCommunityFeedView()
                .isHidden(!(communityProfileViewModel.pinnedPosts.isEmpty && communityProfileViewModel.pinnedFeedLoadingStatus == .loaded))
        }
        .updateTheme(with: viewConfig)
    }
}
