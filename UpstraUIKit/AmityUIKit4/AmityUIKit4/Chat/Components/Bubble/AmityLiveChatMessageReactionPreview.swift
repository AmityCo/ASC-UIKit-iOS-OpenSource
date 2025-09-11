//
//  AmityLiveChatMessageReactionPreview.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

public struct AmityLiveChatMessageReactionPreview: View {
    
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
                
                // Total reaction count
                Text("\(message.reactionCount.formattedCountString)")
                    .font(.system(size: 13))
                    .fontWeight(.medium)
                    .foregroundColor(message.myReactions.isEmpty ? Color(viewConfig.theme.baseInverseColor) : .white)
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

class MessageReactionPreviewViewModel {
    // Reactions
    var topThreeReactions: [AmityReactionType] = []
    
    init(message: MessageModel) {
        if let reactions = message.reactions {
            
            let filteredReactions = reactions.filter { $0.value > 0 }
            
            // In descending order of reaction count.
            let sortedReactions = filteredReactions.sorted {
                // If reaction count is same, sort based on key name
                if $0.value == $1.value {
                    return $0.key < $1.key
                }
                return $0.value > $1.value
            }.prefix(3)
                            
            let reactionConfig = MessageReactionConfiguration.shared
            topThreeReactions = sortedReactions.map { reactionConfig.getReaction(withName: $0.key) }
        }
    }
}

#if DEBUG
#Preview {
    AmityLiveChatMessageReactionPreview(message: MessageModel.preview, tapAction: { })
}
#endif
