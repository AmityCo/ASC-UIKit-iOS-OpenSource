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
    let channelRepository: AmityChannelRepository
    
    init() {
        self.repository = AmityMessageRepository(client: AmityUIKitManagerInternal.shared.client)
        self.channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func queryMessages(options: AmityMessageQueryOptions) -> AmityCollection<AmityMessage> {
        return repository.getMessages(options: options)
    }
    
    func getMessage(messageId: String) -> AmityObject<AmityMessage> {
        return repository.getMessage(messageId)
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
    
    func getChannel(channelId: String) -> AmityChannel? {
        return channelRepository.getChannel(channelId).snapshot
    }
    
    func getCurrentUserChannelMember(channelId: String) -> AmityChannelMember? {
        return channelRepository.getChannel(channelId).snapshot?.currentMembership
    }
}
