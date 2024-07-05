//
//  ImageVideoPicker.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/19/23.
//

import SwiftUI
import AVKit

struct ImageVideoPicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var viewModel: ImageVideoPickerViewModel
    private let mediaType: [UTType]
    
    init(viewModel: ImageVideoPickerViewModel, mediaType: [UTType] = [UTType.image, UTType.movie]) {
        self.viewModel = viewModel
        self.mediaType = mediaType
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageVideoPicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = context.coordinator
        imagePicker.mediaTypes = mediaType.map { $0.identifier }
        imagePicker.videoQuality = .typeHigh
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImageVideoPicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImageVideoPicker
        
        init(_ parent: ImageVideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            if let mediaType = info[.mediaType] as? String {
                switch mediaType {
                case UTType.image.identifier:
                    
                    if let url = info[.imageURL] as? URL,
                       let image = info[.originalImage] as? UIImage {
                        parent.viewModel.selectedMedia = UTType.image.identifier
                        parent.viewModel.selectedImage = image
                        parent.viewModel.selectedMediaURL = url
                        parent.presentationMode.wrappedValue.dismiss()
                    }
                    
                case UTType.movie.identifier:
                    if let url = info[.mediaURL] as? URL {
                        parent.viewModel.selectedMedia = UTType.movie.identifier
                        parent.viewModel.selectedMediaURL = url
                        parent.presentationMode.wrappedValue.dismiss()
                    }
                default:
                    break
                }
            }
            
        }
        
    }
}

class ImageVideoPickerViewModel: ObservableObject, Identifiable, Equatable {
    
    var id: String {
        UUID().uuidString
    }
    
    @Published var selectedMedia: String? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var selectedMediaURL: URL? = nil
    @Published var selectedVidoesURLs: [URL] = []
    @Published var selectedImages: [UIImage] = []

    static func == (lhs: ImageVideoPickerViewModel, rhs: ImageVideoPickerViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
}

