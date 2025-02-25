//
//  AmityDraftStoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/18/23.
//

import SwiftUI
import AVKit
import AmitySDK
import Combine

public enum AmityStoryMediaType {
    case image(URL)
    case video(URL)
}

public struct AmityDraftStoryPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .storyCreationPage
    }
    
    @StateObject private var viewModel: AmityDraftStoryPageViewModel
    @State private var previewDisplayMode: ContentMode = .fit
    @State private var animateActivityIndicator: Bool = false
    @State private var userInteractionEnabled: Bool = true
    @State private var isAlertShown = false
    @State private var showHyperLinkSheet: Bool = false
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(targetId: String, targetType: AmityStoryTargetType, mediaType: AmityStoryMediaType) {
        self._viewModel = StateObject(wrappedValue: AmityDraftStoryPageViewModel(targetId: targetId, targetType: targetType, mediaType: mediaType))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .storyCreationPage))
        
        if case .image(let url) = mediaType {
            if let image = UIImage(contentsOfFile: url.path) {
                self._previewDisplayMode = State(initialValue: image.orientation == .portrait ? .fill : .fit)
            }
        }
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
                                Image(AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "back_icon", of: String.self) ?? ""))
                                    .frame(width: 32, height: 32)
                                    .background(Color(UIColor(hex: viewConfig.getConfig(elementId: .backButtonElement, key: "background_color", of: String.self) ?? "").withAlphaComponent(0.5)))
                                    .clipShape(.circle)
                            })
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.backButton)
                            .isHidden(viewConfig.isHidden(elementId: .backButtonElement), remove: false)
                    
                            Spacer()
                            
                            if case .image = viewModel.storyMediaType {
                                Button {
                                    previewDisplayMode = previewDisplayMode == .fill ? .fit : .fill
                                } label: {
                                    Image(AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .aspectRatioButtonElement, key: "aspect_ratio_icon", of: String.self) ?? ""))
                                        .frame(width: 32, height: 32)
                                        .background(Color(UIColor(hex: viewConfig.getConfig(elementId: .aspectRatioButtonElement, key: "background_color", of: String.self) ?? "").withAlphaComponent(0.5)))
                                        .clipShape(.circle)
                                }
                                .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.aspectRatioButton)
                                .isHidden(viewConfig.isHidden(elementId: .aspectRatioButtonElement), remove: false)
                            }
                            
                            Button {
                                guard viewModel.hyperLinkConfigModel.url.isEmpty else {
                                    Toast.showToast(style: .warning, message: "Can’t add more than one link to your story.")
                                    return
                                }
                                showHyperLinkSheet = true
                            } label: {
                                Image(AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .hyperLinkButtonElement, key: "hyperlink_button_icon", of: String.self) ?? ""))
                                    .frame(width: 32, height: 32)
                                    .background(Color(UIColor(hex: viewConfig.getConfig(elementId: .hyperLinkButtonElement, key: "background_color", of: String.self) ?? "").withAlphaComponent(0.5)))
                                    .clipShape(.circle)
                            }
                            .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.hyperLinkButton)
                            .isHidden(viewConfig.isHidden(elementId: .hyperLinkButtonElement), remove: false)
                        }
                        .padding(16)
                        
                        Spacer()
                        
                        if !viewModel.hyperLinkConfigModel.url.isEmpty {
                            HStack(spacing: 0) {
                                Image(AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .hyperLinkElement, key: "hyper_link_icon", of: String.self) ?? ""))
                                    .frame(width: 20, height: 20)
                                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                                let title = viewModel.hyperLinkConfigModel.getCustomName().isEmpty ? viewModel.hyperLinkConfigModel.getDomainName() ?? "" : viewModel.hyperLinkConfigModel.getCustomName()
                                Text(title)
                                    .applyTextStyle(.body(Color(viewConfig.defaultLightTheme.baseColor)))
                                    .lineLimit(1)
                                    .padding(.trailing, 16)
                                    .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.hyperlinkTextView)
                            }
                            .frame(height: 40)
                            .background(Color(UIColor(hex: viewConfig.getConfig(elementId: .hyperLinkElement, key: "background_color", of: String.self) ?? "")).opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(EdgeInsets(top: 0, leading: 24, bottom: 32, trailing: 24))
                            .onTapGesture {
                                showHyperLinkSheet = true
                            }
                            .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.hyperlinkView)
                            .isHidden(viewConfig.isHidden(elementId: .hyperLinkElement), remove: false)
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
                    .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.shareStoryButton)
                    .isHidden(viewConfig.isHidden(elementId: .shareStoryButtonElement), remove: false)
                
            }
        }
        .bottomSheet(isPresented: $showHyperLinkSheet, height: .infinity,
                     topBarBackgroundColor: Color(viewConfig.theme.backgroundColor),
                     animation: .easeInOut(duration: 0.25), content: {
            AmityHyperLinkConfigComponent(isPresented: $showHyperLinkSheet, data: $viewModel.hyperLinkConfigModel, pageId: id)
        })
        .alert(isPresented: $isAlertShown, content: {
            Alert(title: Text("Discard this story?"), message: Text("The story will be permanently deleted. It cannot be undone."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Discard"), action: {
                host.controller?.navigationController?.popViewController(animated: true)
            }))
        })
        .allowsHitTesting(userInteractionEnabled)
        .ignoresSafeArea(.keyboard)
        .background(Color.black.ignoresSafeArea())
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }
    
    @State private var playVideo: Bool = false
    
    @ViewBuilder
    func getPreviewView(size: CGSize) -> some View {
        
        switch viewModel.storyMediaType {
        case .image(let url):
            if let image = UIImage(contentsOfFile: url.path) {
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
                    .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.storyImageView)
            }
        case .video(let url):
            VideoPlayer(url: url, play: $playVideo)
                .autoReplay(true)
                .contentMode(.scaleAspectFit)
                .allowsHitTesting(false)
                .frame(width: size.width, height: size.height)
                .cornerRadius(14.0)
                .onAppear {
                    playVideo.toggle()
                }
                .onDisappear {
                    playVideo.toggle()
                }
                .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.storyVideoView)
        }
    }
    
    @ViewBuilder
    func getShareStoryButtonView() -> some View {
        let shareIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .shareStoryButtonElement, key: "share_icon", of: String.self) ?? "")
        let hideAvatar = viewConfig.getConfig(elementId: .shareStoryButtonElement, key: "hide_avatar", of: Bool.self) ?? false
        let backgroundColor = Color(UIColor(hex: viewConfig.getConfig(elementId: .shareStoryButtonElement, key: "background_color", of: String.self) ?? ""))
        
        HStack(spacing: 8) {
            if !hideAvatar {
                AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: viewModel.avatar)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.leading, 4)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityDraftStoryPage.shareStoryButtonAvatar)
            }
            
            Text("Share Story")
                .applyTextStyle(.body(Color(viewConfig.defaultLightTheme.baseColor)))
            
            Image(shareIcon)
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
        }
        .frame(height: 40)
        .background(backgroundColor)
    }
}

class AmityDraftStoryPageViewModel: ObservableObject {
    var storyMediaType: AmityStoryMediaType
    let storyManager = StoryManager()
    var targetId: String
    var targetType: AmityStoryTargetType
    @Published var avatar: URL?
    
    private var cancellable: AnyCancellable?
    private var communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    @Published var hyperLinkConfigModel: HyperLinkModel = HyperLinkModel(url: "", urlName: "")
    
    init(targetId: String, targetType: AmityStoryTargetType, mediaType: AmityStoryMediaType) {
        self.targetId = targetId
        self.storyMediaType = mediaType
        self.targetType = targetType
        
        let communityObject = communityRepository.getCommunity(withId: targetId)
        cancellable = communityObject.$snapshot
            .sink { [weak self] community in
                self?.avatar = URL(string: community?.avatar?.fileURL ?? "")
            }
    }
    
    func createStory(displayMode: ContentMode) async throws {
        switch storyMediaType {
            
        case .image(let imageURL):
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
