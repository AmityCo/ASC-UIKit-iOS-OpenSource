//
//  PostContentLiveStreamView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/24.
//

import SwiftUI
import AmitySDK
import AVKit
import AmityVideoPlayerKit

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
                        .font(.system(size: 13, weight: .bold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundColor(Color.white)
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
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.white)
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedMessage.localizedString).multilineTextAlignment(.center)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, 16)
                
            case .terminated:
                VStack(alignment: .center) {
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedTitle.localizedString)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.white)
                        .padding(.bottom, 4)
                    
                    
                    Text( AmityLocalizedStringSet.Social.livestreamPlayerTerminatedMessage.localizedString)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white)
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
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.white)
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableMessage.localizedString)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white)
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
