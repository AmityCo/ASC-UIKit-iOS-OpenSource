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

    private let onProductTagTap: (() -> Void)?

    public init(viewModel: AmityMediaAttachmentViewModel, pageId: PageId? = nil, onProductTagTap: (() -> Void)? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self.onProductTagTap = onProductTagTap
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .mediaAttachment))
    }
    
    
    public var body: some View {
        HStack(spacing: 56) {
            let cameraButtonIcon = viewConfig.getConfig(elementId: .cameraButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: cameraButtonIcon), isHidden: false) {
                // Read live rather than from `currentType`, which is only refreshed on the next pass
                // and would let the camera offer video for an image post.
                if let currentType = viewModel.medias.first?.type {
                    showCamera.type = currentType == .image ? [UTType.image] : [UTType.movie]
                } else {
                    showCamera.type = [UTType.image, UTType.movie]
                }

                pickerViewModel.reset()

                showCamera.source = .camera
                showCamera.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .cameraButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.cameraButton)

            let imageButtonIcon = viewConfig.getConfig(elementId: .imageButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: imageButtonIcon), isHidden: viewModel.medias.first?.type ?? .image != .image) {
                pickerViewModel.reset()

                showMediaPicker.type = .images
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .imageButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.imageButton)

            let videoButtonIcon = viewConfig.getConfig(elementId: .videoButton, key: "image", of: String.self) ?? ""
            getItemView(image: AmityIcon.getImageResource(named: videoButtonIcon), isHidden: viewModel.medias.first?.type ?? .video != .video) {
                pickerViewModel.reset()

                showMediaPicker.type = .videos
                showMediaPicker.source = .photoLibrary
                showMediaPicker.isShown.toggle()
                hideKeyboard()
            }
            .isHidden(viewConfig.isHidden(elementId: .videoButton))
            .accessibilityIdentifier(AccessibilityID.Social.MediaAttachment.videoButton)

            if productTagCount > 0 {
                productTagItem
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
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
            
            // Must clear the identifier arrays too — they are read by position against the image/URL
            // arrays, so clearing only one side leaves every later pick reading the first pick's id.
            pickerViewModel.reset()
        }
        .onAppear {
            currentType = viewModel.medias.first?.type
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
    }
    
    
    /// Counts tags on the frames only. `postComposerViewModel.productTags` also carries tags parsed
    /// from body text, which would make this disagree with the frames it sits under.
    private var productTagCount: Int {
        viewModel.medias.reduce(0) { $0 + $1.produtTags.count }
    }

    @ViewBuilder
    private var productTagItem: some View {
        getItemView(image: AmityIcon.LiveStream.emptyProductTaggingIcon.imageResource, isHidden: false, glyphSize: 28) {
            onProductTagTap?()
        }
        .overlay(
            Text("\(productTagCount)")
                .applyTextStyle(.body(.white))
                .padding(.horizontal, 6)
                .frame(minWidth: 22, minHeight: 22)
                .background(Capsule().fill(Color(viewConfig.theme.baseColor)))
                .offset(x: 8, y: -8),
            alignment: .topTrailing
        )
    }

    @ViewBuilder
    /// `glyphSize` defaults to the media icons' 24. The tag asset is drawn on a 48pt canvas with only
    /// 66% ink, so it needs a larger frame to carry the same visual weight.
    private func getItemView(image: ImageResource, isHidden: Bool, glyphSize: CGFloat = 24, onTapAction: @escaping () -> Void) -> some View {
        let isDisable = viewModel.medias.count >= PostMediaCap.maximum
        let currentThemeStyle = AmityUIKitConfigController.shared.getCurrentThemeStyle()
        let imageTint = currentThemeStyle == .light ? viewConfig.theme.baseColor : UIColor.white
        Rectangle()
            .fill(Color(viewConfig.theme.backgroundShade1Color))
            .frame(width: 32, height: 32)
            .overlay (
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(isDisable ? Color(viewConfig.theme.baseColorShade3) : Color(imageTint))
                    .frame(width: glyphSize, height: glyphSize)
            )
            .clipShape(Circle())
            .contentShape(Rectangle())
            .disabled(isDisable) 
            .onTapGesture {
                if !isDisable {  
                    onTapAction()
                }
            }
            .isHidden(isHidden, remove: true)
    }
}
