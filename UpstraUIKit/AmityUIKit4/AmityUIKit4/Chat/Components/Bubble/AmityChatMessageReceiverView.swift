//
//  AmityChatMessageReceiverView.swift
//  AmityUIKit4
//

import SwiftUI
import AVKit

public struct AmityChatMessageReceiverView: AmityElementView {

    public var pageId: PageId?
    public var componentId: ComponentId?
    public var id: ElementId { .receiverMessageBubble }

    let message: MessageModel
    let messageAction: AmityMessageAction

    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @State private var mediaViewer: ChatMediaViewerKind?

    public init(message: MessageModel, messageAction: AmityMessageAction, pageId: PageId? = .chatPage, componentId: ComponentId? = .messageList) {
        self.message = message
        self.messageAction = messageAction
        self.pageId = pageId
        self.componentId = componentId
    }

    public var body: some View {
        ChatMessageBubbleView(message: message, messageAction: messageAction) {
            VStack(alignment: .leading, spacing: 4) {
                if message.type == .image {
                    ImageBubbleView(url: message.mediumFileURL, syncState: message.syncState)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if message.syncState == .synced {
                                mediaViewer = .image
                            }
                        }
                } else if message.type == .video {
                    VideoBubbleView(
                        thumbnailURL: message.videoThumbnailURL,
                        syncState: message.syncState
                    ) {
                        mediaViewer = .video
                    }
                } else {
                    textContent
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.receiverText)

                    if message.syncState != .error,
                       let url = MessageLinkDetector.firstURL(in: message.text) {
                        MessageLinkPreviewView(url: url, isOwner: false)
                            .padding(.top, 12)
                    }
                }
            }
        }
        // One cover for both media kinds — see `ChatMediaViewerKind`.
        .fullScreenCover(item: $mediaViewer) { kind in
            switch kind {
            case .video:
                if let url = message.videoPlaybackURL {
                    VideoMessageFullScreenView(
                        viewConfig: viewConfig,
                        videoURL: url,
                        downloadURL: message.videoDownloadURL,
                        onClose: { mediaViewer = nil }
                    )
                }
            case .image:
                MediaViewer(
                    url: message.imageURL ?? message.mediumFileURL,
                    viewConfig: viewConfig,
                    closeAction: { mediaViewer = nil },
                    saveImageURL: message.largeImageURL
                )
            }
        }
    }

    @ViewBuilder
    var textContent: some View {
        // Cap at 10 lines before "see more" for all messages, including text
        // containing long links.
        let maxLines = 10

        if #available(iOS 15, *) {
            let bodyBoldFont = AmityTextStyle.bodyBold(.clear).getUIFont()
            let mentionAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: viewConfig.color(.textChatBubbleInboundMentionedDefault),
                .font: bodyBoldFont
            ]
            let linkAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: viewConfig.color(.textChatBubbleInboundLinkDefault),
                .underlineStyle: Text.LineStyle(pattern: .solid)
            ]
            let attributedText = TextHighlighter.getAttributedText(from: message, highlightAttributes: mentionAttrs, linkAttributes: linkAttrs)
            OverflowDetectingText(attributedText: attributedText, maxLines: maxLines)
        } else {
            OverflowDetectingText(plainText: message.text, maxLines: maxLines)
        }
    }
}

#if DEBUG
#Preview {
    AmityChatMessageReceiverView(
        message: MessageModel.preview,
        messageAction: AmityMessageAction(onCopy: nil, onReply: nil, onDelete: nil, onReport: nil, onUnReport: nil)
    )
}
#endif
