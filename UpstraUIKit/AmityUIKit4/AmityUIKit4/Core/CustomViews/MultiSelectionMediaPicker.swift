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

        // Numbers the selection badges, and makes "results are in selection order" a documented
        // guarantee rather than something we rely on incidentally.
        if #available(iOS 15, *) {
            config.selection = .ordered
        }
        
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
        
        private enum PickedItem {
            case image(UIImage, identifier: String?)
            case video(url: URL, identifier: String?)
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let dispatchGroup = DispatchGroup()

            // `results` is in selection order but the loads below finish in any order, so each one
            // writes to its own slot instead of appending. Order is not cosmetic: the composer locks
            // the carousel ratio to whichever media ends up first.
            var picked = [PickedItem?](repeating: nil, count: results.count)
            let pickedLock = NSLock()

            func store(_ item: PickedItem, at index: Int) {
                pickedLock.lock()
                picked[index] = item
                pickedLock.unlock()
            }

            DispatchQueue.main.async {
                self.showLoadingOverlay(on: picker.view, message: AmityLocalizedStringSet.Social.mediaProcessing.localizedString)
            }

            for (index, result) in results.enumerated() {
                let itemProvider = result.itemProvider
                let assetIdentifier = result.assetIdentifier

                // load image from item provider
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter()
                    itemProvider.loadObject(ofClass: UIImage.self) { newImage, error in
                        defer { dispatchGroup.leave() }
                        guard error == nil, let image = newImage as? UIImage else { return }
                        store(.image(image, identifier: assetIdentifier), at: index)
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
                            store(.video(url: tempURL, identifier: assetIdentifier), at: index)
                        } catch {
                            Log.add(event: .error, "Failed to copy video: \(error)")
                        }
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.hideLoadingOverlay()

                // Compacted in slot order, so anything that failed to load drops out without
                // shifting the items around it.
                var images: [(image: UIImage, identifier: String?)] = []
                var videos: [(url: URL, identifier: String?)] = []
                for item in picked.compactMap({ $0 }) {
                    switch item {
                    case .image(let image, let identifier):
                        images.append((image: image, identifier: identifier))
                    case .video(let url, let identifier):
                        videos.append((url: url, identifier: identifier))
                    }
                }

                // Identifiers first: the components read both in one onChange, so they must be in
                // place before the image/URL arrays publish.
                if self.parent.mediaType == .images {
                    self.parent.viewModel.selectedImageIdentifiers.append(contentsOf: images.map { $0.identifier })
                    self.parent.viewModel.selectedImages.append(contentsOf: images.map { $0.image })
                } else {
                    self.parent.viewModel.selectedVideoIdentifiers.append(contentsOf: videos.map { $0.identifier })
                    self.parent.viewModel.selectedVidoesURLs.append(contentsOf: videos.map { $0.url })
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
