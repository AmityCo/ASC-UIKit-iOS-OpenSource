//
//  AmityDraftStoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/18/23.
//

import SwiftUI
import AVKit
import AmitySDK

public enum StoryMediaType {
    case image(URL?, UIImage?)
    case video(URL?)
}

public struct AmityDraftStoryPage: AmityPageView {
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    public var id: PageId {
        .storyCreationPage
    }
    
    @StateObject private var viewModel: AmityDraftStoryPageViewModel
    @State private var previewDisplayMode: ContentMode = .fit
    @State private var animateActivityIndicator: Bool = false
    @State private var userInteractionEnabled: Bool = true
    @State private var isAlertShown = false
    @State private var showHyperLinkSheet: Bool = false
    
    public init(targetId: String, avatar: UIImage?, mediaType: StoryMediaType) {
        self._viewModel = StateObject(wrappedValue: AmityDraftStoryPageViewModel(targetId: targetId, avatar: avatar, mediaType: mediaType))
    }
    
    public var body: some View {
        AmityView(configId: configId, config: { configDict in
            
        }) { config in
            VStack(alignment: .trailing) {
                ZStack(alignment: .topLeading) {
                    GeometryReader { geometry in
                        getPreviewView(size: geometry.size)
                            .overlay(
                                ActivityIndicatorView(isAnimating: $animateActivityIndicator, style: .medium)
                            )
                    }
                    
                    VStack(alignment: .center) {
                        HStack {
                            Button(action: {
                                isAlertShown = true
                            }, label: {
                                Image(AmityIcon.getImageResource(named: getElementConfig(elementId: .backButtonElement, key: "back_icon", of: String.self) ?? ""))
                                    .frame(width: 32, height: 32)
                                    .background(Color(UIColor(hex: getElementConfig(elementId: .backButtonElement, key: "background_color", of: String.self) ?? "")))
                                    .clipShape(.circle)
                            })
                            .buttonStyle(.plain)
                    
                            Spacer()
                            
                            if case .image = viewModel.storyMediaType {
                                Button {
                                    previewDisplayMode = previewDisplayMode == .fill ? .fit : .fill
                                } label: {
                                    Image(AmityIcon.getImageResource(named: getElementConfig(elementId: .aspectRatioButtonElement, key: "aspect_ratio_icon", of: String.self) ?? ""))
                                        .frame(width: 32, height: 32)
                                        .background(Color(UIColor(hex: getElementConfig(elementId: .aspectRatioButtonElement, key: "background_color", of: String.self) ?? "")))
                                        .clipShape(.circle)
                                }
                            }
                            
                            Button {
                                guard viewModel.hyperLinkConfigModel.url.isEmpty else {
                                    Toast.showToast(style: .warning, message: "Can’t add more than one link to your story.")
                                    return
                                }
                                showHyperLinkSheet = true
                            } label: {
                                Image(AmityIcon.getImageResource(named: getElementConfig(elementId: .hyperLinkButtonElement, key: "hyperlink_button_icon", of: String.self) ?? ""))
                                    .frame(width: 32, height: 32)
                                    .background(Color(UIColor(hex: getElementConfig(elementId: .aspectRatioButtonElement, key: "background_color", of: String.self) ?? "")))
                                    .clipShape(.circle)
                            }
                        }
                        .padding(16)
                        
                        Spacer()
                        
                        if !viewModel.hyperLinkConfigModel.url.isEmpty {
                            HStack(spacing: 0) {
                                Image(AmityIcon.getImageResource(named: getElementConfig(elementId: .hyperLinkElement, key: "hyper_link_icon", of: String.self) ?? ""))
                                    .frame(width: 20, height: 20)
                                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                                let title = viewModel.hyperLinkConfigModel.getCustomName().isEmpty ? viewModel.hyperLinkConfigModel.getDomainName() ?? "" : viewModel.hyperLinkConfigModel.getCustomName()
                                Text(title)
                                    .lineLimit(1)
                                    .font(.system(size: 15))
                                    .padding(.trailing, 16)
                            }
                            .frame(height: 40)
                            .background(Color(UIColor(hex: getElementConfig(elementId: .hyperLinkElement, key: "background_color", of: String.self) ?? "")).opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(EdgeInsets(top: 0, leading: 24, bottom: 32, trailing: 24))
                            .onTapGesture {
                                showHyperLinkSheet = true
                            }
                        }
                    }
                    
                }
                
                getShareStoryButtonView()
                    .cornerRadius(24.0)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 25, trailing: 16))
                    .onTapGesture {
                        ImpactFeedbackGenerator.impactFeedback(style: .light)
                        Task {
                            host.controller?.navigationController?.dismiss(animated: true)
                            
                            do {
                                try await viewModel.createStory(displayMode: previewDisplayMode)
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Story.createdStorySuccessfully.localizedString)
                            } catch {
                                Log.add(event: .error, "StoryCreation: Failed - Error \(error)")
                                Toast.showToast(style: .warning, message: error.localizedDescription)
                            }
                        }
                    }
                
            }
        }
        .bottomSheet(isPresented: $showHyperLinkSheet, height: .infinity, animation: .easeInOut(duration: 0.25), content: {
            AmityHyperLinkConfigComponent(isPresented: $showHyperLinkSheet, data: $viewModel.hyperLinkConfigModel)
        })
        .alert(isPresented: $isAlertShown, content: {
            Alert(title: Text("Discard this story?"), message: Text("The story will be permanently deleted. It cannot be undone."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Discard"), action: {
                host.controller?.navigationController?.popViewController(animated: true)
            }))
        })
        .allowsHitTesting(userInteractionEnabled)
        .ignoresSafeArea(.keyboard)
        .background(Color.black.ignoresSafeArea())
    }
    
    @State private var playVideo: Bool = false
    
    @ViewBuilder
    func getPreviewView(size: CGSize) -> some View {
        
        switch viewModel.storyMediaType {
        case .image(_, let image):
            if let image {
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: previewDisplayMode)
                    .frame(width: size.width, height: size.height)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: image.averageGradientColor ?? [.black]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14.0)
            }
        case .video(let url):
            if let url {
                VideoPlayer(url: url, play: $playVideo)
                    .autoReplay(true)
                    .contentMode(.scaleToFill)
                    .allowsHitTesting(false)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(14.0)
                    .onAppear {
                        playVideo.toggle()
                    }
                    .onDisappear {
                        playVideo.toggle()
                    }
            }
            
        }
    }
    
    @ViewBuilder
    func getShareStoryButtonView() -> some View {
        let shareIcon = AmityIcon.getImageResource(named: getElementConfig(elementId: .shareStoryButtonElement, key: "share_icon", of: String.self) ?? "")
        let hideAvatar = getElementConfig(elementId: .shareStoryButtonElement, key: "hide_avatar", of: Bool.self) ?? false
        let backgroundColor = Color(UIColor(hex: getElementConfig(elementId: .shareStoryButtonElement, key: "background_color", of: String.self) ?? ""))
        
        HStack(spacing: 8) {
            if !hideAvatar {
                Image(uiImage: viewModel.avatar ?? AmityIcon.defaultCommunity.getImage()!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .background(Color.yellow)
                    .clipShape(Circle())
                    .padding(.leading, 4)
            }
            
            Text("Share Story")
                .font(Font.system(size: 14))
                .fontWeight(.medium)
            
            Image(shareIcon)
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
        }
        .frame(height: 40)
        .background(backgroundColor)
    }
}

class AmityDraftStoryPageViewModel: ObservableObject {
    var storyMediaType: StoryMediaType
    let storyManager = StoryManager()
    var targetId: String
    var avatar: UIImage?
    @Published var hyperLinkConfigModel: HyperLinkModel = HyperLinkModel(url: "", urlName: "")
    
    init(targetId: String, avatar: UIImage?, mediaType: StoryMediaType) {
        self.targetId = targetId
        self.storyMediaType = mediaType
        self.avatar = avatar
    }
    
    func createStory(displayMode: ContentMode) async throws {
        switch storyMediaType {
            
        case .image(let imageURL, _):
            guard let imageURL else {
                Log.add(event: .error, "ImageURL should not be nil.")
                return
            }
            
            let storyImageDisplayMode = displayMode == .fill ? AmityStoryImageDisplayMode.fill : AmityStoryImageDisplayMode.fit
            
            let items: [AmityStoryItem]
            if !hyperLinkConfigModel.url.isEmpty {
                let hyperLinkItem = AmityHyperLinkItem(url: hyperLinkConfigModel.url, customText: hyperLinkConfigModel.urlName.isEmpty ? nil : hyperLinkConfigModel.urlName)
                items = [hyperLinkItem]
            } else {
                items = []
            }
            
            let createOption = AmityImageStoryCreateOptions(targetType: .community, tartgetId: targetId, imageFileURL: imageURL, items: items, imageDisplayMode: storyImageDisplayMode)
            
            try await storyManager.createImageStory(in: targetId, createOption: createOption)
            
        case .video(let videoURL):
            guard let videoURL else {
                Log.add(event: .error, "VideoURL should not be nil.")
                return
            }
            
            let items: [AmityStoryItem]
            if !hyperLinkConfigModel.url.isEmpty {
                let hyperLinkItem = AmityHyperLinkItem(url: hyperLinkConfigModel.url, customText: hyperLinkConfigModel.urlName.isEmpty ? nil : hyperLinkConfigModel.urlName)
                items = [hyperLinkItem]
            } else {
                items = []
            }
            
            let createOption = AmityVideoStoryCreateOptions(targetType: .community, tartgetId: targetId, videoFileURL: videoURL, items: items)
            
            try await storyManager.createVideoStory(in: targetId, createOption: createOption)
        }
        
    }
}

#Preview {
    AmityDraftStoryPage(targetId: "", avatar: nil, mediaType: .image(nil, nil))
}
