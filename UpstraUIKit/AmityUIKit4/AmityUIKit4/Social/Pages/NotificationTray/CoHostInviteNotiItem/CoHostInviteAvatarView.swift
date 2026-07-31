//
//  CoHostInviteAvatarView.swift
//  AmityUIKit4
//
//  Created by Prisa on 21/7/2569 BE.
//

import Foundation

struct CoHostInviteAvatarView: View {

    @EnvironmentObject var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = CoHostInviteAvatarViewModel()

    let displayName: String
    let avatarURL: URL?
    let roomId: String
    let size: CGFloat

    var body: some View {
        AmityUserProfileImageView(displayName: displayName, avatarURL: avatarURL)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(liveBadge.isHidden(!viewModel.isLive), alignment: .bottomTrailing)
            .onAppear { viewModel.observeIfNeeded(roomId: roomId) }
    }

    @ViewBuilder
    private var liveBadge: some View {
        Image(AmityIcon.notiLiveBadge.imageResource)
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.5, height: size * 0.5)
            .offset(x: size * 0.15, y: size * 0.15)
    }
}
