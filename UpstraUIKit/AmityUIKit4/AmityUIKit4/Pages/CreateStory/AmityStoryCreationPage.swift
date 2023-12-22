//
//  AmityStoryCreationPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/18/23.
//

import SwiftUI
import AVKit
import AmitySDK

enum StoryMediaType {
    case image(URL?, UIImage?)
    case video(URL?)
}

struct AmityStoryCreationPage: AmityPageView {
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    var id: PageId {
        .storyCreationPage
    }
    
    @StateObject private var viewModel: AmityStoryCreationPageViewModel
    @State private var animateActivityIndicator: Bool = false
    @State private var userInteractionEnabled: Bool = true
    @State private var isAlertShown = false
    
    init(targetId: String, avatar: UIImage?, mediaType: StoryMediaType) {
        self._viewModel = StateObject(wrappedValue: AmityStoryCreationPageViewModel(targetId: targetId, avatar: avatar, mediaType: mediaType))
    }
    
    var body: some View {
        AmityView(configType: .page(configId), config: { configDict in
            
        }) { config in
            VStack(alignment: .trailing) {
                ZStack(alignment: .topLeading) {
                    GeometryReader { geometry in
                        getPreviewView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .cornerRadius(14.0)
                            .overlay(
                                ActivityIndicatorView(isAnimating: $animateActivityIndicator, style: .medium)
                            )
                    }
                    
                    Button(action: {
                        isAlertShown = true
                    }, label: {
                        Image(AmityIcon.backIcon.getImageResource())
                            .setModifier(offset: (x: 16, y: 16),
                                         contentMode: .fill,
                                         frame: CGSize(width: 32, height: 32))
                    })
                    .buttonStyle(.plain)
                    .alert(isPresented: $isAlertShown, content: {
                        Alert(title: Text("Discard this story?"), message: Text("The story will be permanently deleted. It cannot be undone."), primaryButton: .cancel(), secondaryButton: .destructive(Text("Discard"), action: {
                            host.controller?.navigationController?.popViewController(animated: true)
                        }))
                    })
                }
                
                getShareStoryButtonView()
                    .background(Color.white)
                    .cornerRadius(24.0)
                    .padding([.top, .bottom, .trailing], 16)
                    .onTapGesture {
                        Task {
                            userInteractionEnabled = false
                            animateActivityIndicator.toggle()
                            
                            await viewModel.createStory()
                            
                            animateActivityIndicator.toggle()
                            userInteractionEnabled = true
                            host.controller?.navigationController?.dismiss(animated: true)
                        }
                    }
                
            }
        }
        .allowsHitTesting(userInteractionEnabled)
        .background(Color.black.ignoresSafeArea())
    }
    
    @State private var playVideo: Bool = false
    
    @ViewBuilder
    func getPreviewView() -> some View {
        
        switch viewModel.storyMediaType {
        case .image(_, let image):
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        case .video(let url):
            if let url {
                VideoPlayer(url: url, play: $playVideo)
                    .autoReplay(true)
                    .contentMode(.scaleToFill)
                    .allowsHitTesting(false)
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
        HStack(spacing: 8) {
            Image(uiImage: viewModel.avatar ?? AmityIcon.defaultCommunity.getImage()!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .background(Color.yellow)
                .clipShape(Circle())
                .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 0))
            
            Text("Share Story")
                .font(Font.system(size: 14))
                .fontWeight(.medium)
            
            Image(AmityIcon.nextIcon.getImageResource())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 16)
                .padding([.trailing], 10)
        }
    }
}

class AmityStoryCreationPageViewModel: ObservableObject {
    var storyMediaType: StoryMediaType
    let storyManager = StoryManager()
    var targetId: String
    var avatar: UIImage?
    
    init(targetId: String, avatar: UIImage?, mediaType: StoryMediaType) {
        self.targetId = targetId
        self.storyMediaType = mediaType
        self.avatar = avatar
    }
    
    func createStory() async {
        switch storyMediaType {
            
        case .image(let imageURL, _):
            guard let imageURL else {
                Log.add(event: .error, "ImageURL should not be nil.")
                return
            }
            let createOption = AmityImageStoryCreateOptions(targetType: .community, tartgetId: targetId, imageFileURL: imageURL, items: [])
            
            do {
                try await storyManager.createImageStory(in: targetId, createOption: createOption)
            } catch {
                Log.add(event: .error, "Image Story Creation fail: \(error)")
            }
            
        case .video(let videoURL):
            guard let videoURL else {
                Log.add(event: .error, "VideoURL should not be nil.")
                return
            }
            let createOption = AmityVideoStoryCreateOptions(targetType: .community, tartgetId: targetId, videoFileURL: videoURL, items: [])
            
            do {
                try await storyManager.createVideoStory(in: targetId, createOption: createOption)
            } catch {
                Log.add(event: .error, "Video Story Creation fail: \(error)")
            }
        }
        
    }
}

#Preview {
    AmityStoryCreationPage(targetId: "", avatar: nil, mediaType: .image(nil, nil))
}
