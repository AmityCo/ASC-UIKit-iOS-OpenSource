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
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    let post: AmityPostModel
    let livestream: AmityStream?
    
    
    init(post: AmityPostModel) {
        self.post = post
        self.livestream = post.liveStream
        
    }
    
    
    var body: some View {
        ZStack(alignment: .center) {
            
            Rectangle()
                .foregroundColor(Color.black)
            
            switch post.livestreamState {
            case .live, .recorded:
                
                AsyncImage(placeholder: AmityIcon.livestreamPlaceholder.imageResource, url: URL(string: livestream?.thumbnail?.fileURL ?? ""), contentMode: .fill)
                
                
                VStack(alignment: .leading) {
                    Text(post.livestreamState == .recorded ? AmityLocalizedStringSet.Social.livestreamPlayerRecorded.localizedString : AmityLocalizedStringSet.Social.livestreamPlayerLive.localizedString)
                        .applyTextStyle(.captionBold(.white))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(post.livestreamState == .recorded ? (Color.black.opacity(0.5)) : Color(UIColor(hex: "FF305A")))
                        .cornerRadius(4, corners: .allCorners)
                        .padding(.all, 12)
                    
                    
                    Spacer()
                    
                    // Save for mute button
                    HStack {
                        Spacer()
                    }
                }
                
                Image(AmityIcon.videoControlIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                
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
            case .idle:
                
                VStack(alignment: .center, spacing: 0) {
                    
                    Image(AmityIcon.livestreamErrorIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableTitle.localizedString)
                        .applyTextStyle(.titleBold(.white))
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableMessage.localizedString)
                        .applyTextStyle(.caption(.white))
                }
                .padding(.horizontal, 16)
                
            case .none:
                EmptyView()
                
            }
        }
        .frame(height: 208)
        .onTapGesture {
            switch post.livestreamState {
            case .live, .recorded:
                showVideoPlayer.toggle()
                
            default:
                break
            }
            
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            AmityLivestreamPlayerPage(post: post)
        }
    }
    
}
