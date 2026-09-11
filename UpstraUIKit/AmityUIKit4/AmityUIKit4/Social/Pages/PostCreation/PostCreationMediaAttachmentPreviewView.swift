//
//  PostCreationMediaPreviewView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/10/24.
//

import SwiftUI
import AVKit
import AmitySDK

/// Routes the composer's attachments: one renders a full-bleed classified preview, two or more a
/// peeking carousel.
struct PostCreationMediaAttachmentPreviewView: View {

    @ObservedObject private var postComposerViewModel: AmityPostComposerViewModel
    @ObservedObject private var mediaAttachmentViewModel: AmityMediaAttachmentViewModel

    @StateObject private var viewerViewConfig = AmityViewConfigController(pageId: .postComposerPage)
    @State private var page: Page = .first()
    @State private var viewerStart: ViewerStart?
    @State private var availableWidth: CGFloat = UIScreen.main.bounds.width

    init(postComposerViewModel: AmityPostComposerViewModel, viewModel: AmityMediaAttachmentViewModel) {
        self.postComposerViewModel = postComposerViewModel
        self.mediaAttachmentViewModel = viewModel
    }

    var body: some View {
        content
            .environmentObject(postComposerViewModel)
            .environmentObject(mediaAttachmentViewModel)
            // `item:`, not `isPresented:` — the tapped index has to travel *with* the trigger.
            // Split across two `@State`s, a tap that lands while the product-tag sheet is still
            // dismissing built the viewer from the pre-tap index.
            .fullScreenCover(item: $viewerStart) { start in
                MediaViewer(
                    medias: mediaAttachmentViewModel.medias,
                    startIndex: start.index,
                    viewConfig: viewerViewConfig,
                    closeAction: { viewerStart = nil }
                    // No onIndexChanged: the composer returns to the frame originally tapped, not the
                    // last one viewed. The inverse of the feed, deliberately.
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if mediaAttachmentViewModel.medias.isEmpty {
            EmptyView()
        } else if mediaAttachmentViewModel.medias.count == 1 {
            singlePreview
        } else {
            SelectedMediaCarouselView(
                mediaViewModel: mediaAttachmentViewModel,
                page: $page,
                onFrameTap: openViewer(at:)
            )
            .padding(.horizontal, 16)
        }
    }

    /// Full-bleed and classified, not a forced square — an inset always-square tile would not preview
    /// what actually publishes.
    @ViewBuilder
    private var singlePreview: some View {
        let media = mediaAttachmentViewModel.medias[0]
        let ratio = MediaDimensionResolver.pixelSize(of: media)
            .map { MediaRatioClassifier.classify(size: $0) } ?? .square

        SelectedMediaFrameView(
            media: media,
            index: 0,
            total: 1,
            removeAction: { mediaAttachmentViewModel.medias.removeAll() },
            onTap: { openViewer(at: 0) }
        )
        .readSize { availableWidth = $0.width }
        .frame(height: ratio.height(forWidth: availableWidth))
        .padding(.vertical, 12)
    }

    private func openViewer(at index: Int) {
        viewerStart = ViewerStart(index: index)
    }
}

/// The frame the full-screen viewer opens on. `Identifiable` so the index is part of the
/// presentation trigger rather than a second piece of state read at presentation time.
private struct ViewerStart: Identifiable, Equatable {
    let index: Int
    var id: Int { index }
}
