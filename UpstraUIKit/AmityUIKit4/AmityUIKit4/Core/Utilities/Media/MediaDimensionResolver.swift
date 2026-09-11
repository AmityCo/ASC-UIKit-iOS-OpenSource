//
//  MediaDimensionResolver.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/5/26.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import ImageIO
import AmitySDK

/// Resolves a media item's source pixel dimensions, so a carousel frame's height is known before the
/// asset loads. Published media reads them from `attributes.metadata`; local media is measured.
enum MediaDimensionResolver {

    static func pixelSize(of media: AmityMedia) -> CGSize? {
        publishedSize(of: media) ?? localSize(of: media)
    }

    private static func publishedSize(of media: AmityMedia) -> CGSize? {
        switch media.state {
        case .downloadableImage(let imageData, _), .uploadedImage(let imageData):
            return imageSize(fromMetadataIn: imageData.attributes)
        case .downloadableVideo(let videoData, _), .uploadedVideo(let videoData):
            return videoSize(fromMetadataIn: videoData.attributes)
        default:
            return nil
        }
    }

    /// The local source, which `AmityMedia` retains across state changes.
    ///
    /// This is what keeps the composer frame a stable shape: `.uploading` carries no dimensions of its
    /// own, so without it a frame would sit at the 1:1 fallback for the whole upload and then jump to
    /// the real ratio the moment it settled.
    private static func localSize(of media: AmityMedia) -> CGSize? {
        if case .image(let image) = media.state, let size = size(of: image) {
            return size
        }
        if case .localAsset(let asset) = media.state {
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            if isUsable(size) { return size }
        }

        if let image = media.localUIImage, let size = size(of: image) {
            return size
        }
        if let asset = media.localAsset {
            let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            if isUsable(size) { return size }
        }
        if let url = media.localUrl {
            switch media.type {
            case .image: if let size = imageSize(atFileURL: url) { return size }
            case .video: if let size = videoSize(atFileURL: url) { return size }
            case .none: break
            }
        }
        // Generated with `appliesPreferredTrackTransform`, so it is already display-oriented.
        return media.generatedThumbnailImage.flatMap(size(of:))
    }

    private static func size(of image: UIImage) -> CGSize? {
        let size = CGSize(width: image.size.width * image.scale,
                          height: image.size.height * image.scale)
        return isUsable(size) ? size : nil
    }

    /// The ratio every frame in a carousel uses, classified from the first attachment.
    /// Falls back to `.square` — the middle band, so an unknown source is never more than one band out.
    static func lockedRatio(for medias: [AmityMedia]) -> MediaAspectRatio {
        guard let first = medias.first else { return .square }

        guard let size = pixelSize(of: first) else {
            Log.add(event: .warn, "MediaDimensionResolver: no usable dimensions for media \(first.id) (type: \(first.type)); falling back to 1:1")
            return .square
        }

        return MediaRatioClassifier.classify(size: size)
    }

    // MARK: - Sources

    /// `metadata.width` / `metadata.height`.
    private static func imageSize(fromMetadataIn attributes: [String: Any]) -> CGSize? {
        guard let metadata = attributes["metadata"] as? [String: Any] else { return nil }
        return size(fromDimensionsIn: metadata)
    }

    /// `metadata.video.width` / `.height` — a level deeper than an image. Reading it the image way
    /// finds nothing and classifies every video post as 1:1.
    ///
    /// These are the **stored** dimensions, before rotation, so a portrait-filmed clip reports
    /// landscape. `metadata.video.rotation` carries the quarter turn, and at 90 or 270 the displayed
    /// shape is the transpose. `display_aspect_ratio` is derived from the stored values and is no help.
    private static func videoSize(fromMetadataIn attributes: [String: Any]) -> CGSize? {
        guard let metadata = attributes["metadata"] as? [String: Any],
              let video = metadata["video"] as? [String: Any],
              let stored = size(fromDimensionsIn: video) else {
            return nil
        }

        guard let rotation = rotationDegrees(in: video), rotation == 90 || rotation == 270 else {
            return stored
        }
        return CGSize(width: stored.height, height: stored.width)
    }

    /// Normalised to `0..<360`, so a `-90` reads as `270`. Accepts a number or a numeric string.
    private static func rotationDegrees(in video: [String: Any]) -> Int? {
        let degrees: Int?
        switch video["rotation"] {
        case let number as NSNumber: degrees = number.intValue
        case let string as String: degrees = Int(string.trimmingCharacters(in: .whitespaces))
        default: degrees = nil
        }
        guard let degrees else { return nil }
        return ((degrees % 360) + 360) % 360
    }

    private static func size(fromDimensionsIn dictionary: [String: Any]) -> CGSize? {
        guard let width = numeric(dictionary["width"]),
              let height = numeric(dictionary["height"]) else {
            return nil
        }
        let size = CGSize(width: width, height: height)
        return isUsable(size) ? size : nil
    }

    private static func numeric(_ value: Any?) -> CGFloat? {
        switch value {
        case let number as NSNumber: return CGFloat(number.doubleValue)
        case let int as Int: return CGFloat(int)
        case let double as Double: return CGFloat(double)
        default: return nil
        }
    }

    /// Reads the header only, no full decode.
    private static func imageSize(atFileURL url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = numeric(properties[kCGImagePropertyPixelWidth]),
              let height = numeric(properties[kCGImagePropertyPixelHeight]) else {
            return nil
        }
        let size = CGSize(width: width, height: height)
        return isUsable(size) ? size : nil
    }

    /// A phone-shot portrait video is stored landscape with a rotation flag. Without
    /// `preferredTransform` every portrait video classifies as 16:9.
    private static func videoSize(atFileURL url: URL) -> CGSize? {
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else { return nil }

        let transformed = track.naturalSize.applying(track.preferredTransform)
        let size = CGSize(width: abs(transformed.width), height: abs(transformed.height))
        return isUsable(size) ? size : nil
    }

    private static func isUsable(_ size: CGSize) -> Bool {
        size.width > 0 && size.height > 0
    }
}
