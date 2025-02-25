//
//  AmityTextMessageReplyPreview.swift
//  AmityUIKit4
//
//  Created by Nishan on 18/2/2567 BE.
//

import SwiftUI

public typealias DefaultTapAction = (() -> Void)

struct AmityTextMessageReplyPreview: View {
    
    let message: MessageModel
    let closeAction: DefaultTapAction
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(message: MessageModel, closeAction: @escaping DefaultTapAction) {
        self.message = message
        self.closeAction = closeAction
    }
    
    var body: some View {
        
        HStack(spacing: 0) {
            AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: message.avatarURL)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .padding(.leading, 16)
                .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.userAvatar)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(AmityLocalizedStringSet.Chat.replyMessagePreview.localized(arguments: message.displayName))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(viewConfig.theme.baseInverseColor))
                    .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.userDisplayName)
                    .lineLimit(1)
                
                Text(message.text)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            Button(action: {
                closeAction()
            }, label: {
                Image(AmityIcon.Chat.closeReply.imageResource)
            })
            .padding(.trailing, 12)
            .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.close_button)
        }
        
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 62)
        .background(Color(viewConfig.theme.baseColorShade4)) // Light: F5F5F5
    }
}

#if DEBUG
#Preview {
    AmityTextMessageReplyPreview(message: .init(id: UUID().uuidString, text: "Hello", type: .text, hasReaction: false, parentId: nil), closeAction: { })
}
#endif
