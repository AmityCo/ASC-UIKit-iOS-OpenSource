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
            
            Image(AmityIcon.videoControlIcon.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
        }
    }
}
