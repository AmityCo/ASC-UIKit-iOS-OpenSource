//
//  AmityForYouFeedComponent.swift
//  AmityUIKit4
//
//  Created by Claude on 4/6/26.
//

import SwiftUI
import Combine
import AmitySDK

public struct AmityForYouFeedComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var pageId: PageId?

    public var id: ComponentId {
        .forYouFeedComponent
    }

    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = ForYouFeedViewModel()

    private let onFeatureDisabled: (() -> Void)?
    private let onSwitchToFollowingRequested: (() -> Void)?

    public init(pageId: PageId? = nil, onFeatureDisabled: (() -> Void)? = nil, onSwitchToFollowingRequested: (() -> Void)? = nil) {
        self.pageId = pageId
        self.onFeatureDisabled = onFeatureDisabled
        self.onSwitchToFollowingRequested = onSwitchToFollowingRequested
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .forYouFeedComponent))

        UITableView.appearance().separatorStyle = .none
    }

    public var body: some View {
        getContentView()
            .updateTheme(with: viewConfig)
            .onAppear {
                viewModel.onFeatureDisabled = onFeatureDisabled
            }
    }

    @ViewBuilder
    func getContentView() -> some View {
        if #available(iOS 15.0, *) {
            getPostListView()
                .refreshable {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
        } else {
            getPostListView()
        }
    }

    @ViewBuilder
    func getPostListView() -> some View {
        List {
            storyTabRow

            if !viewModel.didLoadFirstPage && viewModel.postItems.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(spacing: 0) {
                        PostContentSkeletonView()
                    }
                    .listRowInsets(EdgeInsets())
                    .modifier(HiddenListSeparator())
                }
            } else if viewModel.postItems.isEmpty {
                caughtUpCell
            } else {
                ForEach(Array(viewModel.postItems.enumerated()), id: \.element.id) { index, item in
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
                                AmityPostContentComponent(post: post.object, category: post.isPinned ? .global : .general, onTapAction: { tapContext in
                                    handleTap(on: post, showPollResult: tapContext?.showPollResults ?? false)
                                }, pageId: pageId)
                                .contentShape(Rectangle())
                                .background(GeometryReader { geometry in
                                    Color.clear
                                        .onChange(of: geometry.frame(in: .global)) { frame in
                                            guard !post.isPinned else { return }
                                            handleVisibility(frame: frame, post: post)
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
                        if index == viewModel.postItems.count - 1 {
                            viewModel.loadMore()
                        }
                    }
                }

                if viewModel.isFeedExhausted {
                    caughtUpCell
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var storyTabRow: some View {
        if (!viewModel.storyTargets.isEmpty || !viewModel.roomPosts.isEmpty) {
            VStack(spacing: 0) {
                AmityStoryTabComponent(type: .globalFeed, pageId: pageId)
                    .frame(height: 118)

                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 8)
            }
            .listRowInsets(EdgeInsets())
            .modifier(HiddenListSeparator())
        } else if viewModel.isStoryTabLoading {
            VStack(spacing: 0) {
                SkeletonStoryTabComponent(radius: 64)
                    .frame(height: 118)
                    .padding(.leading, 18)
                    .background(Color(viewConfig.theme.backgroundColor))

                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 8)
            }
            .listRowInsets(EdgeInsets())
            .modifier(HiddenListSeparator())
        }
    }

    @ViewBuilder
    private var caughtUpCell: some View {
        AmityFeedCaughtUpComponent(pageId: pageId) {
            onSwitchToFollowingRequested?()
        }
        .environmentObject(host)
        .listRowInsets(EdgeInsets())
        .modifier(HiddenListSeparator())
    }

    private func handleTap(on post: AmityPostModel, showPollResult: Bool) {
        if post.dataTypeInternal == .clip {
            if let media = post.medias.first, let mediaURL = URL(string: media.clip?.fileURL ?? "") {
                let clipPost = ClipPost(id: post.postId, url: mediaURL, model: post)
                let provider = GlobalFeedClipService(clipPost: clipPost)
                let feedPage = AmityClipFeedPage(provider: provider)
                let hostingView = AmitySwiftUIHostingController(rootView: feedPage)
                host.controller?.navigationController?.pushViewController(hostingView, animated: true)
            }
            return
        }

        let postComponentContext = AmityPostContentComponent.Context(shouldShowPollResults: showPollResult, category: .general)
        let vc = AmitySwiftUIHostingController(rootView: AmityPostDetailPage(post: post.object, context: postComponentContext))
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }

    private func handleVisibility(frame: CGRect, post: AmityPostModel) {
        guard frame.height > 0 else { return }
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(screenHeight, frame.maxY) - max(0, frame.minY)
        let visiblePercentage = max(0, (visibleHeight / frame.height) * 100)
        viewModel.updateVisibility(post: post, visiblePercentage: visiblePercentage)
    }
}
