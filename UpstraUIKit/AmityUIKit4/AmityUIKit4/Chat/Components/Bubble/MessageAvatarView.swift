//
//  MessageAvatarView.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

struct MessageAvatarView: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let message: MessageModel
    let placeholderIcon: ImageResource

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AmityUserProfileImageView(displayName: message.displayName, avatarURL: message.avatarURL)
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            if message.isSenderModerator {
                Color(viewConfig.theme.primaryColor.blend(.shade3))
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                    .overlay(
                        Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 14, height: 14)
                    )
                    .offset(x: 4, y: 4)
            }
        }
    }
}

#if DEBUG
#Preview {
    MessageAvatarView(message: MessageModel.preview,
                      placeholderIcon: AmityIcon.defaultCommunity.getImageResource())
}
#endif
