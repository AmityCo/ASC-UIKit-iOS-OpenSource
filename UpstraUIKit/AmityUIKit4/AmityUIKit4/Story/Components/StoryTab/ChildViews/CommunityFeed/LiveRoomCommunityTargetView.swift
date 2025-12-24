//
//  LiveRoomCommunityTargetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/24/25.
//

import SwiftUI

struct LiveRoomCommunityTargetView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let post: AmityPostModel
    
    init(post: AmityPostModel) {
        self.post = post
    }
    
    var body: some View {
        getStoryView(avatar: getAvatar(),
                     cornerAvatar: getCornerAvatar(),
                     name: getName())
    }
    
    private func getStoryView(avatar: (URL?, String),
                              cornerAvatar: ImageResource,
                              name: String) -> some View {
        return VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 2.0)
                    .fill(Color(hex: "#FF305A"))
                    .frame(width: 56, height: 56)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.storyRingView)
                
                AmityUserProfileImageView(displayName: avatar.1, avatarURL: avatar.0)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.avatarImageView)
                
                Image(cornerAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 12, height: 6)
                    .circularBackground(radius: 14, color: Color(hex: "#FF305A"))
                    .padding(.all, 2)
                    .background(Color.white)
                    .clipShape(Circle())
                    .offset(x: 20, y: 20)
            }
            
            Text(name)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                .frame(height: 20, alignment: .leading)
                .accessibilityIdentifier(AccessibilityID.Story.AmityStoryTabComponent.targetNameTextView)
        }
    }
    
    private func getAvatar() -> (url: URL?, displayName: String) {
        let avatarURL = URL(string: post.room?.creator?.getAvatarInfo()?.mediumFileURL ?? "")
        let displayName = post.room?.creator?.displayName ?? "Unknown"
        
        return (avatarURL, displayName)
    }
    
    private func getCornerAvatar() -> ImageResource {
        return AmityIcon.LiveStream.hostIcon.imageResource
    }
    
    private func getName() -> String {
        let name = post.room?.creator?.displayName
        return name ?? "Unknown"
    }
}
