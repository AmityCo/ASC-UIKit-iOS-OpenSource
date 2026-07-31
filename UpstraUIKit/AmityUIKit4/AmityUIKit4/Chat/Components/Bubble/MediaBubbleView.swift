//
//  MediaBubbleView.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import ImageIO

// MARK: - Video play disc

/// The circular video "play" affordance shown over a video thumbnail: a
/// `Surface/IconButton/Transparent/Primary/Enabled` disc holding the white
/// `video-play-s` glyph. Sizes: 40/24 in a message bubble, 24/16 in the
/// composer reply banner.
struct ChatVideoPlayDisc: View {
    let viewConfig: AmityViewConfigController
    var diameter: CGFloat = 40
    var glyphSize: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(viewConfig.color(.surfaceIconButtonTransparentPrimaryEnabled)))
            Image(AmityIcon.DesignSystem.videoPlayS.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: glyphSize, height: glyphSize)
                .foregroundColor(Color(viewConfig.color(.iconIconButtonTransparentPrimaryDefault)))
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Upload spinner

private struct MediaUploadingSpinner: View {
    /// 0...1 upload fraction. `nil` ⇒ indeterminate (spinning quarter-arc).
    var progress: Double? = nil
    let viewConfig: AmityViewConfigController

    @State private var isAnimating = false

    var body: some View {
        let trackColor = Color(viewConfig.color(.surfaceLoadersUploadControllerBackground))
        let loaderColor = Color(viewConfig.color(.surfaceLoadersUploadControllerLoader))
        ZStack {
            Circle()
                .stroke(trackColor.opacity(0.8), lineWidth: 2)
                .frame(width: 40, height: 40)

            if let progress {
                // Determinate: arc fills from the top as the upload progresses.
                Circle()
                    .trim(from: 0.0, to: CGFloat(max(0.02, min(progress, 1.0))))
                    .stroke(loaderColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: progress)
            } else {
                // Indeterminate: spinning quarter-arc.
                Circle()
                    .trim(from: 0.0, to: 0.25)
                    .stroke(loaderColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 40, height: 40)
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
        // Uploading media stays bright — no dim overlay. A 40pt ring with a 16pt
        // cross-r cancel glyph inside; the whole ring is the cancel tap target.
        Button(action: { onCancel?() }) {
            ZStack {
                MediaUploadingSpinner(progress: progress, viewConfig: viewConfig)

                Image(AmityIcon.DesignSystem.crossR.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(viewConfig.color(.iconLoadersUploadControllerDefault)))
            }
            .frame(width: 40, height: 40)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(onCancel == nil)
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

/// Pixel dimensions read straight out of the image container's metadata.
///
/// `CGImageSourceCopyPropertiesAtIndex` on a URL-backed source parses the header
/// only, so this costs a few KB no matter how large the file is. Decoding the
/// image just to read `UIImage.size` would materialise a full-resolution bitmap
/// (`width * height * 4` bytes), which for a large pick can exhaust the app's
/// memory budget on its own.
private func imagePixelSize(atFileURL url: URL) -> CGSize? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Double,
          let height = properties[kCGImagePropertyPixelHeight] as? Double,
          width > 0, height > 0
    else { return nil }

    // EXIF orientations 5–8 rotate by 90°, so the displayed axes are swapped.
    if let orientation = properties[kCGImagePropertyOrientation] as? UInt32, orientation >= 5 {
        return CGSize(width: height, height: width)
    }
    return CGSize(width: width, height: height)
}

private func resolveMediaBubbleSize(url: URL, onResolved: @escaping (CGSize) -> Void) {
    if let cached = MediaBubbleSizeCache.bubbleSize(for: url) {
        onResolved(cached)
        return
    }

    // Local file — a message that is still uploading. Read the dimensions from the
    // header instead of decoding, so bubble layout never depends on the full image.
    if url.isFileURL {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pixelSize = imagePixelSize(atFileURL: url) else { return }
            let size = flutterMediaBubbleSize(for: pixelSize)
            MediaBubbleSizeCache.set(size, for: url)
            DispatchQueue.main.async { onResolved(size) }
        }
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

// MARK: - Local image thumbnail

/// Bubble-sized thumbnails decoded straight from a local file URL.
///
/// Used for messages that are still uploading. Passing a large local file to
/// Kingfisher instead is not viable: its processors operate on `Data`, so the whole
/// file is read into memory before any downsampling happens, and without a processor
/// it decodes at full native resolution. `CGImageSourceCreateThumbnailAtIndex` on a
/// URL-backed source reads only the bytes it needs to produce the requested size.
private enum LocalImageThumbnailLoader {

    /// Matches `flutterMediaBubbleSize`'s largest edge.
    static let maxBubbleDimension: CGFloat = 240

    static var thumbnailPixelSize: CGFloat {
        maxBubbleDimension * UIScreen.main.scale
    }

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 40
        return cache
    }()

    static func load(url: URL, maxPixelSize: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let key = "\(url.absoluteString)|\(Int(maxPixelSize))" as NSString

        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var thumbnail: UIImage?

            if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
                ]
                if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            }

            if let thumbnail {
                cache.setObject(thumbnail, forKey: key)
            }
            DispatchQueue.main.async { completion(thumbnail) }
        }
    }
}

private struct LocalImageThumbnailView: View {

    let url: URL
    let maxPixelSize: CGFloat
    let placeholder: AnyView

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .onAppear {
            guard thumbnail == nil else { return }
            LocalImageThumbnailLoader.load(url: url, maxPixelSize: maxPixelSize) { image in
                thumbnail = image
            }
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
                    imageContent(url: url)
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

    /// Local files are still uploading, so they come off disk as a bubble-sized
    /// thumbnail. Remote URLs are already server-resized and keep the shared
    /// `AsyncImage`/Kingfisher path (and its cache).
    @ViewBuilder
    private func imageContent(url: URL) -> some View {
        if url.isFileURL {
            LocalImageThumbnailView(
                url: url,
                maxPixelSize: LocalImageThumbnailLoader.thumbnailPixelSize,
                placeholder: AnyView(placeholder)
            )
        } else {
            AsyncImage(placeholderView: { placeholder }, url: url)
                .scaledToFill()
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
                        ChatVideoPlayDisc(viewConfig: viewConfig)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 40, height: 40)
                }
            }
            .frame(width: bubbleSize.width, height: bubbleSize.height)
            .contentShape(Rectangle())

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
