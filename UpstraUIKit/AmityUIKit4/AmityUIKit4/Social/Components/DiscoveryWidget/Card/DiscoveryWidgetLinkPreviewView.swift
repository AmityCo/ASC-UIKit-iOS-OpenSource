//
//  DiscoveryWidgetLinkPreviewView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Link preview, rendered **below** the text when the post body contains a URL.
///
/// The same hero card the feed draws (`Post / Link Preview Card/Default`, Figma `1072:129187`):
/// a `171.5` media block over an `84` information block. A widget-local tree rather than the feed's
/// `PreviewLinkView` for one reason the feed version cannot satisfy — it opens the external URL on
/// tap, where here the preview is inside the card's single tap target and never opens anything.
/// Metadata resolution is shared — same `PreviewLinkViewModel`.
struct DiscoveryWidgetLinkPreviewView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: PreviewLinkViewModel

    init(post: AmityPostModel) {
        self._viewModel = StateObject(wrappedValue: PreviewLinkViewModel(post: post))
    }

    var body: some View {
        if viewModel.previewLinkData.url != nil {
            VStack(alignment: .leading, spacing: 0) {
                media

                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)

                information
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DiscoveryWidgetMetrics.cardCornerRadius)
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
            // Inside the card's tap target — never independently tappable, never focusable.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// Drawn whether or not the link resolves an image. The slot is a fixed part of the card's 480
    /// budget, so an unresolved link falls back to the placeholder icon rather than collapsing the
    /// block and leaving the information stretched over the remainder — which is what the feed does,
    /// since nothing there is holding a fixed height.
    ///
    /// A resolved image fills and centre-crops the block, identical to the feed. The fallback icon
    /// does **not**: `AsyncImage`'s `placeholder:` argument scales it `.fill`, which at `343 × 171.5`
    /// blows a `36 × 27` glyph up nine-fold. `placeholderView:` renders it at its own size instead.
    @ViewBuilder
    private var media: some View {
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(height: DiscoveryWidgetMetrics.linkPreviewMediaHeight)
            .overlay(
                AsyncImage(placeholderView: {
                    Image(AmityIcon.previewLinkDefaultIcon.imageResource)
                }, url: viewModel.previewLinkData.imageUrl)
                    .isHidden(!viewModel.previewLinkData.loaded)
            )
            .clipped()
            .shimmering(active: !viewModel.previewLinkData.loaded)
    }

    @ViewBuilder
    private var information: some View {
        VStack(alignment: .leading, spacing: DiscoveryWidgetMetrics.linkPreviewTitleToUrlGap) {
            let defaultHost = viewModel.previewLinkData.defaultHost

            Text(viewModel.previewLinkData.title ?? defaultHost)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(2)

            Text(viewModel.previewLinkData.domain ?? defaultHost)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(DiscoveryWidgetMetrics.linkPreviewInfoPadding)
    }
}
