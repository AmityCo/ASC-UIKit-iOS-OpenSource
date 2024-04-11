//
//  MessageStatusView.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

// Status (Flag / Unflag / Sent / Timestamp blabla)
struct MessageStatusView: View {
    
    let message: MessageModel
    let dateFormat: DateFormatter
    
    var body: some View {
        
        Button {
            
        } label: {
            Image(AmityIcon.Chat.messageErrorIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
        .padding(.bottom, 4)
        .isHidden(message.syncState != .error)

        
        Text(dateFormat.string(from: message.createdAt))
            .font(.system(size: 9))
            .foregroundColor(Color(UIColor(hex: "#898E9E")))
            .isHidden(message.syncState != .synced)
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleTimestamp)
            .padding(.bottom, 10)

        Text(AmityLocalizedStringSet.Chat.statusSending.localizedString)
            .font(.system(size: 9))
            .foregroundColor(Color(UIColor(hex: "#898E9E")))
            .isHidden(message.syncState != .syncing)
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleSendingStatus)
            .padding(.bottom, 10)

    }
}

#if DEBUG
#Preview {
    MessageStatusView(message: MessageModel.preview, dateFormat: DateFormatter())
}
#endif
