//
//  MessageReactionBubble.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

// Placeholder reactions for now. Refactor this later.
struct AmityLiveChatMessageReactionPreview: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var message: MessageModel
    let viewModel: AmityLiveChatMessageReactionPreviewViewModel
    
    init(message: MessageModel) {
        self.message = message
        self.viewModel = AmityLiveChatMessageReactionPreviewViewModel(message: message)
    }
    
    var body: some View {
        Button(action: {
            
        }, label: {
            HStack(spacing: 2) {

                ForEach(Array(viewModel.topThreeReactions.enumerated()), id: \.element) { index, reactionName in
                    
                    ReactionLabel(image: viewModel.getReactionImage(reactionName: reactionName))
                        .padding(EdgeInsets(top: 4, leading: index == 0 ? 6 : -12, bottom: 4, trailing: 0))
                        .zIndex(Double(viewModel.topThreeReactions.count - index))
                }
                
                Text(message.reactionCount.formattedCountString)
                    .font(.caption2)
                    .padding(.trailing, 6)
            }
            .frame(height: 28)
            .background(Color(viewConfig.theme.baseColorShade3))
            .clipped()
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white, lineWidth: 1)
                    .opacity(!message.myReactions.isEmpty ? 1 : 0)
            )
        })
        .buttonStyle(.plain)
        
        
    }
    
    struct ReactionLabel: View {
        
        let image: ImageResource
        
        var body: some View {
            HStack(spacing: 2) {
                
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

            }
        }
    }
}

class AmityLiveChatMessageReactionPreviewViewModel {
    var topThreeReactions: [String] = []
    
    init(message: MessageModel) {
        
        if let reactions = message.reactions as? [String: Int] {
            let filteredReactions = reactions.filter { $0.value > 0 }
            let sortedReactions = filteredReactions.sorted {
                // Sort keys alphabetically if values are the same
                if $0.value == $1.value {
                    return $0.key < $1.key
                }
                return $0.value > $1.value
            }.prefix(3).map { ($0.key) }
            
            topThreeReactions = sortedReactions
            
        }
    }
    
    func getReactionImage(reactionName: String) -> ImageResource {
        if let reaction = MessageReactionConfiguration.shared.getMessageRactions().first(where: {$0.name == reactionName}) {
            return reaction.image
        } else {
            return AmityIcon.Chat.messageReactionNotFound.imageResource
        }
    }
}

#if DEBUG
#Preview {
    AmityLiveChatMessageReactionPreview(message: MessageModel.preview)
}
#endif
