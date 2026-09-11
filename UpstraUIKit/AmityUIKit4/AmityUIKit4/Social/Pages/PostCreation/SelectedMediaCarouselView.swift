//
//  SelectedMediaCarouselView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/10/26.
//

import SwiftUI
import AmitySDK

/// The composer's media preview: a snapping horizontal carousel that peeks the next frame.
///
/// Unlike the published carousel this renders no pagination indicator and no counter — the peek is the
/// only affordance that more frames exist. `SwiftUIPager` rather than `TabView` for exactly that peek,
/// which `TabView` cannot do.
struct SelectedMediaCarouselView: View {

    @ObservedObject var mediaViewModel: AmityMediaAttachmentViewModel
    @Binding var page: Page
    let onFrameTap: (Int) -> Void

    private enum Frame {
        static let width: CGFloat = 320
        static let gap: CGFloat = 8
    }

    private var frameHeight: CGFloat {
        mediaViewModel.lockedRatio.height(forWidth: Frame.width)
    }

    var body: some View {
        // Paged over indices: `Pager` requires `Element: Equatable`, which a tuple cannot satisfy.
        Pager(page: page, data: Array(mediaViewModel.medias.indices), id: \.self) { index in
            SelectedMediaFrameView(
                media: mediaViewModel.medias[index],
                index: index,
                total: mediaViewModel.medias.count,
                removeAction: { remove(at: index) },
                onTap: { onFrameTap(index) }
            )
            .frame(width: Frame.width, height: frameHeight)
        }
        // 320 wide inside a 375 container leaves the next frame peeking by 31.
        .preferredItemSize(CGSize(width: Frame.width, height: frameHeight), alignment: .start(0))
        .itemSpacing(Frame.gap)
        .alignment(.start(0))
        .frame(height: frameHeight)
        .padding(.vertical, 12)
    }

    private func remove(at index: Int) {
        guard mediaViewModel.medias.indices.contains(index) else { return }
        mediaViewModel.medias.remove(at: index)

        let lastIndex = max(mediaViewModel.medias.count - 1, 0)
        if page.index > lastIndex {
            page.update(.new(index: lastIndex))
        }
    }
}
