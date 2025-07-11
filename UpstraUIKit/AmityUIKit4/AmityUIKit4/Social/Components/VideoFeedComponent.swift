//
//  VideoFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AmitySDK

/// Shared View for VideoFeedComponent in UserProfile & CommunityProfilePage
struct VideoFeedComponent: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    @State private var currentTab: VideoFeedTab = .videos
    @StateObject private var viewModel: MediaFeedViewModel
    
    private var gridLayout: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    public init(mediaFeedViewModel: MediaFeedViewModel) {
        self._viewModel = StateObject(wrappedValue: mediaFeedViewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VideoFeedTabButton(title: "Videos", selected: currentTab == .videos) {
                    currentTab = .videos
                }
                
                VideoFeedTabButton(title: "Clips", selected: currentTab == .clips) {
                    currentTab = .clips
                }
                
                Spacer()
                
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            
            switch currentTab {
            case .videos:
                ZStack(alignment: .top) {
                    videoFeedView
                        .isHidden(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded)
                    
                    switch viewModel.feedType {
                    case .community:
                        if viewModel.emptyFeedState == .private {
                            PrivateCommunityFeedView()
                        } else {
                            EmptyCommunityFeedView(.video)
                                .isHidden(!(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded))
                        }
                    case .user:
                        if let _ = viewModel.blockedFeedState {
                            EmptyUserFeedView(feedType: .video, feedState: .blocked, viewConfig: viewConfig)
                        } else if let feedState = viewModel.emptyFeedState {
                            EmptyUserFeedView(feedType: .video, feedState: feedState, viewConfig: viewConfig)
                        }
                    }
                }
            case .clips:
                ZStack(alignment: .top) {
                    clipsFeedView
                        .isHidden(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded)
                    
                    switch viewModel.feedType {
                    case .community:
                        EmptyCommunityFeedView(.clip)
                            .isHidden(!(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded))
                    case .user:
                        if let _ = viewModel.blockedFeedState {
                            EmptyUserFeedView(feedType: .clip, feedState: .blocked, viewConfig: viewConfig)
                        } else if let feedState = viewModel.emptyFeedState {
                            EmptyUserFeedView(feedType: .clip, feedState: feedState, viewConfig: viewConfig)
                        }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .onChange(of: currentTab) { tab in
            viewModel.loadMediaFeed(feedTab: tab)
        }
        .onAppear {
            viewModel.loadMediaFeed(feedTab: currentTab)
        }
    }
    
    @ViewBuilder
    private var videoFeedView: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 16)
            
            LazyVGrid(columns: gridLayout, spacing: 8) {
                if viewModel.loadingStatus == .loading && viewModel.medias.isEmpty {
                    ForEach(0..<10, id: \.self) { _ in
                        videoSkeletonImageView
                    }
                } else {
                    ForEach(Array(viewModel.medias.enumerated()), id: \.element.id) { index, media in
                        if let url = media.getImageURL(),
                           let attributes = media.video?.attributes,
                           let meta = attributes["metadata"] as? [String: Any],
                           let videoMeta = meta["video"] as? [String: Any],
                           let duration = videoMeta["duration"] as? TimeInterval {
                            getVideoView(url, duration)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .onTapGesture {
                                    viewModel.videoURL = URL(string: media.video?.getVideo(resolution: .original) ?? "")
                                    viewModel.showMediaViewer.toggle()
                                }
                                .onAppear {
                                    if index == viewModel.medias.count - 1 {
                                        viewModel.loadMore()
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .fullScreenCover(isPresented: $viewModel.showMediaViewer) {
                if let videoURL = viewModel.videoURL {
                    AVPlayerView(url: videoURL)
                        .ignoresSafeArea(.all)
                }
            }
            
            Color.clear
                .frame(height: 16)
        }
    }
    
    @ViewBuilder
    private var clipsFeedView: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 16)
            
            LazyVGrid(columns: gridLayout, spacing: 8) {
                if viewModel.loadingStatus == .loading && viewModel.medias.isEmpty {
                    ForEach(0..<10, id: \.self) { _ in
                        clipSkeletonImageView
                    }
                } else {
                    ForEach(Array(viewModel.medias.enumerated()), id: \.element.id) { index, media in
                        
                        // Get the parent post
                        let clipContent = viewModel.getClipContent(at: index)
                        let displayMode = clipContent?.displayMode.contentMode ?? .fill
                        
                        if let url = media.getImageURL(),
                           let attributes = media.clip?.attributes,
                           let meta = attributes["metadata"] as? [String: Any],
                           let videoMeta = meta["video"] as? [String: Any],
                           let duration = videoMeta["duration"] as? TimeInterval {
                            getClipView(url, duration, displayMode)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .onTapGesture {
                                    
                                    let targetId: String
                                    let targetType: AmityPostTargetType
                                    
                                    switch viewModel.feedType {
                                    case .community(let communityId):
                                        targetId = communityId
                                        targetType = .community
                                    case .user(let userId):
                                        targetId = userId
                                        targetType = .user
                                    }
                                    
                                    // Open clip feed
                                    if let postCollection = viewModel.postCollection {
                                        let provider = TargetFeedClipService(targetId: targetId, targetType: targetType, postCollection: postCollection, startIndex: index, postsCache: viewModel.postsCache)
                                        
                                        let feedView = ClipFeedView(clipProvider: provider).updateTheme(with: viewConfig)
                                        let hostingView = AmitySwiftUIHostingController(rootView: feedView)
                                        
                                        self.host.controller?.navigationController?.pushViewController(hostingView, animated: true)
                                    }
                                }
                                .onAppear {
                                    if index == viewModel.medias.count - 1 {
                                        viewModel.loadMore()
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .fullScreenCover(isPresented: $viewModel.showMediaViewer) {
                if let videoURL = viewModel.videoURL {
                    AVPlayerView(url: videoURL)
                        .ignoresSafeArea(.all)
                }
            }
            
            Color.clear
                .frame(height: 16)
        }
    }
    
    @ViewBuilder
    private func getClipView(_ url: URL, _ duration: TimeInterval,_ contentMode: ContentMode) -> some View {
        let emptyView = Color(viewConfig.theme.baseColorShade4)
        let clipViewHeight = ((UIScreen.main.bounds.width - 32 - 8) / 2) * 1.66
        
        ZStack(alignment: .bottomLeading) {
            Color.black
                .overlay(
                    URLImage(url, empty: {
                        emptyView
                    },inProgress: {_ in
                        emptyView
                    },failure: {_, _ in
                        emptyView
                    },content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    })
                    .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                )
                .compositingGroup()
                .clipped()
                .contentShape(Rectangle())
                .frame(height: clipViewHeight)
            
            Text("\(duration.formattedDurationString ?? "0:00")")
                .applyTextStyle(.caption(.white))
                .padding(.all, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding([.leading, .bottom], 8)
        }
        
    }
    
    @ViewBuilder
    private func getVideoView(_ url: URL, _ duration: TimeInterval) -> some View {
        let emptyView = Color(viewConfig.theme.baseColorShade4)
        ZStack(alignment: .bottomLeading) {
            Color.clear
                .overlay(
                    URLImage(url, empty: {
                        emptyView
                    },inProgress: {_ in
                        emptyView
                    },failure: {_, _ in
                        emptyView
                    },content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    })
                    .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                )
                .compositingGroup()
                .clipped()
                .contentShape(Rectangle())
            
            Text("\(duration.formattedDurationString ?? "0:00")")
                .applyTextStyle(.caption(.white))
                .padding(.all, 4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding([.leading, .bottom], 8)
        }
        
    }
    
    @ViewBuilder
    private var videoSkeletonImageView: some View {
        Color(viewConfig.theme.baseColorShade3)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
            .shimmering(gradient: shimmerGradient)
    }
    
    @ViewBuilder
    private var clipSkeletonImageView: some View {
        let clipViewHeight = ((UIScreen.main.bounds.width - 32 - 8) / 2) * 1.66
        
        Color(viewConfig.theme.baseColorShade3)
            .frame(maxWidth: .infinity)
            .frame(height: clipViewHeight)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
            .shimmering(gradient: shimmerGradient)
    }
}
