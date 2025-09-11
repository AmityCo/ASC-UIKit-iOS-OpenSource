//
//  PollImageOptionSection.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/7/25.
//

import SwiftUI
import PhotosUI
import AmitySDK

struct PollImageOptionSection: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @ObservedObject var viewModel: PollPostComposerViewModel
    
    var canAddMoreOption: Bool {
        return viewModel.imageOptions.count < 10
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            PollSectionHeader(title: "Options", description: "Poll must contain at least 2 options, and an image must be uploaded for every option.")
                .padding(.bottom, 20)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(viewModel.imageOptions.enumerated()), id: \.element.id) { index, option in
                    PollImageOptionView(option: option, viewModel: viewModel, index: index)
                }
                
                if canAddMoreOption {
                    addOptionView
                }
            }
        }
    }
    
    var addOptionView: some View {
        Button(action: {
            guard canAddMoreOption else { return }
            
            withAnimation {
                viewModel.addImageOption()
            }
        }) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .overlay(
                    VStack(spacing: 2) {
                        Image(AmityIcon.plusIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                        
                        Text("Add option")
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                            .padding(.horizontal)
                    }
                )
                .contentShape(Rectangle())
                .padding(8)
                .frame(height: 184)
                .cornerRadius(8)
                .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
        }
        .buttonStyle(.plain)
    }
}

struct PollImageOptionView: View {
    
    @EnvironmentObject
    private var host: AmitySwiftUIHostWrapper
    
    @EnvironmentObject
    private var viewConfig: AmityViewConfigController
    
    @State
    var option: PollImageOption
    
    @ObservedObject
    var viewModel: PollPostComposerViewModel
    
    let index: Int
    
    @State private var showImagePicker = false
    @StateObject
    private var imagePickerViewModel = ImageVideoPickerViewModel()
    
    @State private var text: String = ""
    @State private var optionState: PollImageOptionState = .empty
    @State private var uploadProgress: Double = 0
    @State private var imageData: AmityImageData?
    
    var isImageUploaded: Bool {
        return optionState == .uploaded
    }
    
    let maxTextCharLimit = 20
    
    @State private var showRetryActionSheet = false
    
    @ViewBuilder
    var imageContainer: some View {
        let shouldShowStroke = optionState == .empty || optionState == .error
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color(viewConfig.theme.baseColorShade4), style: StrokeStyle(lineWidth: shouldShowStroke ? 1 : 0, dash: [4,4]))
            .frame(height: 108)
            .background(Color(viewConfig.theme.backgroundShade1Color))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Image container
                imageContainer
                    .overlay(
                        ZStack(alignment: .top) {
                            if let image = option.image {
                                GeometryReader { geometry in
                                    ZStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: 108)
                                            .clipped(antialiased: true)
                                        
                                        VStack(alignment: .leading, spacing: 0) {
                                            Spacer()
                                            
                                            HStack(spacing: 0) {
                                                HStack(spacing: 4) {
                                                    
                                                    Text("ALT")
                                                        .applyTextStyle(.captionBold(.white))
                                                        .padding(.leading, 8)
                                                        .padding(.vertical, style: .spacingXS)
                                                    
                                                    if let altText = option.altText, !altText.isEmpty {
                                                        Image(AmityIcon.checkMarkIcon.getImageResource())
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 16, height: 12)
                                                    }
                                                }
                                                .padding(.trailing, 8)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Capsule())
                                                
                                                Spacer()
                                            }
                                            .padding(.leading, 8)
                                            .padding(.bottom, 8)
                                            .onTapGesture {
                                                openAltTextScreen()
                                            }
                                            .opacity(isImageUploaded ? 1 : 0)
                                        }
                                    }
                                    .frame(width: geometry.size.width, height: 108)
                                }
                                
                            } else {
                                VStack(spacing: 8) {
                                    Image(AmityIcon.clipThumbnailIcon.imageResource)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                                    
                                    Text("Upload image")
                                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                                }
                            }
                        }
                        .frame(height: 108)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    )
                    .frame(height: 108)
                    .mask(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture {
                        showImagePicker = true
                    }
                
                // Upload progress overlay
                if case .uploading = optionState {
                    ZStack {
                        Color.black.opacity(0.5)
                            .cornerRadius(8)
                        
                        LiveStreamCircularProgressBar(progress: $uploadProgress, config: .init(backgroundColor: .white, foregroundColor: viewConfig.theme.primaryColor, strokeWidth: 2, shouldAutoRotate: true))
                            .frame(width: 20, height: 20)
                    }
                    .frame(height: 108)
                }
                
                // Error indicator
                if case .error = optionState {
                    ZStack {
                        Color.black.opacity(0.3)
                            .cornerRadius(8)
                        
                        Image(AmityIcon.mediaUploadErrorIcon.imageResource)
                            .renderingMode(.template)
                            .foregroundColor(.white)
                    }
                    .frame(height: 108)
                    .onTapGesture {
                        self.showRetryActionSheet = true
                    }
                    .actionSheet(isPresented: $showRetryActionSheet) {
                        ActionSheet(title: Text("Your image couldn’t be uploaded"), buttons: [
                            .default(Text("Retry"), action: {
                                if let image = option.image {
                                    uploadImage(image: image)
                                }
                            }),
                            .default(Text("Upload new image"), action: {
                                showImagePicker = true
                            }),
                            .cancel()
                        ])
                    }
                }
            }
            
            // Text input
            TextField("", text: $text)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                .placeholder(when: text.isEmpty, placeholder: {
                    Text("Option \(index + 1)")
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                })
                .frame(height: 40)
                .padding(.horizontal, 12)
                .background(Color(viewConfig.theme.baseColorShade4))
                .cornerRadius(8)
                .onChange(of: text) { newValue in
                    if newValue.count > maxTextCharLimit {
                        let finalText = String(newValue.prefix(maxTextCharLimit))
                        text = finalText
                    }
                    
                    viewModel.updateText(for: option, text: newValue)
                }
        }
        .padding(12)
        .frame(height: 184)
        .cornerRadius(8)
        .border(radius: 8, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
        .overlay(
            closeButton
        )
        .sheet(isPresented: $showImagePicker) {
            ImageVideoPicker(
                viewModel: imagePickerViewModel,
                mediaType: [UTType.image]
            )
        }
        .onChange(of: imagePickerViewModel.selectedImage) { newImage in
            if let image = newImage {
                option.image = image
                uploadImage(image: image)
                
                // Reset the picker view model for next use
                imagePickerViewModel.reset()
            }
        }
    }
    
    var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        viewModel.removeImageOption(at: index)
                    }
                }) {
                    Image(AmityIcon.closeIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .offset(x: 6, y: -6)
            }
            
            Spacer()
        }
    }
    
    func uploadImage(image: UIImage) {
        switch optionState {
        case .uploading:
            break
        default:
            self.optionState = .uploading
            self.viewModel.updateUploadState(for: option, state: .uploading, imageData: nil)

            Task { @MainActor in
                do {
                    let imageData = try await viewModel.fileRepository.uploadImage(image) { progress in
                        self.uploadProgress = progress * 100
                    }
                    
                    Log.add(event: .info, "Image Uploaded: \(imageData.fileId)")

                    // Update view model
                    viewModel.updateUploadState(for: option, state: .uploaded, imageData: imageData)

                    // Update state
                    self.uploadProgress = 100
                    self.optionState = .uploaded
                    self.option.imageData = imageData
                    self.imageData = imageData
                    
                } catch let error {
                    self.optionState = .error
                    self.uploadProgress = 0
                    viewModel.updateUploadState(for: option, state: .error, imageData: nil)

                    Log.add(event: .info, "Error while uploading image \(error.localizedDescription)")
                }
            }
        }
    }
    
    func openAltTextScreen() {
        guard let imageData else { return }
        
        let configMode: AltTextConfigMode
        
        if let altText = option.altText, !altText.isEmpty {
            configMode = .edit(altText, .image(imageData))
        } else {
            configMode = .create(.image(imageData))
        }
        
        let component = AmityAltTextConfigComponent(mode: configMode) { altText in
            option.altText = altText
            viewModel.updateAltText(for: option, text: altText)
        }
        let vc = AmitySwiftUIHostingController(rootView: component)
        host.controller?.present(vc, animated: true)
    }
}

enum PollImageOptionState: String {
    case empty
    case uploading
    case uploaded
    case error
}

struct PollImageOption: Identifiable, Equatable {
    
    let id = UUID()
    var text: String = ""
    var image: UIImage?
    var uploadState: PollImageOptionState = .empty
    var imageData: AmityImageData?
    var altText: String?
    
    static func == (lhs: PollImageOption, rhs: PollImageOption) -> Bool {
        return lhs.id == rhs.id && lhs.text == rhs.text && lhs.image == rhs.image && lhs.uploadState == rhs.uploadState && lhs.altText == rhs.altText
    }
}
