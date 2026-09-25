//
//  DiscoveryWidgetCardMediaView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import SwiftUI

/// Media block — the **remainder** of the card's fixed 480 once the header, engagement bar and the
/// caption have taken theirs, with `8` top and bottom padding either way. A one-line caption leaves
/// a `356` slot, no caption leaves `392`, and a caption long enough to truncate leaves the `296`
/// floor. Full-bleed horizontally, with no inset and no radius of its own; the card's clip provides
/// the rounding at the edges it touches.
///
/// **Frame 1 only.** A multi-attachment post shows its first attachment: the block is not swipeable,
/// carries no pagination dots, and never plays. What it does carry is two *indicators* that more
/// exists — the `n/total` counter and the trailing chevron — and, on a video or clip, a play glyph.
/// None of the three is a control: nothing advances a frame and media never auto-plays or plays in
/// place.
struct DiscoveryWidgetCardMediaView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let post: AmityPostModel
    let showsPlayIndicator: Bool

    private var attachmentCount: Int {
        post.medias.count
    }

    var body: some View {
        // The image is an **overlay on a greedy Color**, not a stack sibling, and the play indicator
        // is an overlay on the finished media frame. Both matter: `scaledToFill` reports a size
        // larger than the frame in one axis, so as a sibling it drives the stack's size and anything
        // centred alongside it is centred on the *image*, not on the media block. Overlays cannot
        // affect their parent's size, so the indicator's centre is the block's centre by
        // construction. Same shape `PostMediaFrameView` uses in the feed.
        thumbnail
            .frame(maxWidth: .infinity)
            .frame(minHeight: DiscoveryWidgetMetrics.mediaContentFloor, maxHeight: .infinity)
            .clipped()
            .overlay(playIndicator)
            .overlay(counter, alignment: .topTrailing)
            .overlay(nextIndicator, alignment: .trailing)
            .padding(.vertical, DiscoveryWidgetMetrics.mediaVerticalPadding)
            .accessibilityHidden(true)
    }

    /// `cover` — cropped to fill the slot, never letterboxed. The `Color` underneath is what defines
    /// the frame; the image only paints into it.
    private var thumbnail: some View {
        Color(viewConfig.theme.baseColorShade4)
            .overlay(imageOrPlaceholder)
    }

    @ViewBuilder
    private var imageOrPlaceholder: some View {
        if let url = post.medias.first?.getImageURL() {
            URLImage(
                url,
                empty: { Color(viewConfig.theme.baseColorShade4) },
                inProgress: { _ in Color(viewConfig.theme.baseColorShade4) },
                failure: { _, _ in brokenPlaceholder },
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }
            )
            .environment(\.urlImageOptions, URLImageOptions.amityOptions)
        } else {
            brokenPlaceholder
        }
    }

    @ViewBuilder
    private var playIndicator: some View {
        if showsPlayIndicator {
            Image(AmityIcon.videoControlIcon.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: DiscoveryWidgetMetrics.playIndicatorSize,
                       height: DiscoveryWidgetMetrics.playIndicatorSize)
        }
    }

    @ViewBuilder
    private var counter: some View {
        if attachmentCount > 1 {
            counterPill
                .padding(DiscoveryWidgetMetrics.mediaOverlayInset)
        }
    }

    /// Signals that the post carries more attachments. Gated on the same `> 1` as the counter, and
    /// decorative for the same reason as the play glyph — nothing here advances a frame.
    @ViewBuilder
    private var nextIndicator: some View {
        if attachmentCount > 1 {
            Circle()
                .fill(Color(viewConfig.theme.transparentBlackShade3Color))
                .frame(width: DiscoveryWidgetMetrics.mediaNextIndicatorSize,
                       height: DiscoveryWidgetMetrics.mediaNextIndicatorSize)
                .overlay(
                    Image(AmityIcon.arrowIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: DiscoveryWidgetMetrics.mediaNextIndicatorGlyphSize,
                               height: DiscoveryWidgetMetrics.mediaNextIndicatorGlyphSize)
                )
                .padding(.trailing, DiscoveryWidgetMetrics.mediaOverlayInset)
        }
    }

    /// A failed load keeps the 296 block and its placeholder. The card does not collapse, and it
    /// does not make the widget hide — hiding is a pool-level decision, never a per-card one.
    private var brokenPlaceholder: some View {
        Color(viewConfig.theme.baseColorShade4)
            .overlay(
                Image(AmityIcon.pollImageNotAvailableIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            )
    }

    /// `n/total`, no spaces. Bound to `white_color`, **not** `base_inverse_color` — the latter is
    /// black in light mode, which would paint the label black on a 50%-black scrim.
    private var counterPill: some View {
        Text("1/\(attachmentCount)")
            .applyTextStyle(.captionBold(.white))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(viewConfig.theme.transparentBlackShade3Color)))
    }
}
