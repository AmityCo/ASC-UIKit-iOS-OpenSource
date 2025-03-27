//
//  PostCreationMediaPreviewView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/10/24.
//

import SwiftUI
import AVKit

struct PostCreationMediaAttachmentPreviewView: View {
    
    @ObservedObject private var mediaAttachmentViewModel: AmityMediaAttachmentViewModel
    
    init(viewModel: AmityMediaAttachmentViewModel) {
        self.mediaAttachmentViewModel = viewModel
    }
    
    var body: some View {
        VStack {
            getGridView()
        }
        .padding([.leading, .trailing], 16)
    }
    
    
    @ViewBuilder
    private func getGridView() -> some View {
        let columns = (0..<getColumnCount()).map { _ in GridItem(.flexible()) }
        
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(Array(mediaAttachmentViewModel.medias.enumerated()), id: \.element.id) { index, media in
                MediaAttachmentView(
                    media: media, 
                    mediaViewModel: mediaAttachmentViewModel,
                    removeAction: {
                        mediaAttachmentViewModel.medias.remove(at: index)
                    }
                )
                .frame(height: mediaAttachmentViewModel.medias.count < 3 ? 300 : 140)
            }
        }
    }
    
    private func getColumnCount() -> Int {
        switch mediaAttachmentViewModel.medias.count {
        case 1: return 1
        case 2: return 2
        default: return 3
        }
    }
}


struct MediaAttachmentView: View {
    
    private let media: AmityMedia
    private let removeAction: () -> Void
    private let fileRepositoryManager = FileRepositoryManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @ObservedObject private var mediaViewModel: AmityMediaAttachmentViewModel
    
    init(media: AmityMedia, mediaViewModel: AmityMediaAttachmentViewModel, removeAction: @escaping () -> Void) {
        self.media = media
        self.mediaViewModel = mediaViewModel
        self.removeAction = removeAction
        print(media.state)
        print(media.type)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .overlay(
                    ZStack {
                        if media.type == .image {
                            if let mediaImage = media.localUIImage {
                                Image(uiImage: mediaImage)
                                    .resizable()
                                    .scaledToFill()
                            } else if let url = media.getImageURL() {
                                Color.clear
                                    .overlay(
                                        KFImage.url(url)
                                            .placeholder {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            }
                                            .resizable()
                                            .fromMemoryCacheOrRefresh()
                                            .startLoadingBeforeViewAppear()
                                            .aspectRatio(contentMode: .fill)
                                    )
                                    .clipped()
                                    .contentShape(Rectangle())
                            } else {
                                let image = UIImage(contentsOfFile: media.localUrl?.path ?? "")
                                Image(uiImage: image ?? UIImage())
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        
                        
                        if media.type == .video {
                            if let thumbnail = media.generatedThumbnailImage {
                                Image(uiImage: media.generatedThumbnailImage ?? UIImage())
                                    .resizable()
                                    .scaledToFill()
                            } else if let url = media.getImageURL() {
                                Color.clear
                                    .overlay(
                                        KFImage.url(url)
                                            .placeholder {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            }
                                            .resizable()
                                            .fromMemoryCacheOrRefresh()
                                            .startLoadingBeforeViewAppear()
                                            .aspectRatio(contentMode: .fill)
                                    )
                                    .clipped()
                                    .contentShape(Rectangle())
                            }
                            
                            Image(AmityIcon.videoControlIcon.getImageResource())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                        }
                        
                        /// Display loading progress view if media.state is uploading...
                        if case .uploading(let progress) = media.state {
                            Color.black.opacity(0.5)
                            getProgressView(progress)
                        }
                        
                        /// Display error view if media.state is error...
                        if case .error = media.state {
                            Color.black.opacity(0.5)
                            Image(AmityIcon.mediaUploadErrorIcon.getImageResource())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                        }
                        
                        /// Display error view if network is not connected...
                        if !networkMonitor.isConnected {
                            Color.black.opacity(0.5)
                            Image(AmityIcon.mediaUploadErrorIcon.getImageResource())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                        }
                    }
                )
                .clipped()
            
            Button(action: {
                removeAction()
            }, label: {
                Image(AmityIcon.backgroundedCloseIcon.getImageResource())
                    .resizable()
                    .scaledToFill()
                    .frame(size: CGSize(width: 24, height: 24))
                    .padding(.all, 10)
            })
        }
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onAppear {
            
            if case .image(let image) = media.state, media.type == .image {
                uploadImage(image: image)
            }
            
            if case .localURL(_) = media.state, media.type == .image {
                uploadImage()
            }
            
            if case .localURL(_) = media.state, media.type == .video {
                generatedThumbnailAndUploadVideo()
            }
        }
    }
    
    
    func getProgressView(_ progress: CGFloat) -> some View {
        Circle()
            .stroke(lineWidth: 3.0)
            .fill(
                Color.white
            )
            .overlay(
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        .blue,
                        lineWidth: 3.0
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.01), value: progress)
            )
            .frame(width: 30, height: 30)
    }
    
    
    private func uploadImage() {
        // Note: This is not a fool-proof way to check image file type. Ideally we want to check starting bytes of the file instead. Since these images are selected from photo gallery or captured using device camera, we are sure that its an image file.
        // So for simplicity, we just check the file extension of the URL for that image.
        let allowedFormats: Set<String> = ["jpg","jpeg","png"]
        let imageExtension = media.localUrl?.pathExtension.lowercased() ?? ""
        let needsConversion = !allowedFormats.contains(imageExtension)
        
        if needsConversion {
            // Change state outside of dispatch queue
            media.state = .uploading(progress: 0)
        }

        DispatchQueue.global(qos: .background).async {
            if needsConversion {
                if let convertedImageURL = ImageConverter.convertImage(url: media.localUrl ?? URL(fileURLWithPath: "")) {
                    startImageUpload(imageURL: convertedImageURL)
                }
            } else {
                startImageUpload(imageURL: media.localUrl ?? URL(fileURLWithPath: ""))
            }
        }
    }
    
    private func startImageUpload(imageURL: URL) {
        fileRepositoryManager.fileRepository.uploadImage(with: imageURL, isFullImage: true) { progress in
            DispatchQueue.main.async {
                Log.add(event: .info, "Image Upload progress: \(progress)")
                media.state = .uploading(progress: progress)
                
                // Trigger objectWillChange to update the button state
                self.mediaViewModel.updateMediaState(media)
            }
        } completion: { imageData, error in
            DispatchQueue.main.async {
                if let error {
                    media.state = .error
                    self.mediaViewModel.updateMediaState(media)
                    return
                }
                
                guard let imageData else { return }
                Log.add(event: .info, "Image Uploaded!!!")
                media.state = .uploadedImage(data: imageData)
                
                // Trigger objectWillChange to update the button state
                self.mediaViewModel.updateMediaState(media)
            }
        }
    }
    
    // Note: No need for conversion as png image is extracted from UIImage internally in SDK
    private func uploadImage(image: UIImage) {
        Task { @MainActor in
            do {
                let imageData = try await fileRepositoryManager.fileRepository.uploadImage(image) { progress in
                    
                    DispatchQueue.main.async {
                        Log.add(event: .info, "Image Upload progress: \(progress)")
                        media.state = .uploading(progress: progress)
                        
                        // Update view model state
                        self.mediaViewModel.updateMediaState(media)
                    }
                }
                
                Log.add(event: .info, "Image Uploaded!!!")
                media.state = .uploadedImage(data: imageData)
                
                // Update view model state
                self.mediaViewModel.updateMediaState(media)
            } catch {
                media.state = .error
                self.mediaViewModel.updateMediaState(media)
                return
            }
        }
    }
    
    private func generatedThumbnailAndUploadVideo() {
        let originalURL = media.localUrl ?? URL(fileURLWithPath: "")
        
        generateThumbnail(videoURL: originalURL)
        
        media.state = .uploading(progress: 0.1)
        
        let asset = AVAsset(url: originalURL)
        if VideoConverter.shouldConvertVideo(asset: asset) {
            Log.add(event: .info, "Converting video to supported type..")
            VideoConverter.convertVideo(asset: asset) { convertedVideoURL in
                Log.add(event: .info, "Video Converted! Starting upload process...")
                startVideoUpload(videoURL: convertedVideoURL ?? URL(fileURLWithPath: ""))
            }
            
        } else {
            Log.add(event: .info, "Uploading original video..")
            startVideoUpload(videoURL: originalURL)
        }
    }
    
    private func generateThumbnail(videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1.0, preferredTimescale: 1)
        var actualTime: CMTime = CMTime.zero
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            media.generatedThumbnailImage = UIImage(cgImage: imageRef)
        } catch {
            print("Unable to generate thumbnail image for kUTTypeMovie.")
        }
    }
    
    private func startVideoUpload(videoURL: URL) {
        
        Task { @MainActor in
            do {
                let videoData = try await fileRepositoryManager.fileRepository.uploadVideo(with: videoURL) { progress in
                    DispatchQueue.main.async {
                        Log.add(event: .info, "Video Upload progress: \(progress)")
                        media.state = .uploading(progress: progress)
                        
                        // Update view model state
                        self.mediaViewModel.updateMediaState(media)
                    }
                }
                
                Log.add(event: .info, "Video Uploaded!!!")
                media.state = .uploadedVideo(data: videoData)
                self.mediaViewModel.updateMediaState(media)
            } catch let error {
                media.state = .error
                self.mediaViewModel.updateMediaState(media)
            }
        }
    }
}
