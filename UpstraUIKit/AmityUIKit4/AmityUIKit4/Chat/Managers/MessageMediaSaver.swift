//
//  MessageMediaSaver.swift
//  AmityUIKit4
//

import Foundation
import Photos
import UIKit

enum MessageMediaSaver {

    static func saveImage(from url: URL, completion: @escaping (Bool) -> Void) {
        requestAddOnlyAuthorization { granted in
            guard granted else { completion(false); return }
            download(url: url, suffix: "img") { tempURL in
                guard let tempURL else { completion(false); return }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempURL)
                }) { success, _ in
                    try? FileManager.default.removeItem(at: tempURL)
                    DispatchQueue.main.async { completion(success) }
                }
            }
        }
    }

    static func saveVideo(from url: URL, completion: @escaping (Bool) -> Void) {
        requestAddOnlyAuthorization { granted in
            guard granted else { completion(false); return }
            download(url: url, suffix: "mp4") { tempURL in
                guard let tempURL else { completion(false); return }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                }) { success, _ in
                    try? FileManager.default.removeItem(at: tempURL)
                    DispatchQueue.main.async { completion(success) }
                }
            }
        }
    }

    // MARK: - Private

    private static func requestAddOnlyAuthorization(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if current == .authorized || current == .limited {
                completion(true); return
            }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                completion(status == .authorized || status == .limited)
            }
        } else {
            let current = PHPhotoLibrary.authorizationStatus()
            if current == .authorized {
                completion(true); return
            }
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        }
    }

    private static func download(url: URL, suffix: String, completion: @escaping (URL?) -> Void) {
        Task {
            do {
                let localURL = try await FileRepositoryManager().downloadFile(fromURL: url.absoluteString)
                let ext = url.pathExtension.isEmpty
                    ? (localURL.pathExtension.isEmpty ? suffix : localURL.pathExtension)
                    : url.pathExtension
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(ext)
                do {
                    try FileManager.default.copyItem(at: localURL, to: dest)
                    completion(dest)
                } catch {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
    }
}
