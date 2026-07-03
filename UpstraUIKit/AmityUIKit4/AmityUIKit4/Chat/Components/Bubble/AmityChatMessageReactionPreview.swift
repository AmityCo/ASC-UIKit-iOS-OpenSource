//
//  AmityChatMessageReactionPreview.swift
//  AmityUIKit4
//

import SwiftUI

public struct AmityChatMessageReactionPreview: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let message: MessageModel
    let viewModel: MessageReactionPreviewViewModel
    let action: DefaultTapAction?
        
    public init(message: MessageModel, tapAction: DefaultTapAction? = nil) {
        self.message = message
        self.viewModel = MessageReactionPreviewViewModel(message: message)
        self.action = tapAction
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack(spacing: 2) {
                
                ForEach(Array(viewModel.topThreeReactions.enumerated()), id: \.element.id) { index, reaction in
                    ReactionLabel(image: reaction.image)
                        .padding(EdgeInsets(top: 4, leading: index == 0 ? 6 : -10, bottom: 4, trailing: 0))
                        .zIndex(Double(viewModel.topThreeReactions.count - index))
                }
                
                Text("\(message.reactionCount.formattedCountString)")
                    .applyTextStyle(.custom(13, .medium, message.myReactions.isEmpty ? Color(viewConfig.theme.baseInverseColor) : .white))
                    .padding(.trailing, 8)
                    .padding(.leading, 2)
            }
            .frame(height: 28)
            .background(message.myReactions.isEmpty ? Color(viewConfig.theme.backgroundShade1Color) : Color(viewConfig.theme.highlightColor))
            .clipped()
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
            )
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.reactionPreview)
        })
        .buttonStyle(.plain)
    }
    
    struct ReactionLabel: View {
        let image: ImageResource
        
        var body: some View {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}

#if DEBUG
#Preview {
    AmityChatMessageReactionPreview(message: MessageModel.preview, tapAction: { })
}
#endif
