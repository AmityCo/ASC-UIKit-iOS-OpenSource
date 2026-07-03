//
//  MessageCameraPickerView.swift
//  AmityUIKit4
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - Camera selection payload

enum MessageCameraMediaKind {
    case image
    case video
}

struct MessageCameraSelection {
    let url: URL
    let kind: MessageCameraMediaKind
}

// MARK: - UIImagePickerController wrapper

struct MessageCameraPickerView: UIViewControllerRepresentable {
    /// Called once with the captured payload, or `nil` if the user cancelled.
    let onCaptured: (MessageCameraSelection?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCaptured: onCaptured) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCaptured: (MessageCameraSelection?) -> Void
        init(onCaptured: @escaping (MessageCameraSelection?) -> Void) { self.onCaptured = onCaptured }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)

            if let videoURL = info[.mediaURL] as? URL {
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(videoURL.pathExtension.isEmpty ? "mov" : videoURL.pathExtension)
                try? FileManager.default.copyItem(at: videoURL, to: dest)
                onCaptured(MessageCameraSelection(url: dest, kind: .video))
                return
            }

            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.9) {
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                do {
                    try data.write(to: dest)
                    onCaptured(MessageCameraSelection(url: dest, kind: .image))
                } catch {
                    onCaptured(nil)
                }
                return
            }

            onCaptured(nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCaptured(nil)
        }
    }
}

// MARK: - Permission helper

enum MessageCameraPermission {
    static func request(_ completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}
