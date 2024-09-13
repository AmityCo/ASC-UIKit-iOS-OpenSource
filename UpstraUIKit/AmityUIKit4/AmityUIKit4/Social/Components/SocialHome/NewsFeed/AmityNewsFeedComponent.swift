//
//  AmityNewsFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/3/24.
//

import SwiftUI
import Combine
import AmitySDK

public struct AmityNewsFeedComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .newsFeedComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var postFeedViewModel = PostFeedViewModel(feedType: .globalFeed)
    @StateObject private var viewModel = AmityNewsFeedComponentViewModel()
    @State private var hideStoryTab: Bool = true
    @State private var pullToRefreshShowing: Bool = false
    
    public init(pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .newsFeedComponent))
        
        UITableView.appearance().separatorStyle = .none
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            getContentView()
                .opacity(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded ? 0 : 1)
            
            AmityEmptyNewsFeedComponent(pageId: pageId)
                .opacity(postFeedViewModel.postItems.isEmpty && postFeedViewModel.feedLoadingStatus == .loaded ? 1 : 0)
        }
        .updateTheme(with: viewConfig)
        .onReceive(viewModel.$shouldHideStoryComponent, perform: { value in
            hideStoryTab = value
        })
    }
    
    @ViewBuilder
    func getContentView() -> some View {
        if #available(iOS 15.0, *) {
            getPostListView()
            .refreshable {
                // just to show/hide story view
                viewModel.loadStoryTargets()
                // refresh global feed
                // swiftUI cannot update properly if we use nested Observable Object
                // that is the reason why postFeedViewModel is not moved into viewModel
                postFeedViewModel.loadFeed(feedType: .globalFeed)
            }
        } else {
            getPostListView()
        }
    }
    
    @ViewBuilder
    func getPostListView() -> some View {
        List {
            if !hideStoryTab {
                VStack(spacing: 0) {
                    AmityStoryTabComponent(type: .globalFeed, pageId: pageId)
                        .frame(height: 118)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
            }
            
            if postFeedViewModel.postItems.isEmpty {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 0) {
                        PostContentSkeletonView()
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
            } else {
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
                                AmityPostContentComponent(post: post.object, onTapAction: {
                                    let context = AmityNewsFeedComponentBehavior.Context(component: self, post: post)
                                    AmityUIKitManagerInternal.shared.behavior.newsFeedComponentBehavior?.goToPostDetailPage(context: context)
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

class AmityNewsFeedComponentViewModel: ObservableObject {
    @Published var shouldHideStoryComponent: Bool = true
    private var storyTargetCollection: AmityCollection<AmityStoryTarget>?
    private var cancellable: AnyCancellable?
    private let storyManager = StoryManager()
    
    init() {
        loadStoryTargets()
    }
    
    func loadStoryTargets() {
        storyTargetCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
        cancellable = storyTargetCollection?.$snapshots
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .sink { [weak self] targets in
                self?.shouldHideStoryComponent = targets.count == 0
            }
    }
}
