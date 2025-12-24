//
//  PostContentLiveStreamView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/24.
//

import SwiftUI
import AmitySDK
import AVKit

struct PostContentLiveStreamView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    @State var showVideoPlayer: Bool = false
    let post: AmityPostModel
    let room: AmityRoom?
    let isStreamDeleted: Bool
    let isStreamBanned: Bool
    
    init(post: AmityPostModel) {
        self.post = post
        self.room = post.room
        self.isStreamDeleted = room?.isDeleted ?? false
        self.isStreamBanned = false
//        self.isStreamBanned = room?.isBanned ?? false
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            
            Rectangle()
                .foregroundColor(Color.black)
            
            if isStreamDeleted {
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamErrorIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                }
                .padding(.horizontal, 16)
            } else if isStreamBanned {
                VStack(alignment: .center) {
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerBannedTitle.localizedString)
                        .applyTextStyle(.titleBold(.white))
                        .padding(.bottom, 4)
                    
                    Text( AmityLocalizedStringSet.Social.livestreamPlayerBannedMessage.localizedString)
                        .applyTextStyle(.caption(.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            } else {
                switch post.livestreamState {
                case .idle, .live, .recorded:
                    
                    let thumbnailImageUrl = room?.getThumbnail()?.mediumFileURL ?? ""
                    AsyncImage(placeholder: AmityIcon.livestreamPlaceholderGray.imageResource, url: URL(string: thumbnailImageUrl), contentMode: .fill)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(post.livestreamState.badgeTitle)
                                .applyTextStyle(.captionBold(.white))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(post.livestreamState == .live ? Color(UIColor(hex: "FF305A")) : Color.black.opacity(0.5))
                                .blurBackground(style: .regular)
                                .cornerRadius(4, corners: .allCorners)
                                .padding(12)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    
                    Image(AmityIcon.videoControlIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .isHidden(post.livestreamState == .idle)
                    
                case .ended:
                    VStack(alignment: .center) {
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .error:
                    VStack(alignment: .center) {
                        Image(AmityIcon.livestreamErrorIcon.imageResource)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 12)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerErrorTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerErrorMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .terminated:
                    VStack(alignment: .center) {
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text( AmityLocalizedStringSet.Social.livestreamPlayerTerminatedMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .none:
                    EmptyView()
                    
                }
            }
        }
        .frame(height: 208)
        .onTapGesture {
            guard !isStreamBanned else { return }
            
            switch post.livestreamState {
            case .live, .recorded:
                let livestreamPlayerPage = AmityLivestreamPlayerPage(post: post.object)
                let hostController = AmitySwiftUIHostingNavigationController(rootView: livestreamPlayerPage)
                hostController.isNavigationBarHidden = true
                hostController.modalPresentationStyle = .overFullScreen
                self.host.controller?.present(hostController, animated: true)
            default:
                break
            }
            
        }
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension View {
    func blurBackground(style: UIBlurEffect.Style) -> some View {
        background(BlurView(style: style))
    }
}
