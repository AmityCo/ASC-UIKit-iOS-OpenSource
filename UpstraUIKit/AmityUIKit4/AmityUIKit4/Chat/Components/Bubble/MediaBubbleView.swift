//
//  MediaBubbleView.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Upload spinner

private struct MediaUploadingSpinner: View {
    /// 0...1 upload fraction. `nil` ⇒ indeterminate (spinning quarter-arc).
    var progress: Double? = nil

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 38, height: 38)

            if let progress {
                // Determinate: arc fills from the top as the upload progresses.
                Circle()
                    .trim(from: 0.0, to: CGFloat(max(0.02, min(progress, 1.0))))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: progress)
            } else {
                // Indeterminate: spinning quarter-arc.
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Upload overlay

private struct MediaUploadOverlay: View {
    var progress: Double? = nil
    var onCancel: (() -> Void)?

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(viewConfig.theme.baseColor).opacity(0.4))

            ZStack {
                MediaUploadingSpinner(progress: progress)

                if let onCancel = onCancel {
                    Button(action: onCancel) {
                        Image(AmityIcon.Chat.closeButtonIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Sizing helper

func flutterMediaBubbleSize(for imageSize: CGSize) -> CGSize {
    let maxDim: CGFloat = 240
    let w = imageSize.width
    let h = imageSize.height
    guard w > 0, h > 0 else { return CGSize(width: maxDim, height: maxDim) }

    if h >= w {
        let ratio = h / w
        let bh = maxDim
        let bw = ratio > 3 ? 80 : maxDim / ratio
        return CGSize(width: bw, height: bh)
    } else {
        let ratio = w / h
        let bw = maxDim
        let bh = ratio > 3 ? 80 : maxDim / ratio
        return CGSize(width: bw, height: bh)
    }
}

// MARK: - Bubble-size cache

private enum MediaBubbleSizeCache {
    private static let queue = DispatchQueue(label: "amityuikit.mediaBubbleSizeCache",
                                             attributes: .concurrent)
    private static var store: [String: CGSize] = [:]

    static func bubbleSize(for url: URL) -> CGSize? {
        var result: CGSize?
        queue.sync { result = store[url.absoluteString] }
        return result
    }

    static func set(_ size: CGSize, for url: URL) {
        queue.async(flags: .barrier) { store[url.absoluteString] = size }
    }
}

private func resolveMediaBubbleSize(url: URL, onResolved: @escaping (CGSize) -> Void) {
    if let cached = MediaBubbleSizeCache.bubbleSize(for: url) {
        onResolved(cached)
        return
    }

    let cache = ImageCache.default
    let key = url.cacheKey

    if let img = cache.retrieveImageInMemoryCache(forKey: key) {
        let size = flutterMediaBubbleSize(for: img.size)
        MediaBubbleSizeCache.set(size, for: url)
        onResolved(size)
        return
    }

    KingfisherManager.shared.retrieveImage(with: url) { result in
        if case .success(let value) = result {
            let size = flutterMediaBubbleSize(for: value.image.size)
            MediaBubbleSizeCache.set(size, for: url)
            DispatchQueue.main.async { onResolved(size) }
        }
    }
}

// MARK: - Image bubble

struct ImageBubbleView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let url: URL?
    let syncState: AmitySyncState
    let progress: Double?
    let isCancelled: Bool
    var onCancel: (() -> Void)? = nil

    @State private var bubbleSize: CGSize

    init(url: URL?, syncState: AmitySyncState, progress: Double? = nil, isCancelled: Bool = false, onCancel: (() -> Void)? = nil) {
        self.url = url
        self.syncState = syncState
        self.progress = progress
        self.isCancelled = isCancelled
        self.onCancel = onCancel
        let seed = url.flatMap { MediaBubbleSizeCache.bubbleSize(for: $0) }
                   ?? CGSize(width: 240, height: 240)
        _bubbleSize = State(initialValue: seed)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack {
                if let url {
                    AsyncImage(placeholderView: { placeholder }, url: url)
                        .scaledToFill()
                        .frame(width: bubbleSize.width, height: bubbleSize.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .background(
                            GeometryReader { _ in
                                Color.clear.onAppear { loadImageSize(url: url) }
                            }
                        )
                } else {
                    placeholder
                }
                if syncState == .syncing && (url == nil || progress != nil) {
                    MediaUploadOverlay(progress: progress, onCancel: onCancel)
                }
            }
            .frame(width: bubbleSize.width, height: bubbleSize.height)

            if syncState == .error && !isCancelled {
                Text(AmityLocalizedStringSet.Chat.mediaFailedToSend.localizedString)
                    .applyTextStyle(.captionSmall(Color(UIColor(red: 0xFA/255.0, green: 0x4D/255.0, blue: 0x30/255.0, alpha: 1))))
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(width: bubbleSize.width, height: bubbleSize.height)
    }

    private func loadImageSize(url: URL) {
        resolveMediaBubbleSize(url: url) { size in
            if size != bubbleSize { bubbleSize = size }
        }
    }
}

// MARK: - Video bubble

struct VideoBubbleView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let thumbnailURL: URL?
    let syncState: AmitySyncState
    let progress: Double?
    let isCancelled: Bool
    var onCancel: (() -> Void)? = nil
    let onPlay: () -> Void

    @State private var bubbleSize: CGSize

    init(thumbnailURL: URL?,
         syncState: AmitySyncState,
         progress: Double? = nil,
         isCancelled: Bool = false,
         onCancel: (() -> Void)? = nil,
         onPlay: @escaping () -> Void) {
        self.thumbnailURL = thumbnailURL
        self.syncState = syncState
        self.progress = progress
        self.isCancelled = isCancelled
        self.onCancel = onCancel
        self.onPlay = onPlay
        let seed = thumbnailURL.flatMap { MediaBubbleSizeCache.bubbleSize(for: $0) }
                   ?? CGSize(width: 240, height: 240)
        _bubbleSize = State(initialValue: seed)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .center) {
                if let url = thumbnailURL {
                    AsyncImage(placeholderView: { videoPlaceholder }, url: url)
                        .scaledToFill()
                        .frame(width: bubbleSize.width, height: bubbleSize.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .background(
                            GeometryReader { _ in
                                Color.clear.onAppear { loadImageSize(url: url) }
                            }
                        )
                } else {
                    videoPlaceholder
                }

                if syncState == .syncing {
                    MediaUploadOverlay(progress: progress, onCancel: onCancel)
                }

                if syncState == .synced {
                    Button(action: onPlay) {
                        Image(AmityIcon.Chat.videoPlayButtonIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40, height: 40)
                }
            }
            .frame(width: bubbleSize.width, height: bubbleSize.height)

            if syncState == .error && !isCancelled {
                Text(AmityLocalizedStringSet.Chat.mediaFailedToSend.localizedString)
                    .applyTextStyle(.captionSmall(Color(UIColor(red: 0xFA/255.0, green: 0x4D/255.0, blue: 0x30/255.0, alpha: 1))))
            }
        }
    }

    private var videoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(width: bubbleSize.width, height: bubbleSize.height)
    }

    private func loadImageSize(url: URL) {
        resolveMediaBubbleSize(url: url) { size in
            if size != bubbleSize { bubbleSize = size }
        }
    }
}
