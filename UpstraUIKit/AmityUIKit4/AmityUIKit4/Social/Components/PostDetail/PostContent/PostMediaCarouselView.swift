//
//  PostMediaCarouselView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/26.
//

import SwiftUI
import AmitySDK

/// The published media carousel. Every frame shares the ratio classified from the first attachment,
/// so the height never jumps between slides.
///
/// `TabView`, not `SwiftUIPager`: this sits inside the feed's scroll, and SwiftUIPager's global-space
/// `DragGesture` fights it — no gesture priority resolves that. `TabView` is `UIPageViewController`-
/// backed, so paging coexists natively. The composer keeps SwiftUIPager because it needs the
/// next-frame peek, which `TabView` cannot do.
struct PostMediaCarouselView: View {

    @ObservedObject var viewConfig: AmityViewConfigController

    let medias: [AmityMedia]
    /// The visible frame. Owned by the caller so the full-screen viewer can track it and write back.
    @Binding var currentIndex: Int

    let onFrameTap: (Int) -> Void
    let onProductTagTap: (AmityMedia) -> Void

    /// The width actually offered by the container, which is not the screen's on iPad, in split view,
    /// or inside any inset parent. Seeded with the screen width for the first layout pass only.
    @State private var availableWidth: CGFloat = UIScreen.main.bounds.width

    private var lockedRatio: MediaAspectRatio {
        MediaDimensionResolver.lockedRatio(for: medias)
    }

    private var showsChrome: Bool {
        medias.count > 1
    }

    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $currentIndex) {
                ForEach(medias.indices, id: \.self) { index in
                    PostMediaFrameView(
                        viewConfig: viewConfig,
                        media: medias[index],
                        index: index,
                        total: medias.count,
                        onProductTagTap: onProductTagTap
                    )
                    .onTapGesture { onFrameTap(index) }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .overlay(
                counterPill
                    .padding(8)
                    .isHidden(!showsChrome, remove: true),
                alignment: .topTrailing
            )
            .readSize { availableWidth = $0.width }
            .frame(height: lockedRatio.height(forWidth: availableWidth))

            if showsChrome {
                PostMediaPaginationIndicatorView(
                    viewConfig: viewConfig,
                    current: currentIndex,
                    total: medias.count
                )
            }
        }
        .padding(.vertical, 8)
    }

    /// `n/total`, no spaces — unlike the viewer's spaced `n / total`.
    private var counterPill: some View {
        Text("\(currentIndex + 1)/\(medias.count)")
            .applyTextStyle(.body(.white))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.black.opacity(0.5))
            )
            .accessibilityHidden(true)
    }
}
