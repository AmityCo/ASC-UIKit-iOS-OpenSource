//
//  MessageActionView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI

struct MessageActionView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let message: MessageModel
    let messageAction: AmityMessageAction
    let dismissAction: () -> Void
    @StateObject var viewModel: LiveChatMessageBubbleViewModel
    
    init(message: MessageModel, messageAction: AmityMessageAction, dismissAction: @escaping () -> Void) {
        self.message = message
        self.messageAction = messageAction
        self._viewModel = StateObject(wrappedValue: LiveChatMessageBubbleViewModel(message: message))
        self.dismissAction = dismissAction
    }

    struct ActionButton: View {
        
        let title: String
        let image: ImageResource
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                    
                    Spacer()
                    
                    Image(image)
                        .renderingMode(.template)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            ActionButton(title: AmityLocalizedStringSet.Chat.replyButton.localizedString, image: AmityIcon.Chat.replyIcon.imageResource) {
                
                let replyModel = message
                messageAction.onReply?(replyModel)
                dismissAction()
            }
            .foregroundColor(Color(viewConfig.theme.baseInverseColor))
            .isHidden(message.syncState == .error)
            .accessibilityIdentifier(AmityLocalizedStringSet.Chat.replyButton.localizedString)
            
            Divider()
                .frame(maxWidth: .infinity)

            ActionButton(title: AmityLocalizedStringSet.Chat.copyButton.localizedString, image: AmityIcon.Chat.copyIcon.imageResource) {
                
                messageAction.onCopy?(message)
                dismissAction()
            }
            .foregroundColor(Color(viewConfig.theme.baseInverseColor))
            .accessibilityIdentifier(AmityLocalizedStringSet.Chat.copyButton.localizedString)
            
            if !message.isOwner {
                let isFlaggedByOwner = message.isFlaggedByMe ?? viewModel.isReportedByMe

                Divider()
                    .frame(maxWidth: .infinity)
                
                ActionButton(title: isFlaggedByOwner ? AmityLocalizedStringSet.Chat.unReportButton.localizedString : AmityLocalizedStringSet.Chat.reportButton.localizedString, image: AmityIcon.Chat.redFlagIcon.imageResource) {
                    
                    if isFlaggedByOwner {
                        messageAction.onUnReport?(message)
                    } else {
                        messageAction.onReport?(message)
                    }
                    dismissAction()

                }
                .foregroundColor(Color.red)
                .accessibilityIdentifier(isFlaggedByOwner ? AmityLocalizedStringSet.Chat.unReportButton.localizedString : AmityLocalizedStringSet.Chat.reportButton.localizedString)
            }
            
            if message.isOwner || message.hasModeratorPermissionInChannel {
                
                Divider()
                    .frame(maxWidth: .infinity)

                ActionButton(title: AmityLocalizedStringSet.Chat.deleteButton.localizedString, image: AmityIcon.Chat.redTrashIcon.imageResource) {
                    
                    messageAction.onDelete?(message)
                    dismissAction()
                }
                .foregroundColor(Color.red)
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.deleteButton.localizedString)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
