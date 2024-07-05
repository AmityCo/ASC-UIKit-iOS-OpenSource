//
//  MultiSelectionMediaPicker.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 27/6/2567 BE.
//

import Foundation
import SwiftUI
import PhotosUI

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
        
        init(_ parent: MultiSelectionMediaPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            let identifiers = results.compactMap(\.assetIdentifier)
            
            
            
            for result in results {
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] newImage, error in
                        if let error = error {
                        } else if let image = newImage as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.viewModel.selectedImages.append(image)
                            }
                        }
                    }
                } else {
                    
                    guard let assetId = result.assetIdentifier else { continue }
                    
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                    guard let asset = fetchResult.firstObject else { continue }
                    
                    if asset.mediaType == .video {
                        
                        let options = PHVideoRequestOptions()
                        options.version = .original
                        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                            if let urlAsset = avAsset as? AVURLAsset {
                                let fileUrl = urlAsset.url
                                DispatchQueue.main.async {
                                    self.parent.viewModel.selectedVidoesURLs.append(fileUrl)
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
}
