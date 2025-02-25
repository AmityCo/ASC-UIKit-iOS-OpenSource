//
//  AmityLiveChatMessageReactionPicker.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI
import AmitySDK

public struct AmityLiveChatMessageReactionPicker: AmityElementView {
        
    @EnvironmentObject var viewConfig: AmityViewConfigController

    public var pageId: PageId?
    public var componentId: ComponentId?
    public var id: ElementId {
        return .messageReactionPicker
    }

    let dismissAction: DefaultTapAction?
    
    let message: MessageModel
    
    @StateObject var viewModel: AmityLiveChatMessageReactionPickerViewModel
    
    public init(message: MessageModel, pageId: PageId? = .liveChatPage, componentId: ComponentId? = .messageList, tapAction: DefaultTapAction? = nil) {
        self.message = message
        self.pageId = pageId
        self.componentId = componentId
        self._viewModel = StateObject(wrappedValue: AmityLiveChatMessageReactionPickerViewModel(message: message))
        self.dismissAction = tapAction
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(MessageReactionConfiguration.shared.allReactions, id: \.id) { reaction in
                
                Button(action: {
                    ImpactFeedbackGenerator.impactFeedback(style: .medium)
                    
                    // Message should be synced before adding reaction
                    guard message.syncState == .synced else { return }
                    
                    if viewModel.message.myReactions.contains(where: {$0 == reaction.name}) {
                        viewModel.removeRaction(reaction: reaction.name)
                    } else {
                        viewModel.addReaction(reaction: reaction.name)
                    }
                    dismissAction?()
                }, label: {
                    ZStack {
                        Color(viewConfig.theme.baseColorShade2)
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                            .opacity(viewModel.message.myReactions.contains(where: {$0 == reaction.name}) ? 1 : 0)
                        
                        Image(reaction.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                })
                .accessibilityIdentifier(reaction.accessibilityId)
            }
        }
        .font(.title)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(viewConfig.theme.baseColorShade4))
        .cornerRadius(30)
        
    }
}



class AmityLiveChatMessageReactionPickerViewModel: ObservableObject {
    @Published var message: MessageModel
    
    private let reactionRepo = AmityReactionRepository(client: AmityUIKit4Manager.client)
    
    init(message: MessageModel) {
        self.message = message
    }
    
    @MainActor
    public func addReaction(reaction: String) {
        Task {
            // We only allow 1 reaction at a time so we need to remove the previous one
            do {
                if let currentReaction = message.myReactions.first {
                    try await removeReactionInternal(reaction: currentReaction)
                }
                
                let _ = try await reactionRepo.addReaction(reaction, referenceId: message.id, referenceType: .message)
            } catch {
                Log.chat.debug("Error while adding reaction \(error)")
            }
        }
    }
    
    @MainActor
    public func removeRaction(reaction: String) {
        Task {
            do {
                try await removeReactionInternal(reaction: reaction)
            } catch {
                Log.chat.debug("Error while removing reaction \(error)")
            }
        }
    }
    
    private func removeReactionInternal(reaction: String) async throws {
        
        let _ = try await reactionRepo.removeReaction(reaction, referenceId: message.id, referenceType: .message)
        
    }
}

