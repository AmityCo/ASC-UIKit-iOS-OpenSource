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
    /// `postId#index` for a published post's media; nil where a video must not auto-play.
    var playbackKey: String? = nil

    @Environment(\.feedAutoPlayHost) private var feedAutoPlayHost
    @ObservedObject private var autoPlay = FeedAutoPlayStore.shared
    /// The same post can be on screen twice (a feed under another feed), so each frame instance reports
    /// under its own key.
    @State private var instanceId = UUID()

    private var autoPlayKey: String? {
        guard feedAutoPlayHost, media.type == .video, !media.isFailedTranscodeVideo, let playbackKey else { return nil }
        // A video still processing is a candidate like any other (it shows the spinner while it is the pick).
        if !media.isProcessingVideo {
            guard let url = media.autoPlayVideoURL, !autoPlay.hasFailed(url) else { return nil }
        }
        return "\(playbackKey)#\(instanceId.uuidString)"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mediaContent

            if isActive, media.isProcessingVideo, let fileId = media.video?.fileId,
               let postId = playbackKey?.split(separator: "#").first.map(String.init) {
                FeedProcessingVideoView(postId: postId, fileId: fileId, accessibilityLabel: accessibilityLabel)
            } else if isActive, let url = media.autoPlayVideoURL {
                FeedInlineVideoView(url: url, accessibilityLabel: accessibilityLabel)
            } else if media.type == .video, feedAutoPlayHost {
                // Not playing: the frame reads as the thumbnail, or as the fallback once its video failed.
                Color.clear
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.frame)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityValue(isFallback ? "fallback" : "thumbnail") // l10n:ok test value
            }

            if !media.produtTags.isEmpty {
                AmityProductTagBadgeView(count: media.produtTags.count, icon: .productTagFilledIcon)
                    .padding(12)
                    .onTapGesture { onProductTagTap(media) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .reportsFeedAutoPlayVisibility(key: autoPlayKey)
        .onAppear {
            guard feedAutoPlayHost, media.type == .video else { return }
            autoPlay.noteVideo(media.autoPlayVideoURL, inPost: playbackKey?.split(separator: "#").first.map(String.init))
        }
        .compositingGroup()
        .clipped()
        .contentShape(Rectangle())
        // Inside a feed that auto-plays, a video frame keeps its parts apart so its sound button and Watch again
        // can be reached; elsewhere the frame reads as one element, as before.
        .accessibilityElement(children: feedAutoPlayHost && media.type == .video ? .contain : .combine)
        .accessibilityLabel(feedAutoPlayHost && media.type == .video ? "" : accessibilityLabel)
    }

    @ViewBuilder
    private var mediaContent: some View {
        ZStack {
            mediaImage
                .accessibilityHidden(feedAutoPlayHost && media.type == .video)

            // The play icon shows only while auto-play is off for this frame (switched off, not allowed on
            // this connection, not a feed that auto-plays, or the video failed); the inline player draws
            // its own spinner while this frame is the one playing. In a feed it is its own element, for tests.
            if media.type == .video, !isActive, !(autoPlay.isAutoPlayOn && autoPlayKey != nil) {
                Image(AmityIcon.videoControlIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .allowsHitTesting(false)
                    .feedPlayButtonAccessibility(feedAutoPlayHost)
            }
        }
    }

    @ViewBuilder
    private var mediaImage: some View {
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

            if feedAutoPlayHost, media.type == .video, let frame = autoPlay.keptFrame(for: media.autoPlayVideoURL) {
                Color.clear
                    .overlay(
                        Image(uiImage: frame)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
            }
        }
    }

    private var isActive: Bool {
        guard let autoPlayKey else { return false }
        return autoPlay.activeKey == autoPlayKey
    }

    /// Playback failed: the server could not process the video, or it failed to load or play. A video still
    /// processing never shows the fallback.
    private var isFallback: Bool {
        if media.isFailedTranscodeVideo { return true }
        return !media.isProcessingVideo && autoPlay.hasFailed(media.autoPlayVideoURL)
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
