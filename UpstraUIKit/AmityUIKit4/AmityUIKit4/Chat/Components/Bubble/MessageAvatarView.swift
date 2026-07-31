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
            AmityChatUserProfileImageView(displayName: message.displayName, avatarURL: message.avatarURL)
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            if message.isSenderModerator {
                AmityBadge(variant: .icon,
                           icon: .shieldCheckS,
                           size: .size16,
                           preset: .userStatus(.moderator),
                           viewConfig: viewConfig)
                    .padding(2)
                    .background(
                        Color(viewConfig.color(.borderAvatarIndicatorDefault))
                            .clipShape(Circle())
                    )
                    .offset(x: 6, y: 6)
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
