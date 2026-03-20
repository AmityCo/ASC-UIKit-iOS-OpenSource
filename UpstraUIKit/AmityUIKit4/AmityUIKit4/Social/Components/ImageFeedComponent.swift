//
//  ImageFeedComponent.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 31/10/25.
//

import SwiftUI
import SafariServices

struct ImageFeedComponent: View {

    @EnvironmentObject var host: AmitySwiftUIHostWrapper

    @StateObject var viewModel: MediaFeedViewModel
    @StateObject var viewConfig: AmityViewConfigController

    @State private var selectedProductTagMedia: AmityMedia?

    private var gridLayout: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    public init(mediaFeedViewModel: MediaFeedViewModel, pageId: PageId?, componentId: ComponentId?) {
        self._viewModel = StateObject(wrappedValue: mediaFeedViewModel)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: componentId))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            imageFeedView
                .isHidden(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded)
            
            switch viewModel.feedType {
            case .community:
                EmptyCommunityFeedView(.image)
                    .isHidden(!(viewModel.medias.isEmpty && viewModel.loadingStatus == .loaded))
            case .user:
                if let _ = viewModel.blockedFeedState {
                    EmptyUserFeedView(feedType: .image, feedState: .blocked, viewConfig: viewConfig)
                } else if let feedState = viewModel.emptyFeedState {
                    EmptyUserFeedView(feedType: .image, feedState: feedState, viewConfig: viewConfig)
                }
            }
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private var imageFeedView: some View {
        VStack(spacing: 0) {
            if viewModel.emptyFeedState == .private, case .community = viewModel.feedType {
                PrivateCommunityFeedView()
            } else {
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
                                ZStack(alignment: .bottomTrailing) {
                                    getImageView(url)

                                    if !media.produtTags.isEmpty {
                                        AmityProductTagBadgeView(count: media.produtTags.count)
                                            .padding(8)
                                            .onTapGesture {
                                                selectedProductTagMedia = media
                                            }
                                    }
                                }
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
                .onChange(of: viewModel.showMediaViewer) { _ in
                    if viewModel.showMediaViewer {
                        // Get the selected media
                        let selectedMedia = viewModel.medias[viewModel.selectedMediaIndex]
                        // Get the parent post from cache if available
                        
                        var parentPostModel: AmityPostModel?
                        if let parentPost = selectedMedia.parentPostId.flatMap({ viewModel.postsCache[$0] }) {
                            parentPostModel = AmityPostModel(post: parentPost)
                        }
                        
                        let nav = UINavigationController()
                        nav.navigationBar.isHidden = true
                        
                        let view = MediaViewer(
                            medias: [viewModel.medias[viewModel.selectedMediaIndex]],
                            startIndex: viewModel.selectedMediaIndex,
                            viewConfig: viewConfig,
                            closeAction: {
                                nav.dismiss(animated: true) {
                                    viewModel.showMediaViewer = false
                                }
                            },
                            post: parentPostModel
                        )
                            .environmentObject(viewConfig)
                        
                        let controller = AmitySwiftUIHostingController(rootView: view)
                        nav.viewControllers = [controller]
                        nav.modalPresentationStyle = .overFullScreen
                        nav.view.backgroundColor = .clear
                        host.controller?.present(nav, animated: false)
                    }
                }
                
                Color.clear
                    .frame(height: 16)
            }
        }
        .sheet(item: $selectedProductTagMedia) { media in
            let component = AmityProductTagListComponent(
                productTags: media.produtTags,
                renderMode: .image,
                sourceId: media.parentPostId ?? "",
                onProductClick: { productTag in
                    if let url = URL(string: productTag.object.productUrl) {
                        let browserVC = SFSafariViewController(url: url)
                        browserVC.modalPresentationStyle = .pageSheet
                        UIApplication.topViewController()?.present(browserVC, animated: true)
                    }
                })
            component
                .environmentObject(host)
                .halfSheetPresentation()
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

