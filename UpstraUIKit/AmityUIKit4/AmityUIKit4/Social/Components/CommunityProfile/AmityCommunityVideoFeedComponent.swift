//
//  AmityCommunityVideoFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/11/24.
//

import SwiftUI

public struct AmityCommunityVideoFeedComponent: AmityComponentView {
    public var pageId: PageId?
    @StateObject private var viewModel: MediaFeedViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public var id: ComponentId {
        .commentTrayComponent
    }
    
    private var gridLayout: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    public init(communityId: String, communityProfileViewModel: CommunityProfileViewModel? = nil, pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityImageFeed))
        
        if let communityProfileViewModel {
            self._viewModel = StateObject(wrappedValue: communityProfileViewModel.videoFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .video))
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            videoFeedView
                .isHidden(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded)
            
            EmptyCommunityFeedView(.video)
                .isHidden(!(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded))
        }
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private var videoFeedView: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 16)
            
            LazyVGrid(columns: gridLayout, spacing: 8) {
                if viewModel.loadingStatus == .loading && viewModel.medias.isEmpty {
                    ForEach(0..<10, id: \.self) { _ in
                        skeletonImageView
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
                                    if let urlStr = media.video?.getVideo(resolution: .original) {
                                        viewModel.videoURL = URL(string: urlStr)
                                    } else {
                                        viewModel.videoURL = URL(string: media.video?.fileURL ?? "")
                                    }
                                     
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
                    AVPlayerView(url: videoURL, autoPlay: false)
                        .ignoresSafeArea(.all)
                }
            }
            
            Color.clear
                .frame(height: 16)
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
                    },
                    inProgress: {_ in
                        emptyView
                    },
                    failure: {_, _ in
                        emptyView
                    },
                    content: { image in
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
    private var skeletonImageView: some View {
        Color(viewConfig.theme.baseColorShade3)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
            .shimmering(gradient: shimmerGradient)
    }
}
