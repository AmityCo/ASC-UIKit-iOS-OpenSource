//
//  MessageReactionBubble.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import SwiftUI

// Placeholder reactions for now. Refactor this later.
struct MessageReactionBubble: View {
    
    @State var message: MessageModel
    
    var body: some View {
        Button(action: {
            
        }, label: {
            HStack(spacing: 2) {
                if let heartReactionCount = message.reactions?["heart"] as? Int {
                    ReactionLabel(count: "\(heartReactionCount)")
                        .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 0))
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 4)
            .clipped()
            .cornerRadius(20)
        })
        .buttonStyle(.plain)
    }
    
    struct ReactionLabel: View {
        
        let count: String
        
        var body: some View {
            HStack(spacing: 2) {
                AsyncImage(placeholder: ImageResource(name: AmityIcon.Chat.heartReactionIcon.rawValue, bundle: AmityUIKit4Manager.bundle), url: nil)
                    .frame(width: 20, height: 20)

                Text(count)
                    .font(.caption2)
            }
            .frame(height: 28)
            .padding(.horizontal, 6)
            .background(Color(hex: "#40434E"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#if DEBUG
#Preview {
    MessageReactionBubble(message: MessageModel.preview)
}
#endif
