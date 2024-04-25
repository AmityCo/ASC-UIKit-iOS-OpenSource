//
//  LiveChatMessageBubble.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 28/3/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

struct LiveChatMessageBubble: ViewModifier {
    
    let isBubbleEnabled: Bool
    let message: MessageModel
    
    @ObservedObject var viewModel: LiveChatMessageBubbleViewModel
    
    @EnvironmentObject var viewConfig: AmityViewConfigController

    init(isBubbleEnabled: Bool = true, message: MessageModel, viewModel: LiveChatMessageBubbleViewModel) {
        self.isBubbleEnabled = isBubbleEnabled
        self.message = message
        self.viewModel = viewModel
    }
    
    func body(content: Content) -> some View {
        if isBubbleEnabled {
            if message.parentId != nil, !message.isDeleted {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let repliedMessage = viewModel.repliedMessage {
                            Text(repliedMessage.displayName)
                                .font(.system(size: 13, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color(viewConfig.theme.baseInverseColor))
                                .lineLimit(1)
                            
                            Text(repliedMessage.text)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color(viewConfig.theme.baseColor))
                                .lineLimit(1)
                                .accessibilityIdentifier(message.isOwner ? AccessibilityID.Chat.MessageList.senderReplyText : AccessibilityID.Chat.MessageList.receiverReplyText)
                        } else {
                            Text("")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 100, alignment: .leading)
                                .shimmerEffect(cornerRadius: 16)

                            Text("")
                                .font(.system(size: 13))
                                .frame(width: 150, alignment: .leading)
                                .shimmerEffect(cornerRadius: 16)
                            
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 60 , alignment: .leading)
                    .background(Color(viewConfig.theme.baseColorShade3))
                    .accessibilityIdentifier(message.isOwner ? AccessibilityID.Chat.MessageList.senderReplyTextView : AccessibilityID.Chat.MessageList.receiverReplyTextView)
                    
                    content
                        .font(.system(size: 15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(viewConfig.theme.baseColorShade4))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }
                .clipShape(RoundedCorner(radius: 11, corners: .allCorners))
                
            } else if message.isDeleted {
                content
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .clipShape(RoundedCorner(radius: 11, corners: .allCorners))
            
            } else {
                content
                    .font(.system(size: 15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .clipShape(RoundedCorner(radius: 11, corners: [.bottomLeft, .bottomRight, .topRight]))
            }
        } else {
            content
        }
    }
}

extension View {
    
    func shimmerEffect(cornerRadius: CGFloat) -> some View {
        modifier(ShimeringModifier(cornerRadius: cornerRadius))
            .shimmering()
    }
    
}

struct ShimeringModifier: ViewModifier {
    
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .opacity(0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .padding(.vertical, 3)
            )
    }
}
