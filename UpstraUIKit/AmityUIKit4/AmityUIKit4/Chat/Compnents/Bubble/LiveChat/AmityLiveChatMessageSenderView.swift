//
//  AmityLiveChatMessageSenderView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 10/4/2567 BE.
//

import SwiftUI

public struct AmityLiveChatMessageSenderView: AmityElementView {
    
    public var pageId: PageId?
    public var componentId: ComponentId?
    public var id: ElementId {
        return .senderMessageBubble
    }
    
    private let config = Configuration.init()
    
    let message: MessageModel
    let messageAction: AmityMessageAction
    
    public init(message: MessageModel, messageAction: AmityMessageAction, pageId: PageId? = .liveChatPage, componentId: ComponentId? = .messageList) {
        self.message = message
        self.messageAction = messageAction
        self.pageId = pageId
        self.componentId = componentId
    }
    
    public var body: some View {
        LiveChatMessageBubbleView(message: message, messageAction: messageAction) {
            VStack (alignment: .leading, spacing: 4) {
                if #available(iOS 15, *) {
                    let attributedText = MentionTextHighlighter.getAttributedText(from: message)
                    Text(attributedText)
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.senderText)
                } else {
                    Text(message.text)
                        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.senderText)
                }
            }
        }
    }
    
    struct Configuration {
        // Load sender text message bubble
    }

}


#if DEBUG
#Preview {
    AmityLiveChatMessageSenderView(message: MessageModel.preview, messageAction: AmityMessageAction(onCopy: nil, onReply: nil, onDelete: nil))
}
#endif
