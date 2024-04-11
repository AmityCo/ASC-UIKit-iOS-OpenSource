//
//  ChatManager.swift
//  AmityUIKit4
//
//  Created by Nishan on 19/2/2567 BE.
//

import Foundation
import AmitySDK
import OSLog

class ChatManager {
    let repository: AmityMessageRepository
    
    init() {
        self.repository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func queryMessages(options: AmityMessageQueryOptions) -> AmityCollection<AmityMessage> {
        return repository.getMessages(options: options)
    }
    
    @MainActor
    func createTextMessage(options: AmityTextMessageCreateOptions) async throws -> AmityMessage {
        return try await repository.createTextMessage(options: options)
    }

    @MainActor
    func updateTextMessage(messageId: String, text: String) async throws -> Bool {
        return try await repository.editTextMessage(withId: messageId, text)
    }
    
    @MainActor
    func deleteMessage(messageId: String) async throws -> Bool {
        return try await repository.softDeleteMessage(withId: messageId)
    }
    
    @MainActor
    func flagMessage(messageId: String) async throws -> Bool {
        return try await repository.flagMessage(withId: messageId)
    }
    
    @MainActor
    func unflagMessage(messageId: String) async throws -> Bool {
        return try await repository.unflagMessage(withId: messageId)
    }
}
