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
    let isParentUnavailable: Bool
    let closeAction: DefaultTapAction

    @EnvironmentObject var viewConfig: AmityViewConfigController

    init(message: MessageModel, isParentUnavailable: Bool = false, closeAction: @escaping DefaultTapAction) {
        self.message = message
        self.isParentUnavailable = isParentUnavailable
        self.closeAction = closeAction
    }

    var body: some View {

        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AmityLocalizedStringSet.Chat.replyMessagePreview.localized(arguments: replyTargetName))
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                    .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.userDisplayName)
                    .lineLimit(1)

                Text(previewText)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)

            Spacer()

            if !isParentUnavailable {
                if message.type == .image, let url = message.imageURL {
                    AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: url)
                        .frame(width: 38, height: 38)
                        .cornerRadius(4)
                        .padding(.trailing, 8)
                } else if message.type == .video, let url = message.videoThumbnailURL {
                    ZStack {
                        AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: url)
                            .frame(width: 38, height: 38)
                            .cornerRadius(4)
                        Color.black.opacity(0.4)
                            .frame(width: 38, height: 38)
                            .cornerRadius(4)
                        Image(AmityIcon.Chat.videoPlayButtonIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                    .padding(.trailing, 8)
                }
            }

            Button(action: closeAction, label: {
                Image(AmityIcon.Chat.closeReply.imageResource)
                    .frame(width: 20, height: 20)
            })
            .padding(.trailing, 12)
            .accessibilityIdentifier(AccessibilityID.Chat.ReplyPanel.close_button)
        }

        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 62)
        .background(Color(viewConfig.theme.baseColorShade4))
    }

    private var replyTargetName: String {
        message.isOwner
            ? AmityLocalizedStringSet.Chat.Bubble.replyingYourself.localizedString
            : message.displayName
    }

    private var previewText: String {
        if isParentUnavailable {
            return AmityLocalizedStringSet.Chat.ParentPreview.unavailable.localizedString
        }
        switch message.type {
        case .image:
            return AmityLocalizedStringSet.Chat.ParentPreview.photo.localizedString
        case .video:
            return AmityLocalizedStringSet.Chat.ParentPreview.video.localizedString
        default:
            return message.text
        }
    }
}

#if DEBUG
#Preview {
    AmityTextMessageReplyPreview(message: .init(id: UUID().uuidString, text: "Hello", type: .text, hasReaction: false, parentId: nil), closeAction: { }) // l10n:ok preview mock data
}
#endif
