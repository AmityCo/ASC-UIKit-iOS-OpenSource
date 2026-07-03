//
//  FileRepositoryManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/13/24.
//

import Foundation
import AmitySDK
import UIKit

class FileRepositoryManager {
    let fileRepository = AmityFileRepository()

    func uploadImage(_ image: UIImage) async throws -> AmityImageData {
        return try await fileRepository.uploadImage(image, progress: nil)
    }

    func downloadFile(fromURL url: String) async throws -> URL {
        return try await fileRepository.downloadFile(fromURL: url)
    }

    /// Observe upload progress. Pass `message.uniqueId` (== the upload id).
    func observeUploadProgress(uploadId: String, onProgress: @escaping (Double) -> Void) {
        fileRepository.getUploadProgress(forUploadId: uploadId, progress: onProgress)
    }

    /// Cancels an in-flight upload. Pass `message.uniqueId` (== the upload id).
    func cancelUpload(uploadId: String) {
        fileRepository.cancelUpload(forUploadId: uploadId)
    }
}
