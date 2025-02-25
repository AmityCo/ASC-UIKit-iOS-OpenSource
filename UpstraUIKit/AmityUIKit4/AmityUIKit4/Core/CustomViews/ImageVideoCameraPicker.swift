//
//  ImageVideoCameraPicker.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/14/24.
//


import SwiftUI
import AVKit

struct ImageVideoCameraPicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var viewModel: ImageVideoPickerViewModel
    @Binding private var mediaType: [UTType]
    @Binding private var sourceType: UIImagePickerController.SourceType
    
    init(viewModel: ImageVideoPickerViewModel, mediaType: Binding<[UTType]>, sourceType: Binding<UIImagePickerController.SourceType>) {
        self.viewModel = viewModel
        self._mediaType = mediaType
        self._sourceType = sourceType
    }
   
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageVideoCameraPicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        imagePicker.mediaTypes = mediaType.map { $0.identifier }
        imagePicker.videoQuality = .typeHigh
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImageVideoCameraPicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImageVideoCameraPicker
        
        init(_ parent: ImageVideoCameraPicker) {
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
            
            
            /// Taking picture with Camera
            if let image = info[.originalImage] as? UIImage {
                let url = saveImageToDocumentsDirectory(image: image)
                parent.viewModel.selectedMedia = UTType.image.identifier
                parent.viewModel.selectedImage = image
                parent.viewModel.selectedMediaURL = url
                parent.presentationMode.wrappedValue.dismiss()
            }
            
            
        }
        
        
        // Function to save the image to the documents directory and return the URL
        func saveImageToDocumentsDirectory(image: UIImage) -> URL? {
            // Get the documents directory URL
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            // Create a unique filename
            let fileName = UUID().uuidString
            let fileURL = documentsDirectory.appendingPathComponent("\(fileName).jpg")
            
            // Save the image to the file URL
            if let data = image.jpegData(compressionQuality: 1.0) {
                do {
                    try data.write(to: fileURL)
                    return fileURL
                } catch {
                    Log.add(event: .error, "Error saving image: \(error)")
                    return nil
                }
            }
            
            return nil
        }
    }
}
