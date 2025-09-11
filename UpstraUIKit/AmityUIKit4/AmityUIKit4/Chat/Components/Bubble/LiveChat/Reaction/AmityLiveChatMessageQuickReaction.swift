//
//  AmityLiveChatMessageQuickReaction.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 23/5/2567 BE.
//

import SwiftUI
import AmitySDK

public struct AmityLiveChatMessageQuickReaction: View {
    let message: MessageModel
    
    let viewModel: QuickReactionViewModel
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    public init(message: MessageModel) {
        self.message = message
        self.viewModel = QuickReactionViewModel(message: message)
    }
    
    
    public var body: some View {
        
        if let quickReaction = viewModel.getQuickReaction(viewConfig: viewConfig) {
            let isAvailable = message.myReactions.isEmpty && message.syncState == .synced
            
            Button {
                Task {
                    await viewModel.addQuickRaction(reaction: quickReaction)
                }
            } label: {
                Image(AmityIcon.Chat.messageBubbleAddReactionIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
            }
            .padding(.bottom, 6)
            .padding(.leading, 6)
            .accessibilityIdentifier(AccessibilityID.Chat.MessageList.quickReaction)
            .isHidden(!isAvailable)
        }
        

    }
    

}

extension AmityLiveChatMessageQuickReaction {
    
    struct QuickReactionViewModel {
        
        let reactionRepo = AmityReactionRepository(client: AmityUIKit4Manager.client)
        let message: MessageModel
        
        func addQuickRaction(reaction: String) async {
            do {
                let _ = try await reactionRepo.addReaction(reaction, referenceId: message.id, referenceType: .message)
            } catch {
                Log.chat.debug("Error while adding quick reaction \(error)")
            }
        }
        
        func getQuickReaction(viewConfig: AmityViewConfigController) -> String? {
            
            /// Quick reaction need to be available in message_quick_reaction config
            /// And the reaction name should be in one of message_reactions config.
            if let quickReaction = viewConfig.getConfig(elementId: .messageQuickReaction, key: "reactions", of: String.self), let _ = MessageReactionConfiguration.shared.availableReactions[quickReaction] {
                return quickReaction
            }
            
            return nil
        }
        
    }
}
