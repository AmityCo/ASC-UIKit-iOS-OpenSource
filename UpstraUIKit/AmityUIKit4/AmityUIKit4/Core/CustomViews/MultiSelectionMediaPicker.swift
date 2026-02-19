//
//  MultiSelectionMediaPicker.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 27/6/2567 BE.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MultiSelectionMediaPicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var viewModel: ImageVideoPickerViewModel
    @Binding private var mediaType: PHPickerFilter
    @Binding private var sourceType: UIImagePickerController.SourceType
    
    let selectionLimit: Int
    
    init(viewModel: ImageVideoPickerViewModel, mediaType: Binding<PHPickerFilter>, sourceType: Binding<UIImagePickerController.SourceType>, selectionLimit: Int) {
        self.viewModel = viewModel
        self._mediaType = mediaType
        self._sourceType = sourceType
        self.selectionLimit = selectionLimit
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MultiSelectionMediaPicker>) -> UIViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = mediaType
        config.selectionLimit = selectionLimit
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MultiSelectionMediaPicker>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: MultiSelectionMediaPicker
        var loadingOverlay: LoadingOverlayView?
        
        init(_ parent: MultiSelectionMediaPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let dispatchGroup = DispatchGroup()
            var images: [UIImage] = []
            var videos: [URL] = []
            
            DispatchQueue.main.async {
                self.showLoadingOverlay(on: picker.view, message: "Processing media...")
            }
            
            for result in results {
                let itemProvider = result.itemProvider

                // load image from item provider
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter()
                    itemProvider.loadObject(ofClass: UIImage.self) { newImage, error in
                        defer { dispatchGroup.leave() }
                        guard error == nil, let image = newImage as? UIImage else { return }
                        images.append(image)
                    }
                } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    // Load video directly from item provider (works with limited photo access)
                    dispatchGroup.enter()
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        defer { dispatchGroup.leave() }
                        guard error == nil, let url = url else { return }

                        // Copy to temporary location since the provided URL is temporary
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension(url.pathExtension)
                        do {
                            try FileManager.default.copyItem(at: url, to: tempURL)
                            videos.append(tempURL)
                        } catch {
                            Log.add(event: .error, "Failed to copy video: \(error)")
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.hideLoadingOverlay()
                
                if self.parent.mediaType == .images {
                    self.parent.viewModel.selectedImages.append(contentsOf: images)
                } else {
                    self.parent.viewModel.selectedVidoesURLs.append(contentsOf: videos)
                }
                
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        private func showLoadingOverlay(on view: UIView, message: String) {
            loadingOverlay = LoadingOverlayView(message: message)
            guard let overlay = loadingOverlay else { return }
            
            view.addSubview(overlay)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: view.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        private func hideLoadingOverlay() {
            loadingOverlay?.removeFromSuperview()
            loadingOverlay = nil
        }
    }
}


class LoadingOverlayView: UIView {
    private let containerView: UIView
    private let activityIndicator: UIActivityIndicatorView
    private let messageLabel: UILabel

    init(message: String) {
        containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 10
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        
        messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        super.init(frame: .zero)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        addSubview(containerView)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(messageLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        activityIndicator.startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
