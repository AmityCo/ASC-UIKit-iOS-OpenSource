//
//  AmityMediaAttachmentComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/6/24.
//

import SwiftUI
import AVKit
import PhotosUI

#warning ("FIX ME: Refactor and share the same code base between AmityMediaAttatchmentComponent and AmityDetailMediaAttatchmentComponent")
public struct AmityMediaAttachmentComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .mediaAttachment
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
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .mediaAttachment))
    }
    
    
    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
        
            Spacer()
                .isHidden(currentType == nil, remove: true)
             
            let cameraButtonIcon = viewConfig.getConfig(elementId: .cameraButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: cameraButtonIcon), isHidden: false) {
                if let currentType = currentType {
                    showCamera.type = currentType == .image ? [UTType.image] : [UTType.movie]
                } else {
                    showCamera.type = [UTType.image, UTType.movie]
                }
                
                showCamera.source = .camera
                showCamera.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .cameraButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.cameraButton)

            Spacer()
                .isHidden(currentType == .video, remove: true)
            
            let imageButtonIcon = viewConfig.getConfig(elementId: .imageButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: imageButtonIcon), isHidden: viewModel.medias.first?.type ?? .image != .image) {
                showMediaPicker.type = .images
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .imageButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.imageButton)
            
            Spacer()
                .isHidden(currentType == .image, remove: true)
            
            let videoButtonIcon = viewConfig.getConfig(elementId: .videoButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: videoButtonIcon), isHidden: viewModel.medias.first?.type ?? .video != .video) {
                showMediaPicker.type = .videos
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .videoButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.videoButton)
            
            Spacer()
                .isHidden(currentType == nil, remove: true)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
        .padding([.leading, .trailing], 25)
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
        .onAppear {
            currentType = viewModel.medias.first?.type
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
    }
    
    
    @ViewBuilder
    private func getItemView(image: ImageResource, isHidden: Bool, onTapAction: @escaping () -> Void) -> some View {
        let isDisable = viewModel.medias.count >= 10
        Rectangle()
            .fill(Color(viewConfig.defaultLightTheme.baseColorShade4))
            .frame(width: 32, height: 32)
            .overlay (
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(isDisable ? Color(viewConfig.theme.baseColor) : nil)
                    .frame(width: 20, height: 20)
            )
        .clipShape(Circle())
        .contentShape(Rectangle())
        .onTapGesture {
            onTapAction()
        }
        .disabled(isDisable)
        .isHidden(isHidden, remove: true)
    }
}
