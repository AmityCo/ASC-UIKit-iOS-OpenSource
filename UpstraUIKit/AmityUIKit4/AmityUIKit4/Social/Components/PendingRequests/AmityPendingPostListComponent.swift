import AmitySDK
import Combine
//
//  AmityPendingPostListComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 27/5/25.
//
import SwiftUI

public struct AmityPendingPostListComponent: AmityComponentView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController

    @StateObject private var viewModel: AmityPendingPostPageViewModel
    private let community: AmityCommunityModel

    public var pageId: PageId?

    public var id: ComponentId {
        .pendingPostListComponent
    }

    public init(community: AmityCommunity, pageId: PageId? = nil, onChange: ((Int) -> Void)? = nil){
        self.pageId = pageId
        self.community = AmityCommunityModel(object: community)
        self._viewModel = StateObject(
            wrappedValue: AmityPendingPostPageViewModel(community: community, onChange: onChange))

        UITableView.appearance().separatorStyle = .none
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 60)
                .overlay(
                    Text("Decline pending post will permanently delete the selected post from community.")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .padding([.leading, .trailing], 16)
                )
                .isHidden(!community.hasModeratorRole)

            if viewModel.showEmpty {
                getEmptyView()
            } else {
                getContentView()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }

    @ViewBuilder
    func getEmptyView() -> some View {
        VStack(spacing: 8) {
            Spacer()

            Image(AmityIcon.emptyPendingPostIcon.getImageResource())
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)

            Text(AmityLocalizedStringSet.Social.communityPendingPostsEmptyStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))

            Spacer()
        }
    }

    @ViewBuilder
    func getContentView() -> some View {
        if viewModel.showLoading {
            List {
                ForEach(0..<5, id: \.self) { index in
                    PostContentSkeletonView()
                        .listRowInsets(EdgeInsets())
                        .modifier(HiddenListSeparator())
                }
            }
            .listStyle(.plain)
            .environmentObject(viewConfig)
        } else {
            if #available(iOS 15.0, *) {
                getPostListView()
                    .refreshable {
                        viewModel.getPendingCommunityFeedPosts()
                    }
            } else {
                getPostListView()
            }
        }
    }

    @ViewBuilder
    func getPostListView() -> some View {
        List {
            ForEach(Array(viewModel.posts.enumerated()), id: \.element.postId) { index, post in
                VStack(spacing: 0) {
                    AmityPendingPostContentComponent(pageId: .communityPendingPostPage, post: post)

                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                        .isHidden(index == viewModel.posts.count - 1)
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
                .onAppear {
                    if index == viewModel.posts.count - 1 {
                        viewModel.loadMorePosts()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
