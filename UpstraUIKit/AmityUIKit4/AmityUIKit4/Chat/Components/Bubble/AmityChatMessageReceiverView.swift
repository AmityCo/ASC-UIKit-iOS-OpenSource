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
    @State private var showingVideoPlayer = false
    @State private var showingImageViewer = false

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
                        .onTapGesture {
                            if message.syncState == .synced {
                                showingImageViewer = true
                            }
                        }
                } else if message.type == .video {
                    VideoBubbleView(
                        thumbnailURL: message.videoThumbnailURL,
                        syncState: message.syncState
                    ) {
                        showingVideoPlayer = true
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
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let url = message.videoPlaybackURL {
                VideoMessagePlayerView(videoURL: url)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            MediaViewer(
                url: message.imageURL ?? message.mediumFileURL,
                viewConfig: viewConfig,
                closeAction: { showingImageViewer = false },
                saveImageURL: message.largeImageURL
            )
        }
    }

    @ViewBuilder
    var textContent: some View {
        let hasLinks = MessageLinkDetector.firstURL(in: message.text) != nil
        let maxLines = hasLinks ? 5 : 10

        if #available(iOS 15, *) {
            let bodyBoldFont = AmityTextStyle.bodyBold(.clear).getUIFont()
            let mentionAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: viewConfig.theme.highlightColor,
                .font: bodyBoldFont
            ]
            let linkAttrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: viewConfig.theme.highlightColor,
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
