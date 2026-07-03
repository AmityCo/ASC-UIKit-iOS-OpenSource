//
//  AmityChatMessageQuickReaction.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmityChatMessageQuickReaction: View {
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
                    await viewModel.addQuickReaction(reaction: quickReaction)
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

extension AmityChatMessageQuickReaction {
    
    struct QuickReactionViewModel {
        
        let chatManager = ChatManager()
        let message: MessageModel

        func addQuickReaction(reaction: String) async {
            do {
                try await chatManager.addReaction(reaction, referenceId: message.id, referenceType: .message)
            } catch {
                Log.chat.debug("Error while adding quick reaction \(error)")
            }
        }
        
        func getQuickReaction(viewConfig: AmityViewConfigController) -> String? {
            if let quickReaction = viewConfig.getConfig(elementId: .messageQuickReaction, key: "reactions", of: String.self), let _ = MessageReactionConfiguration.shared.availableReactions[quickReaction] {
                return quickReaction
            }
            return nil
        }
    }
}
