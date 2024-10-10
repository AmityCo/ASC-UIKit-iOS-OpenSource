//
//  AmityCommunityImageFeedComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import SwiftUI

public struct AmityCommunityImageFeedComponent: AmityComponentView {
    public var id: ComponentId {
        .communityImageFeed
    }
    
    public var pageId: PageId?
    @StateObject private var viewModel: MediaFeedViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
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
            self._viewModel = StateObject(wrappedValue: communityProfileViewModel.imageFeedViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: MediaFeedViewModel(feedType: .community(communityId: communityId), postType: .image))
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            imageFeedView
                .isHidden(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded)
            
            EmptyCommunityFeedView(.image)
                .isHidden(!(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded))
        }
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private var imageFeedView: some View {
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
                        if let url = media.getImageURL() {
                            getImageView(url)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .onTapGesture {
                                    viewModel.selectedMediaIndex = index
                                    withoutAnimation {
                                        viewModel.showMediaViewer.toggle()
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
                MediaViewer(medias: [viewModel.medias[viewModel.selectedMediaIndex]], startIndex: 0, closeAction: { viewModel.showMediaViewer.toggle() })
            }
            
            Color.clear
                .frame(height: 16)
        }
    }
    
    @ViewBuilder
    private func getImageView(_ url: URL) -> some View {
        let emptyView = Color(viewConfig.theme.baseColorShade4)
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
