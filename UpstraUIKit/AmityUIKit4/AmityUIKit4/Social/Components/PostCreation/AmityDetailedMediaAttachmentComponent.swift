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

    private let onProductTagTap: (() -> Void)?

    public init(viewModel: AmityMediaAttachmentViewModel, pageId: PageId? = nil, onProductTagTap: (() -> Void)? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self.onProductTagTap = onProductTagTap
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .detailedMediaAttachment))
    }
    
    public var body: some View {
        VStack(spacing: 28) {
            let cameraButtonIcon = viewConfig.getConfig(elementId: .cameraButton, key: "image", of: String.self) ?? ""
            let cameraButtonTitle = viewConfig.getConfig(elementId: .cameraButton, key: "text", of: String.self) ?? AmityLocalizedStringSet.Social.cameraButton.localizedString
            getItemView(image: AmityIcon.getImageResource(named: cameraButtonIcon),
                        title: cameraButtonTitle,
                        isHidden: false) {
                if let currentType =  viewModel.medias.first?.type {
                    showCamera.type = currentType == .image ? [UTType.image] : [UTType.movie]
                } else {
                    showCamera.type = [UTType.image, UTType.movie]
                }
                
                pickerViewModel.reset()
                
                showCamera.source = .camera
                showCamera.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .cameraButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.cameraButton)
                        
            let imageButtonIcon = viewConfig.getConfig(elementId: .imageButton, key: "image", of: String.self) ?? ""
            let imageButtonTitle = viewConfig.getConfig(elementId: .imageButton, key: "text", of: String.self) ?? AmityLocalizedStringSet.Social.photoButton.localizedString
            getItemView(image: AmityIcon.getImageResource(named: imageButtonIcon),
                        title: imageButtonTitle,
                        isHidden: viewModel.medias.first?.type ?? .image != .image) {
                
                pickerViewModel.reset()
                
                showMediaPicker.type = .images
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .imageButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.imageButton)
            
            let videoButtonIcon = viewConfig.getConfig(elementId: .videoButton, key: "image", of: String.self) ?? ""
            let videoButtonTitle = viewConfig.getConfig(elementId: .videoButton, key: "text", of: String.self) ?? AmityLocalizedStringSet.Social.videoButton.localizedString
            getItemView(image: AmityIcon.getImageResource(named: videoButtonIcon),
                        title: videoButtonTitle,
                        isHidden: viewModel.medias.first?.type ?? .video != .video) {
                
                pickerViewModel.reset()
                
                showMediaPicker.type = .videos
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .videoButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.videoButton)

            if productTagCount > 0 {
                tagProductsRow
            }
        }
        .onChange(of: pickerViewModel) { _ in
            
            // Note:
            // This onChange(of: pickerViewModel) is being called multiple times
            // leading to app freeze issue.
            guard pickerViewModel.haveSelection else {
                return
            }
                                    
            guard viewModel.medias.count <= PostMediaCap.maximum else {
                Log.add(event: .error, "Media item count limit reached.")
                pickerViewModel.reset()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMaximumMediaAlert.toggle()
                }
                
                return
            }
            currentType = viewModel.medias.first?.type
            
            // Camera mode
            if let selectedMedia = pickerViewModel.selectedMedia, let url = pickerViewModel.selectedMediaURL {
                let mediaType: AmityMediaType = selectedMedia == UTType.image.identifier ? .image : .video
                let media = AmityMedia(state: .localURL(url: url), type: mediaType)
                media.localUrl = url
                viewModel.medias.append(media)
            }
            
            let attachedIdentifiers = Set(viewModel.medias.compactMap { $0.assetIdentifier })

            if !pickerViewModel.selectedImages.isEmpty {
                for (offset, image) in pickerViewModel.selectedImages.enumerated() {
                    let identifier = pickerViewModel.selectedImageIdentifiers.indices.contains(offset)
                        ? pickerViewModel.selectedImageIdentifiers[offset]
                        : nil

                    // Re-selecting an already-attached item is skipped silently: no error, no toast.
                    if let identifier, attachedIdentifiers.contains(identifier) { continue }

                    let media = AmityMedia(state: .image(image), type: .image)
                    media.localUIImage = image
                    media.assetIdentifier = identifier
                    viewModel.medias.append(media)
                }
            }
            
            if !pickerViewModel.selectedVidoesURLs.isEmpty {
                for (offset, url) in pickerViewModel.selectedVidoesURLs.enumerated() {
                    let identifier = pickerViewModel.selectedVideoIdentifiers.indices.contains(offset)
                        ? pickerViewModel.selectedVideoIdentifiers[offset]
                        : nil

                    if let identifier, attachedIdentifiers.contains(identifier) { continue }

                    let media = AmityMedia(state: .localURL(url: url), type: .video)
                    media.localUrl = url
                    media.assetIdentifier = identifier
                    viewModel.medias.append(media)
                }
            }
            
            pickerViewModel.reset()
        }
        .alert(isPresented: $showMaximumMediaAlert) {
            let typeString = currentType == .image ? "images" : "videoes"
            return Alert(title: Text(AmityLocalizedStringSet.Social.maxUploadLimitTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.maxUploadLimitMessage.localized(arguments: typeString, typeString)), dismissButton: .cancel(Text("Close")))
        }
        .fullScreenCover(isPresented: $showCamera.isShown) {
            ImageVideoCameraPicker(viewModel: pickerViewModel, mediaType: $showCamera.type, sourceType: $showCamera.source)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showMediaPicker.isShown) {
            MultiSelectionMediaPicker(viewModel: pickerViewModel, mediaType: $showMediaPicker.type, sourceType: $showMediaPicker.source, selectionLimit: PostMediaCap.maximum - viewModel.medias.count)
                .ignoresSafeArea()
        }
        .padding(.bottom, 10)
        .padding(.top, 10)
        .background(Color(viewConfig.theme.backgroundColor))
        .ignoresSafeArea()
    }
    
    
    /// The only row with a trailing count and chevron; Camera, Photo and Video are icon + label only.
    /// The file row does not exist in v4 and is not rendered.
    @ViewBuilder
    private var tagProductsRow: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.backgroundShade1Color))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(AmityIcon.LiveStream.emptyProductTaggingIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                )
                .clipShape(Circle())

            Text(AmityLocalizedStringSet.Social.tagProductsRow.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))

            Spacer()

            HStack(spacing: 8) {
                if productTagCount > 0 {
                    Text("\(productTagCount)")
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                }

                Image(AmityIcon.arrowIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .onTapGesture { onProductTagTap?() }
    }

    private var productTagCount: Int {
        viewModel.medias.reduce(0) { $0 + $1.produtTags.count }
    }

    @ViewBuilder
    private func getItemView(image: ImageResource, title: String, isHidden: Bool, onTapAction: @escaping () -> Void) -> some View {
        let isDisable = viewModel.medias.count >= PostMediaCap.maximum
        let currentThemeStyle = AmityUIKitConfigController.shared.getCurrentThemeStyle()
        let imageTint = currentThemeStyle == .light ? viewConfig.theme.baseColor : UIColor.white
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.backgroundShade1Color))
                .frame(width: 32, height: 32)
                .overlay (
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(isDisable ? Color(viewConfig.theme.baseColorShade3) : Color(imageTint))
                        .frame(width: 24, height: 24)
                )
                .clipShape(Circle())
            
            Text(title)
                .applyTextStyle(.bodyBold(isDisable ? Color(viewConfig.theme.baseColorShade3) : Color(viewConfig.theme.baseColor)))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 16)
        .disabled(isDisable) 
        .onTapGesture {
            if !isDisable {  
                onTapAction()
            }
        }
        .isHidden(isHidden, remove: true)
    }
}
