//
//  AmityDraftClipPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/6/25.
//

import AmitySDK
import SwiftUI
import AVFoundation

class AmityDraftClipPageViewModel: ObservableObject {
    
    let fileRepo = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    @Published var isUploadingClip = false
    @Published var uploadProgress: Double = 0
    @Published var isUploadError: Bool = false
    
    var clipData: AmityClipData?
    
    func uploadClip(url: URL) {
        // Do not start uploading again when moving back from composer page.
        guard !isUploadingClip && clipData == nil else { return }
        
        Log.add(event: .info, "Uploading clip...")
        isUploadingClip = true
        
        Task { @MainActor in
            
            do {
                let uploadData = try await fileRepo.uploadClip(with: url) { [weak self] progress in
                    guard let self else { return }
                    
                    self.uploadProgress = progress * 100
                }
                self.clipData = uploadData
                Log.add(event: .info, "Clip uploaded: \(uploadData.fileId)")
                self.isUploadingClip = false
            } catch {
                Log.warn("Error while uploading clip \(error)")
                self.isUploadingClip = false
                self.isUploadError = true
            }
        }
    }
    
    // Just incase we need to convert the clip
    func processVideo(url: URL) async -> URL  {
        return await withCheckedContinuation { continuation in
            let asset = AVAsset(url: url)
            
            if VideoConverter.shouldConvertVideo(asset: asset) {
                Log.add(event: .info, "Converting video to supported type..")
                VideoConverter.convertVideo(asset: asset) { responseURL in
                    Log.add(event: .info, "Video Converted! Starting upload process...")
                    continuation.resume(with: .success(responseURL ?? url))
                }
            } else {
                Log.add(event: .info, "Uploading original video..")
                continuation.resume(with: .success(url))
            }
        }
    }
}

