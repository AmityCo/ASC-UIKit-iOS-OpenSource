//
//  AmityMessageComposerViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 26/3/2567 BE.
//

import Foundation
import AmitySDK
import Combine

class AmityMessageComposerViewModel: ObservableObject {
    
    enum ComposerAction {
        case `default`
        case edit(MessageModel)
        case reply(MessageModel)
    }
    
    @Published var action: ComposerAction = .default
    
    let subChannelId: String
    lazy var chatManager = ChatManager()
    
    init(subChannelId: String) {
        self.subChannelId = subChannelId
    }
    
    @MainActor
    func createTextMessage(text: String, mentionData: MentionData) async throws {
        let sanitizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedText.isEmpty else { return }
        
        let createOptions = AmityTextMessageCreateOptions(subChannelId: subChannelId, text: sanitizedText, metadata: mentionData.metadata, mentioneesBuilder: mentionData.mentionee)
        
        let _ = try await chatManager.createTextMessage(options: createOptions)
        
    }
    
    @MainActor
    func createReplyMessage(text: String, mentionData: MentionData) async throws {
        let sanitizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard case let .reply(message) = action, !sanitizedText.isEmpty else { return }
        let createOptions = AmityTextMessageCreateOptions(subChannelId: subChannelId, text: sanitizedText, parentId: message.id, metadata: mentionData.metadata, mentioneesBuilder: mentionData.mentionee)
        
        MessageCache.shared.appendMessage(message: message)
        
        // Reset action first so that reply panel is removed before message list is scrolled.
        self.resetAction()
        
        let _ = try await chatManager.createTextMessage(options: createOptions)
        
    }
    
    @MainActor
    func updateTextMessage(text: String) async throws {
        let sanitizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard case let .edit(message) = action, !sanitizedText.isEmpty else { return }
        
        self.resetAction()
        let _ = try await chatManager.updateTextMessage(messageId: message.id, text: text)
        
    }
    
    func resetAction() {
        self.action = .default
    }
}
