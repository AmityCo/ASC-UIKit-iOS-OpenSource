//
//  AmityDetailedMediaAttachmentComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/6/24.
//

import SwiftUI
import AVKit
import Combine
import PhotosUI

#warning ("FIX ME: Refactor and share the same code base between AmityMediaAttatchmentComponent and AmityDetailMediaAttatchmentComponent")
public struct AmityDetailedMediaAttachmentComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .detailedMediaAttachment
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showMaximumMediaAlert: Bool = false
    @State private var showCamera: (isShown: Bool, type: [UTType], source: UIImagePickerController.SourceType) = (false, [], .photoLibrary)
    @State private var showMediaPicker: (isShown: Bool, type: PHPickerFilter, source: UIImagePickerController.SourceType) = (false, .images, .photoLibrary)
    @StateObject private var pickerViewModel = ImageVideoPickerViewModel()
    @ObservedObject private var viewModel: AmityMediaAttachmentViewModel
    @State private var attachedMediaType: AmityMediaType = .none
    @State private var currentType: AmityMediaType? = nil

    public init(viewModel: AmityMediaAttachmentViewModel, pageId: PageId? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .detailedMediaAttachment))
    }
    
    public var body: some View {
        VStack(spacing: 28) {
            let cameraButtonIcon = viewConfig.getConfig(elementId: .cameraButton, key: "image", of: String.self) ?? ""
            let cameraButtonTitle = viewConfig.getConfig(elementId: .cameraButton, key: "text", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: cameraButtonIcon),
                        title: cameraButtonTitle,
                        isHidden: false) {
                if let currentType =  viewModel.medias.first?.type {
                    showCamera.type = currentType == .image ? [UTType.image] : [UTType.movie]
                } else {
                    showCamera.type = [UTType.image, UTType.movie]
                }
                
                showCamera.source = .camera
                showCamera.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .cameraButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.cameraButton)
                        
            
            let imageButtonIcon = viewConfig.getConfig(elementId: .imageButton, key: "image", of: String.self) ?? ""
            let imageButtonTitle = viewConfig.getConfig(elementId: .imageButton, key: "text", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: imageButtonIcon),
                        title: imageButtonTitle,
                        isHidden: viewModel.medias.first?.type ?? .image != .image) {
                showMediaPicker.type = .images
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .imageButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.imageButton)
            
            let videoButtonIcon = viewConfig.getConfig(elementId: .videoButton, key: "image", of: String.self) ?? ""
            let videoButtonTitle = viewConfig.getConfig(elementId: .videoButton, key: "text", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: videoButtonIcon),
                        title: videoButtonTitle,
                        isHidden: viewModel.medias.first?.type ?? .video != .video) {
                showMediaPicker.type = .videos
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .videoButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.videoButton)
            
//            getItemView(image: AmityIcon.attatchmentIcon.getImageResource(),
//                        title: "Attatchment",
//                        isDisable: false) {}
        }
        .onChange(of: pickerViewModel) { _ in
                        
            guard viewModel.medias.count <= 10 else {
                Log.add(event: .error, "Media item count limit reached.")
                pickerViewModel.selectedMedia = nil
                pickerViewModel.selectedImage = nil
                pickerViewModel.selectedMediaURL = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMaximumMediaAlert.toggle()
                }
                
                return
            }
            currentType = viewModel.medias.first?.type
            
            // Camera mode
            if let selectedMedia = pickerViewModel.selectedMedia, let url = pickerViewModel.selectedMediaURL {
                let mediaType: AmityMediaType = selectedMedia == UTType.image.identifier ? .image : .video
                var media = AmityMedia(state: .localURL(url: url), type: mediaType)
                media.localUrl = url
                viewModel.medias.append(media)
            }
            
            if !pickerViewModel.selectedImages.isEmpty {
                for image in pickerViewModel.selectedImages {
                    let media = AmityMedia(state: .image(image), type: .image)
                    media.localUIImage = image
                    viewModel.medias.append(media)
                }
            }
            
            if !pickerViewModel.selectedVidoesURLs.isEmpty {
                for url in pickerViewModel.selectedVidoesURLs {
                    let media = AmityMedia(state: .localURL(url: url), type: .video)
                    media.localUrl = url
                    viewModel.medias.append(media)
                }
            }
            
            pickerViewModel.selectedMedia = nil
            pickerViewModel.selectedVidoesURLs = []
            pickerViewModel.selectedImages = []
            pickerViewModel.selectedImage = nil
            pickerViewModel.selectedMediaURL = nil
        }
        .alert(isPresented: $showMaximumMediaAlert) {
            let typeString = currentType == .image ? "images" : "videoes"
            return Alert(title: Text("Maximum upload limit reached"), message: Text("You’ve reached the upload limit of 10 \(typeString). Any additional \(typeString) will not be saved."), dismissButton: .cancel(Text("Close")))
        }
        .fullScreenCover(isPresented: $showCamera.isShown) {
            ImageVideoCameraPicker(viewModel: pickerViewModel, mediaType: $showCamera.type, sourceType: $showCamera.source)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showMediaPicker.isShown) {
            MultiSelectionMediaPicker(viewModel: pickerViewModel, mediaType: $showMediaPicker.type, sourceType: $showMediaPicker.source, selectionLimit: 10 - viewModel.medias.count)
                .ignoresSafeArea()
        }
        .padding(.bottom, 10)
        .padding(.top, 10)
        .background(Color(viewConfig.theme.backgroundColor))
        .ignoresSafeArea()
    }
    
    
    @ViewBuilder
    private func getItemView(image: ImageResource, title: String, isHidden: Bool, onTapAction: @escaping () -> Void) -> some View {
        let isDisable = viewModel.medias.count >= 10
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.defaultLightTheme.baseColorShade4))
                .frame(width: 32, height: 32)
                .overlay (
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(isDisable ? Color(viewConfig.theme.baseColorShade3) : nil)
                        .frame(width: 20, height: 20)
                )
                .clipShape(Circle())
            
            Text(title)
                .foregroundColor(isDisable ? .gray : Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.leading, 25)
        .onTapGesture {
            onTapAction()
        }
        .disabled(isDisable)
        .isHidden(isHidden, remove: true)
    }
}
