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
                MediaAttachmentView(media: media, removeAction: {
                    mediaAttachmentViewModel.medias.remove(at: index)
                })
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
    @State private var mediaState: AmityMediaState = .none
    @StateObject private var networkMonitor = NetworkMonitor()
    
    init(media: AmityMedia, removeAction: @escaping () -> Void) {
        self.media = media
        self.removeAction = removeAction
        self.mediaState = mediaState
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
                            } else if let url = media.image?.largeFileURL.url {
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
                            Image(uiImage: media.generatedThumbnailImage ?? UIImage())
                                .resizable()
                                .scaledToFill()
                            
                            Image(AmityIcon.videoControlIcon.getImageResource())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                        }
                        
                        /// Display loading progress view if mediaState is uploading...
                        if case .uploading(let progress) = mediaState {
                            Color.black.opacity(0.5)
                            getProgressView(progress)
                        }
                        
                        /// Display error view if mediaState is error...
                        if case .error = mediaState {
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
        DispatchQueue.global(qos: .background).async {
            fileRepositoryManager.fileRepository.uploadImage(with: media.localUrl ?? URL(fileURLWithPath: ""), isFullImage: true) { progress in
                DispatchQueue.main.async {
                    Log.add(event: .info, "Image Upload progress: \(progress)")
                    media.state = .uploading(progress: progress)
                    
                    /// Update media state to use within view
                    mediaState = .uploading(progress: progress)
                }
            } completion: { imageData, error in
                DispatchQueue.main.async {
                    if let error {
                        mediaState = .error
                        return
                    }
                    
                    guard let imageData else { return }
                    Log.add(event: .info, "Image Uploaded!!!")
                    media.state = .uploadedImage(data: imageData)
                    
                    /// Update media state to use within view
                    mediaState = .uploadedImage(data: imageData)
                }
            }
        }
    }
    
    
    private func uploadImage(image: UIImage) {
        
        Task { @MainActor in
            do {
                let imageData = try await fileRepositoryManager.fileRepository.uploadImage(image) { progress in
                    
                    DispatchQueue.main.async {
                        Log.add(event: .info, "Image Upload progress: \(progress)")
                        media.state = .uploading(progress: progress)
                        
                        /// Update media state to use within view
                        mediaState = .uploading(progress: progress)
                    }
                }
                
                Log.add(event: .info, "Image Uploaded!!!")
                media.state = .uploadedImage(data: imageData)
                
                /// Update media state to use within view
                mediaState = .uploadedImage(data: imageData)
            } catch {
                mediaState = .error
                return
            }
            
        }
        
    }
    
    
    private func generatedThumbnailAndUploadVideo() {
        let asset = AVAsset(url: media.localUrl ?? URL(fileURLWithPath: ""))
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
        
        fileRepositoryManager.fileRepository.uploadVideo(with: media.localUrl ?? URL(fileURLWithPath: "")) { progress in
            DispatchQueue.main.async {
                Log.add(event: .info, "Video Upload progress: \(progress)")
                media.state = .uploading(progress: progress)
                
                /// Update media state to use within view
                mediaState = .uploading(progress: progress)
            }
        } completion: { videoData, error in
            DispatchQueue.main.async {
                if let error {
                    mediaState = .error
                    return
                }
                
                guard let videoData else { return }
                
                Log.add(event: .info, "Video Uploaded!!!")
                media.state = .uploadedVideo(data: videoData)
                
                /// Update media state to use within view
                mediaState = .uploadedVideo(data: videoData)
            }
        }
    }
}
