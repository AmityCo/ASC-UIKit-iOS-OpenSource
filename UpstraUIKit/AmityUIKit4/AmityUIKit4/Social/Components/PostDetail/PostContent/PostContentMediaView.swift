//
//  PostContentMediaView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/13/24.
//

import Foundation
import SwiftUI
import AmitySDK

/// Routes a post's attachments: one renders a single frame, two or more a swipeable carousel. Both are
/// full-bleed and classified — only the chrome differs.
struct PostContentMediaView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewModel: PostContentMediaViewModel = PostContentMediaViewModel()
    @ObservedObject var viewConfig: AmityViewConfigController
    let post: AmityPostModel
    var pageId: PageId? = nil

    @State private var currentIndex: Int
    @State private var availableWidth: CGFloat = UIScreen.main.bounds.width
    @ObservedObject private var positionStore = PostMediaCarouselPositionStore.shared

    init(post: AmityPostModel, viewConfig: AmityViewConfigController, pageId: PageId? = nil) {
        self.post = post
        self.viewConfig = viewConfig
        self.pageId = pageId
        self._currentIndex = State(
            initialValue: PostMediaCarouselPositionStore.shared.index(
                for: post.postId,
                mediaCount: post.medias.count
            )
        )
    }

    var body: some View {
        if post.medias.isEmpty {
            EmptyView()
        } else {
            content
                .onChange(of: currentIndex) { index in
                    PostMediaCarouselPositionStore.shared.setIndex(index, for: post.postId)
                }
                /// Drives `TabView(selection:)` back to the first frame on a reload. Rows that are
                /// off screen are rebuilt later and read the cleared store instead.
                .onChange(of: positionStore.resetGeneration) { _ in
                    currentIndex = 0
                }
                .fullScreenCover(isPresented: $viewModel.showMediaViewer) {
                    MediaViewer(
                        medias: post.medias,
                        startIndex: viewModel.selectedMediaIndex,
                        viewConfig: viewConfig,
                        closeAction: { viewModel.showMediaViewer.toggle() },
                        showEditAction: post.isOwner,
                        post: post,
                        showViewParentPost: false,
                        pageId: pageId,
                        alwaysShowsCounter: true,
                        // Tracked live, so the carousel is already on the right frame when the
                        // fade-out reveals it. The composer deliberately does not wire this.
                        onIndexChanged: { viewedIndex in
                            currentIndex = viewedIndex
                        }
                    )
                }
                .sheet(isPresented: $viewModel.showProductTagSheet) {
                    productTagListSheet
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if post.medias.count == 1 {
            singleFrame
        } else {
            PostMediaCarouselView(
                viewConfig: viewConfig,
                medias: post.medias,
                currentIndex: $currentIndex,
                onFrameTap: { index in
                    withoutAnimation {
                        viewModel.selectedMediaIndex = index
                        viewModel.showMediaViewer.toggle()
                    }
                },
                onProductTagTap: { media in
                    viewModel.selectedProductTagMedia = media
                    viewModel.showProductTagSheet = true
                }
            )
            // The owning component pads 16; a media frame is full post width.
            .padding(.horizontal, -16)
        }
    }

    /// Drawn exactly like a carousel frame; only the chrome differs. Attachment count changes how many
    /// frames there are, never how one is drawn.
    @ViewBuilder
    private var singleFrame: some View {
        let ratio = MediaDimensionResolver.lockedRatio(for: post.medias)

        PostMediaFrameView(
            viewConfig: viewConfig,
            media: post.medias[0],
            index: 0,
            total: 1,
            onProductTagTap: { media in
                viewModel.selectedProductTagMedia = media
                viewModel.showProductTagSheet = true
            }
        )
        .readSize { availableWidth = $0.width }
        .frame(height: ratio.height(forWidth: availableWidth))
        .onTapGesture {
            withoutAnimation {
                viewModel.selectedMediaIndex = 0
                viewModel.showMediaViewer.toggle()
            }
        }
        // The owning component pads 16; a media frame is full post width.
        .padding(.horizontal, -16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var productTagListSheet: some View {
        if let media = viewModel.selectedProductTagMedia {
            let renderMode: ProductTagListRenderMode = media.type == .video ? .video : .image
            let component = AmityProductTagListComponent(
                pageId: pageId,
                productTags: media.produtTags,
                renderMode: renderMode,
                sourceId: post.postId)
            component
                .environmentObject(host)
                .halfSheetPresentation()
        }
    }
}

/// Remembers which carousel frame each post is showing.
///
/// A feed row's `@State` is destroyed when the post scrolls out of the viewport and rebuilt from
/// scratch on re-entry, which reset every carousel to frame 1. Position therefore cannot live in the
/// view; it lives here, keyed by post.
final class PostMediaCarouselPositionStore: ObservableObject {
    static let shared = PostMediaCarouselPositionStore()

    /// Bumped by `reset()`. Rows already on screen watch this and return to frame 1.
    ///
    /// Clearing `indices` alone is not enough: a reloaded feed keeps each row's `ForEach` identity
    /// (`PaginatedItem.id` is the post id), so SwiftUI preserves the row's `@State` and never re-runs
    /// the `init` that reads this store. A reload therefore has to push, not just forget.
    @Published private(set) var resetGeneration: Int = 0

    private var indices: [String: Int] = [:]

    private init() {}

    /// Clamped on read — a post edited down to fewer attachments must not select a frame that is gone.
    func index(for postId: String, mediaCount: Int) -> Int {
        guard mediaCount > 0, let stored = indices[postId] else { return 0 }
        return min(max(stored, 0), mediaCount - 1)
    }

    func setIndex(_ index: Int, for postId: String) {
        indices[postId] = index
    }

    /// Scroll-recycling is the only thing position survives. A feed reload discards it.
    func reset() {
        indices.removeAll()
        resetGeneration += 1
    }
}

class PostContentMediaViewModel: ObservableObject {
    @Published var showMediaViewer: Bool = false
    @Published var selectedMediaIndex: Int = 0
    @Published var showProductTagSheet: Bool = false
    @Published var selectedProductTagMedia: AmityMedia?
}
