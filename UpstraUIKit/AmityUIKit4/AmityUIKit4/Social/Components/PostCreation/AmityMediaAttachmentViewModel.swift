//
//  AmityMediaAttachmentViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/13/24.
//

import Foundation
import Combine
import AVKit
import UIKit
import AmitySDK

public class AmityMediaAttachmentViewModel: ObservableObject {
    @Published var medias: [AmityMedia] = []
    @Published var areAttachmentsReady: Bool = true
    @Published var isAnyMediaFailed: Bool = false
    var isPostEditing: Bool = false

    /// The ratio every carousel frame uses. Positional: it follows whatever attachment currently
    /// occupies first position, so removing the first re-derives the shape from its replacement.
    @Published private(set) var lockedRatio: MediaAspectRatio = .square

    private var lockedRatioSourceId: String?
    private let fileRepositoryManager = FileRepositoryManager()
    private var cancellables = Set<AnyCancellable>()

    public init(medias: [AmityMedia] = [], isPostEditing: Bool) {
        self.medias = medias
        self.isPostEditing = isPostEditing
        updateAttachmentReadiness()
        refreshLockedRatio()

        $medias
            .sink { [weak self] medias in
                // `$medias` fires in willSet, so `self.medias` is still the pre-mutation array here.
                self?.updateAttachmentReadiness(for: medias)
                self?.refreshLockedRatio(for: medias)
            }
            .store(in: &cancellables)
    }

    // Call this method whenever a media's state changes
    func updateMediaState(_ media: AmityMedia) {
        updateAttachmentReadiness()
    }

    private func updateAttachmentReadiness(for medias: [AmityMedia]? = nil) {
        let medias = medias ?? self.medias

        if medias.isEmpty {
            areAttachmentsReady = true
            isAnyMediaFailed = false
        } else {
            // Consider media ready ONLY if it's in a final uploaded state
            areAttachmentsReady = !medias.contains { media in
                switch media.state {
                case .uploadedImage, .uploadedVideo, .downloadableImage, .downloadableVideo, .downloadableClip:
                    // These states are fully processed and ready
                    return false
                default:
                    // Any other state (including localURL, image, uploading, error)
                    // means we're not ready yet
                    return true
                }
            }

            isAnyMediaFailed = medias.contains { media in
                if case .error = media.state { return true } else { return false }
            }
        }
    }

    // MARK: - Frame ratio

    private func refreshLockedRatio(for medias: [AmityMedia]? = nil) {
        let medias = medias ?? self.medias
        let firstId = medias.first?.id
        guard firstId != lockedRatioSourceId else { return }

        lockedRatioSourceId = firstId
        lockedRatio = MediaDimensionResolver.lockedRatio(for: medias)
    }

    // MARK: - Upload

    /// Starts whatever upload the media's state calls for.
    ///
    /// Owned here rather than by the preview frame: a carousel recycles its frames, and upload state
    /// tied to a view is lost when one goes away.
    func startUploadIfNeeded(for media: AmityMedia) {
        switch (media.state, media.type) {
        case (.image(let image), .image):
            uploadImage(image, for: media)
        case (.localURL, .image):
            uploadImage(media)
        case (.localURL, .video):
            generateThumbnailAndUploadVideo(media)
        default:
            break
        }
    }

    private func uploadImage(_ media: AmityMedia) {
        // Note: This is not a fool-proof way to check image file type. Ideally we want to check starting bytes of the file instead. Since these images are selected from photo gallery or captured using device camera, we are sure that its an image file.
        // So for simplicity, we just check the file extension of the URL for that image.
        let allowedFormats: Set<String> = ["jpg", "jpeg", "png"]
        let imageExtension = media.localUrl?.pathExtension.lowercased() ?? ""
        let needsConversion = !allowedFormats.contains(imageExtension)

        // Validate file size: reject images over 1 GB
        let maxImageFileSize: Int64 = 1_073_741_824 // 1 GB
        if let url = media.localUrl,
           let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           Int64(fileSize) > maxImageFileSize {
            media.state = .error
            updateMediaState(media)
            return
        }

        // Set uploading state immediately before starting async upload
        media.state = .uploading(progress: 0)
        updateMediaState(media)

        DispatchQueue.global(qos: .background).async { [weak self] in
            if needsConversion {
                if let convertedImageURL = ImageConverter.convertImage(url: media.localUrl ?? URL(fileURLWithPath: "")) {
                    self?.startImageUpload(imageURL: convertedImageURL, for: media)
                }
            } else {
                self?.startImageUpload(imageURL: media.localUrl ?? URL(fileURLWithPath: ""), for: media)
            }
        }
    }

    private func startImageUpload(imageURL: URL, for media: AmityMedia) {
        fileRepositoryManager.fileRepository.uploadImage(with: imageURL, isFullImage: true) { progress in
            DispatchQueue.main.async { [weak self] in
                Log.add(event: .info, "Image Upload progress: \(progress)")
                media.state = .uploading(progress: progress)
                self?.updateMediaState(media)
            }
        } completion: { imageData, error in
            DispatchQueue.main.async { [weak self] in
                if error != nil {
                    media.state = .error
                    self?.updateMediaState(media)
                    return
                }

                guard let imageData else { return }
                Log.add(event: .info, "Image Uploaded!!!")
                media.state = .uploadedImage(data: imageData)
                self?.updateMediaState(media)
            }
        }
    }

    // Note: No need for conversion as png image is extracted from UIImage internally in SDK
    private func uploadImage(_ image: UIImage, for media: AmityMedia) {
        // Validate file size: reject images over 1 GB
        let maxImageFileSize: Int64 = 1_073_741_824 // 1 GB
        if let imageData = image.jpegData(compressionQuality: 1.0),
           Int64(imageData.count) > maxImageFileSize {
            media.state = .error
            updateMediaState(media)
            return
        }

        // Set uploading state immediately before starting async upload
        media.state = .uploading(progress: 0)
        updateMediaState(media)

        Task { @MainActor in
            do {
                let imageData = try await fileRepositoryManager.fileRepository.uploadImage(image) { progress in
                    DispatchQueue.main.async { [weak self] in
                        Log.add(event: .info, "Image Upload progress: \(progress)")
                        media.state = .uploading(progress: progress)
                        self?.updateMediaState(media)
                    }
                }

                Log.add(event: .info, "Image Uploaded!!!")
                media.image = imageData
                media.state = .uploadedImage(data: imageData)
                updateMediaState(media)
            } catch {
                media.state = .error
                updateMediaState(media)
            }
        }
    }

    private func generateThumbnailAndUploadVideo(_ media: AmityMedia) {
        let originalURL = media.localUrl ?? URL(fileURLWithPath: "")
        media.state = .uploading(progress: 0.1)

        generateThumbnail(videoURL: originalURL, for: media)

        let asset = AVAsset(url: originalURL)
        if VideoConverter.shouldConvertVideo(asset: asset) {
            Log.add(event: .info, "Converting video to supported type..")
            VideoConverter.convertVideo(asset: asset) { [weak self] convertedVideoURL in
                Log.add(event: .info, "Video Converted! Starting upload process...")
                self?.startVideoUpload(videoURL: convertedVideoURL ?? URL(fileURLWithPath: ""), for: media)
            }
        } else {
            Log.add(event: .info, "Uploading original video..")
            startVideoUpload(videoURL: originalURL, for: media)
        }
    }

    private func generateThumbnail(videoURL: URL, for media: AmityMedia) {
        let asset = AVAsset(url: videoURL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 1)
        var actualTime: CMTime = CMTime.zero
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            media.generatedThumbnailImage = UIImage(cgImage: imageRef)
        } catch {
            Log.add(event: .error, "Unable to generate thumbnail image for kUTTypeMovie.")
        }
    }

    private func startVideoUpload(videoURL: URL, for media: AmityMedia) {
        Task { @MainActor in
            do {
                let videoData = try await fileRepositoryManager.fileRepository.uploadVideo(with: videoURL) { progress in
                    DispatchQueue.main.async { [weak self] in
                        Log.add(event: .info, "Video Upload progress: \(progress)")
                        media.state = .uploading(progress: progress)
                        self?.updateMediaState(media)
                    }
                }

                Log.add(event: .info, "Video Uploaded!!!")
                media.video = videoData
                media.state = .uploadedVideo(data: videoData)
                updateMediaState(media)
            } catch {
                media.state = .error
                updateMediaState(media)
            }
        }
    }
}
