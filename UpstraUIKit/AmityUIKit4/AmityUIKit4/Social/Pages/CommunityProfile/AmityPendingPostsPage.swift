//
//  AmityPendingPostsPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/29/24.
//

import SwiftUI
import AmitySDK
import Combine

@available(*, deprecated, message: "Pending Posts are now reusable under AmityPendingPostListComponent. This is used in PendingRequestPage")
public struct AmityPendingPostsPage: AmityPageView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityPendingPostPageViewModel
    private let community: AmityCommunityModel
    
    public var id: PageId {
        .communityPendingPostPage
    }
    
    public init(community: AmityCommunity) {
        self.community = AmityCommunityModel(object: community)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPendingPostPage))
        self._viewModel = StateObject(wrappedValue: AmityPendingPostPageViewModel(community: community))
        
        UITableView.appearance().separatorStyle = .none
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
                .padding(.bottom, 8)
            
            if viewModel.showEmpty {
                getEmptyView()
            } else {
                getContentView()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    
    private var navigationBarView: some View {
        let title = viewConfig.getText(elementId: .title) ?? "Pending posts"

        return AmityNavigationBar(title: "\(title) (\(viewModel.posts.count))", showBackButton: true)
    }
    
    
    @ViewBuilder
    func getEmptyView() -> some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image(AmityIcon.emptyPendingPostIcon.getImageResource())
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text("No post to review")
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
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(height: 60)
            .overlay(
                Text("Decline pending post will permanently delete the selected post from community.")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .padding([.leading, .trailing], 16)
            )
            .isHidden(!community.hasModeratorRole)
        
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


class AmityPendingPostPageViewModel: ObservableObject {
    @Published var posts: [AmityPost] = []
    @Published var showLoading: Bool = false
    @Published var showEmpty: Bool = false
    
    private let feedManager = FeedManager()
    private let community: AmityCommunity
    private var feedCollection: AmityCollection<AmityPost>?
    var cancellables = Set<AnyCancellable>()
    
    let onChange: ((Int) -> Void)?
    
    init(community: AmityCommunity, onChange: ((Int) -> Void)? = nil) {
        self.community = community
        self.onChange = onChange
        getPendingCommunityFeedPosts()
        
        $posts
            .combineLatest($showLoading)
            .sink { [weak self] posts, showLoading in
                self?.showEmpty = posts.isEmpty && !showLoading
            }
            .store(in: &cancellables)
    }
    
    func getPendingCommunityFeedPosts() {
        feedCollection = feedManager.getPendingCommunityFeedPosts(communityId: community.communityId)
        feedCollection?.$snapshots
            .sink(receiveValue: { [weak self] posts in
                self?.posts = posts
                self?.onChange?(posts.count)
            })
            .store(in: &cancellables)
        
        feedCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.showLoading = status == .loading
            })
            .store(in: &cancellables)
    }
    
    func loadMorePosts() {
        if let feedCollection, feedCollection.hasNext {
            feedCollection.nextPage()
        }
    }
}
