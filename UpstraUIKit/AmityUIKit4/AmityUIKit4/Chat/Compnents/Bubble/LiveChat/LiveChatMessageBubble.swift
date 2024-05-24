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
                                .shimmerEffect(cornerRadius: 16, color: viewConfig.theme.baseInverseColor)

                            Text("")
                                .font(.system(size: 13))
                                .frame(width: 150, alignment: .leading)
                                .shimmerEffect(cornerRadius: 16, color: viewConfig.theme.baseInverseColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 60 , alignment: .leading)
                    .background(Color(viewConfig.theme.backgroundShade1Color))
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
    
    // Deprecate this: Use text shimmer effect
    func shimmerEffect(cornerRadius: CGFloat, color: UIColor) -> some View {
        modifier(AmityTextShimmer(isActive: true, cornerRadius: cornerRadius, color: color))
    }
    
    /// Applies rounded rectange overlay with corner radius and then apply shimmering effect.
    /// Note: This might not produce the require result when applied on circular image.
    func textShimmerEffect(cornerRadius: CGFloat, isActive: Bool, color: UIColor) -> some View {
        modifier(AmityTextShimmer(isActive: isActive, cornerRadius: cornerRadius, color: color))
    }
}

/// Adds shimmering effect to text with rounded corner radius
struct AmityTextShimmer: ViewModifier {
    
    let isActive: Bool
    let cornerRadius: CGFloat
    let color: UIColor
    
    func body(content: Content) -> some View {
        if !isActive {
            content
        } else {
            content
                .opacity(0)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(color).opacity(0.1))
                        .padding(.vertical, 3)
                )
                .shimmering()
        }
    }
}
