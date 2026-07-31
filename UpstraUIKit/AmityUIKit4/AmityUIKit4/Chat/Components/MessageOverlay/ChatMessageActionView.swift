//
//  ChatMessageActionView.swift
//  AmityUIKit4
//

import SwiftUI

private struct PopoverRowButtonStyle: ButtonStyle {
    let viewConfig: AmityViewConfigController

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 44)
            .background(
                configuration.isPressed
                    ? Color(viewConfig.color(.surfacePopoverListsHover))
                    : Color.clear
            )
            .contentShape(Rectangle())
    }
}

struct ChatMessageActionView: View {

    @EnvironmentObject var viewConfig: AmityViewConfigController

    let message: MessageModel
    let messageAction: AmityMessageAction
    let dismissAction: () -> Void
    @StateObject var viewModel: ChatMessageBubbleViewModel

    /// Save video is temporarily disabled: transcoded videos are served as an HLS
    /// stream that can't be reliably saved to Photos. The `onSaveVideo` handler
    /// stays wired — set this to `true` to re-enable the "Save video" action.
    private let isSaveVideoEnabled = false

    init(message: MessageModel, messageAction: AmityMessageAction, dismissAction: @escaping () -> Void) {
        self.message = message
        self.messageAction = messageAction
        self._viewModel = StateObject(wrappedValue: ChatMessageBubbleViewModel(message: message))
        self.dismissAction = dismissAction
    }

    struct ActionButton: View {

        @EnvironmentObject var viewConfig: AmityViewConfigController

        let title: String
        let image: ImageResource
        let isDestructive: Bool
        let action: () -> Void

        init(title: String, image: ImageResource, isDestructive: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.image = image
            self.isDestructive = isDestructive
            self.action = action
        }

        var body: some View {
            let color = isDestructive ? Color(viewConfig.theme.alertColor) : Color(viewConfig.theme.baseColor)
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 18)
                        .foregroundColor(color)
                        .padding(.horizontal, 12)

                    Text(title)
                        .applyTextStyle(.body(color))
                        .padding(.trailing, 12)
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(PopoverRowButtonStyle(viewConfig: viewConfig))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.isOwner && message.type == .text && message.syncState != .error {
                ActionButton(title: AmityLocalizedStringSet.Chat.editButton.localizedString,
                             image: AmityIcon.Chat.editMessageIcon.imageResource) {
                    messageAction.onEdit?(message)
                    dismissAction()
                }
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.editButton.localizedString)
            }

            ActionButton(title: AmityLocalizedStringSet.Chat.replyButton.localizedString,
                         image: AmityIcon.Chat.replyMessageActionIcon.imageResource) {
                messageAction.onReply?(message)
                dismissAction()
            }
            .isHidden(message.syncState == .error)
            .accessibilityIdentifier(AmityLocalizedStringSet.Chat.replyButton.localizedString)

            if message.type != .image && message.type != .video {
                ActionButton(title: AmityLocalizedStringSet.Chat.copyButton.localizedString,
                             image: AmityIcon.Chat.messageCopyIcon.imageResource) {
                    messageAction.onCopy?(message)
                    dismissAction()
                }
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.copyButton.localizedString)
            }

            if message.type == .image,
               messageAction.onSaveImage != nil,
               message.syncState == .synced {
                ActionButton(title: AmityLocalizedStringSet.Chat.SaveMedia.saveImageAction.localizedString,
                             image: AmityIcon.Chat.saveImageIcon.imageResource) {
                    messageAction.onSaveImage?(message)
                    dismissAction()
                }
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.SaveMedia.saveImageAction.localizedString)
            }

            if isSaveVideoEnabled,
               message.type == .video,
               messageAction.onSaveVideo != nil,
               message.syncState == .synced {
                ActionButton(title: AmityLocalizedStringSet.Chat.SaveMedia.saveVideoAction.localizedString,
                             image: AmityIcon.Chat.saveImageIcon.imageResource) {
                    messageAction.onSaveVideo?(message)
                    dismissAction()
                }
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.SaveMedia.saveVideoAction.localizedString)
            }

            if !message.isOwner {
                let isFlaggedByOwner = viewModel.isReportedByMe

                ActionButton(
                    title: isFlaggedByOwner ? AmityLocalizedStringSet.Chat.unReportButton.localizedString : AmityLocalizedStringSet.Chat.reportButton.localizedString,
                    image: isFlaggedByOwner ? AmityIcon.Chat.unreportUserButtonIcon.imageResource : AmityIcon.Chat.reportUserButtonIcon.imageResource
                ) {
                    if isFlaggedByOwner {
                        messageAction.onUnReport?(message)
                    } else {
                        messageAction.onReport?(message)
                    }
                    dismissAction()
                }
                .accessibilityIdentifier(isFlaggedByOwner ? AmityLocalizedStringSet.Chat.unReportButton.localizedString : AmityLocalizedStringSet.Chat.reportButton.localizedString)
            }

            if message.isOwner || message.hasModeratorPermissionInChannel {
                ActionButton(title: AmityLocalizedStringSet.Chat.deleteButton.localizedString,
                             image: AmityIcon.Chat.deletedMessageIcon.imageResource,
                             isDestructive: true) {
                    messageAction.onDelete?(message)
                    dismissAction()
                }
                .accessibilityIdentifier(AmityLocalizedStringSet.Chat.deleteButton.localizedString)
            }
        }
        .onAppear {
            if !message.isOwner {
                viewModel.refreshFlagStatus()
            }
        }
    }
}
