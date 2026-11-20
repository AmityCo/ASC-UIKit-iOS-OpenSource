//
//  PostContentClipView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 19/6/25.
//

import SwiftUI
import Foundation
import AmitySDK

struct PostContentClipView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @StateObject var mediaPlayerController = AmityMediaPlayerController()

    @Environment(\.feedAutoPlayHost) private var feedAutoPlayHost
    @ObservedObject private var autoPlay = FeedAutoPlayStore.shared
    /// The same post can be on screen twice, so each instance reports under its own key.
    @State private var instanceId = UUID()
    
    let post: AmityPostModel
    let size: CGSize
    let thumbnailURL: URL?
    let displayMode: ContentMode
    
    init(post: AmityPostModel) {
        self.post = post
        
        let idealWidth = UIScreen.main.bounds.width - 32 // 16 padding on each side
        let aspectRatio: Double = 16.0 / 9.0
        let idealHeight = aspectRatio * idealWidth
        self.size = CGSize(width: idealWidth, height: min(600, idealHeight)) // idealHeight seems to be too large
        self.thumbnailURL = post.medias.first?.getImageURL()
        
        if case let .clip(clipContent) = post.content {
            displayMode = clipContent.displayMode == .fill ? .fill : .fit
        } else {
            displayMode = .fill
        }
    }
    
    var body: some View {
        ZStack {
            Color(viewConfig.theme.baseColorShade4)
                .cornerRadius(8, corners: .allCorners)
                .frame(width: size.width, height: size.height)
                .opacity(thumbnailURL == nil ? 1 : 0)
            
            if let url = thumbnailURL {
                Color.clear
                    .overlay(Color.black)
                    .overlay(
                        URLImage(url, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: displayMode)
                        })
                        .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                    )
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(8, corners: .allCorners)
                    .contentShape(Rectangle())
            }
            
            if !isActive, feedAutoPlayHost, let frame = autoPlay.keptFrame(for: clipURL) {
                Color.black
                    .overlay(
                        Image(uiImage: frame)
                            .resizable()
                            .aspectRatio(contentMode: displayMode)
                    )
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(8, corners: .allCorners)
            }

            if isActive, let url = clipURL {
                // Plays in place like a feed video; a tap outside its sound button still opens the clip feed.
                FeedInlineVideoView(url: url, videoGravity: displayMode == .fill ? .resizeAspectFill : .resizeAspect,
                                    isForceMuted: isSavedMuted)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(8, corners: .allCorners)
            } else if !(autoPlay.isAutoPlayOn && autoPlayKey != nil) {
                // While auto-play is on, a clip that is not playing shows no play icon.
                Image(AmityIcon.videoControlIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .feedPlayButtonAccessibility(feedAutoPlayHost)
            }
        }
        .reportsFeedAutoPlayVisibility(key: autoPlayKey)
    }

    /// A clip saved as muted always plays muted, as in the clip feed.
    private var isSavedMuted: Bool {
        if case let .clip(data) = post.content { return data.isMuted }
        return false
    }

    private var clipURL: URL? {
        post.medias.first?.autoPlayVideoURL
    }

    private var autoPlayKey: String? {
        guard feedAutoPlayHost, let url = clipURL, !autoPlay.hasFailed(url) else { return nil }
        return "\(post.postId)#0#\(instanceId.uuidString)"
    }

    private var isActive: Bool {
        guard let autoPlayKey else { return false }
        return autoPlay.activeKey == autoPlayKey
    }
}
