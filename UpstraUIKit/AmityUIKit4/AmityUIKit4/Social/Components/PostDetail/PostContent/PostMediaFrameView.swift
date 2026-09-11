//
//  PostMediaFrameView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/26.
//

import SwiftUI
import AmitySDK

/// A single frame of the published media carousel, drawn at the carousel's locked ratio.
struct PostMediaFrameView: View {

    @ObservedObject var viewConfig: AmityViewConfigController

    let media: AmityMedia
    let index: Int
    let total: Int
    let onProductTagTap: (AmityMedia) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mediaContent

            if !media.produtTags.isEmpty {
                AmityProductTagBadgeView(count: media.produtTags.count, icon: .productTagFilledIcon)
                    .padding(12)
                    .onTapGesture { onProductTagTap(media) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .compositingGroup()
        .clipped()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var mediaContent: some View {
        ZStack {
            if let url = media.getImageURL() {
                Color(viewConfig.theme.baseColorShade4)
                    .overlay(
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
                    )
            } else {
                brokenPlaceholder
            }

            if media.type == .video {
                Image(AmityIcon.videoControlIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }
        }
    }

    /// A broken frame still carries the counter, badge and indicator — it is a frame, not a gap.
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

    private var accessibilityLabel: String {
        let position = "\(index + 1) of \(total)"
        let kind = media.type == .video ? "Video" : "Photo"
        if let altText = media.getAltText(hasDefault: false), !altText.isEmpty {
            return "\(kind) \(position): \(altText)"
        }
        return "\(kind) \(position)"
    }
}
