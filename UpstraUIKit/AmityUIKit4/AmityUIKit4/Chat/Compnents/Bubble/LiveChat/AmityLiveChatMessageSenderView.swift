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
            VStack(alignment: .leading, spacing: 4) {
                textContent
                    .accessibilityIdentifier(AccessibilityID.Chat.MessageList.senderText)
            }
        }
    }
    
    @ViewBuilder
    var textContent: some View {
        if #available(iOS 15, *) {
            let attributedText = TextHighlighter.getAttributedText(from: message)
            Text(attributedText)
        } else {
            Text(message.text)
        }
    }
}


#if DEBUG
#Preview {
    AmityLiveChatMessageSenderView(message: MessageModel.preview, messageAction: AmityMessageAction(onCopy: nil, onReply: nil, onDelete: nil, onReport: nil, onUnReport: nil))
}
#endif
