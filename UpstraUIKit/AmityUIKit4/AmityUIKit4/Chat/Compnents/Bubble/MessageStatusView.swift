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
    @ObservedObject var viewModel: LiveChatMessageBubbleViewModel
    let messageAction: AmityMessageAction

    @State private var showSheet = false
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    init(message: MessageModel, dateFormat: DateFormatter, viewModel: LiveChatMessageBubbleViewModel, messageAction: AmityMessageAction) {
        self.message = message
        self.dateFormat = dateFormat
        self.viewModel = viewModel
        self.messageAction = messageAction
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                showSheet.toggle()
            } label: {
                Image(AmityIcon.Chat.messageErrorIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            }
            .padding(.bottom, 4)
            .isHidden(message.syncState != .error)
            .actionSheet(isPresented: $showSheet) {
                ActionSheet(
                    title: Text(AmityLocalizedStringSet.Chat.deleteActionSheetTitle.localizedString),
                    buttons: [
                        .destructive(Text(AmityLocalizedStringSet.Chat.deleteButton.localizedString)) {
                            messageAction.onDelete?(message)
                        },
                        .cancel()
                    ]
                )
            }
            
            if message.flagCount > 0 && (viewModel.isReportedByMe || (message.isFlaggedByMe ?? false)) {
                Image(AmityIcon.Chat.redFlagIcon.imageResource)
                    .scaledToFit()
                    .padding(.bottom, 6)
                    .padding(.leading, 6)
                    .frame(width: 20, height: 20)
            }

            Text(dateFormat.string(from: message.createdAt))
                .font(.system(size: 9))
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .isHidden(message.syncState != .synced)
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleTimestamp)
                .padding(.leading, 6)
                .padding(.bottom, 10)

            Text(AmityLocalizedStringSet.Chat.statusSending.localizedString)
                .font(.system(size: 9))
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .isHidden(message.syncState != .syncing)
                .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleSendingStatus)
                .padding(.leading, 6)
                .padding(.bottom, 10)
        }
    }
}

#if DEBUG
#Preview {
    MessageStatusView(message: MessageModel.preview, dateFormat: DateFormatter(), viewModel: LiveChatMessageBubbleViewModel(message: MessageModel.preview), messageAction: AmityMessageAction(onCopy: nil, onReply: nil, onDelete: nil, onReport: nil, onUnReport: nil))
}
#endif
