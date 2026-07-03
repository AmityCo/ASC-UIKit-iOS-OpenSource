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
    let reactionRepository: AmityReactionRepository

    init() {
        self.repository = AmityMessageRepository()
        self.channelRepository = AmityChannelRepository()
        self.reactionRepository = AmityReactionRepository()
    }

    func queryMessages(options: AmityMessageQueryOptions) -> AmityCollection<AmityMessage> {
        return repository.getMessages(options: options)
    }

    func searchMessages(options: AmityMessageSearchOptions) -> AmityCollection<AmityMessage> {
        return repository.searchMessages(options: options)
    }

    func getMessage(messageId: String) -> AmityObject<AmityMessage> {
        return repository.getMessage(messageId)
    }

    func isMessageFlaggedByMe(messageId: String) async throws -> Bool {
        return try await repository.isMessageFlaggedByMe(withId: messageId)
    }
    
    @MainActor
    func createImageMessage(subChannelId: String, imageURL: URL, parentId: String? = nil) async throws -> AmityMessage {
        let attachment = AmityMessageAttachment.localURL(url: imageURL)
        let options = AmityImageMessageCreateOptions(
            subChannelId: subChannelId,
            attachment: attachment,
            fullImage: true,
            parentId: parentId
        )
        return try await repository.createImageMessage(options: options)
    }

    @MainActor
    func createVideoMessage(subChannelId: String, videoURL: URL, parentId: String? = nil) async throws -> AmityMessage {
        let attachment = AmityMessageAttachment.localURL(url: videoURL)
        let options = AmityVideoMessageCreateOptions(
            subChannelId: subChannelId,
            attachment: attachment,
            parentId: parentId
        )
        return try await repository.createVideoMessage(options: options)
    }

    @MainActor
    func createFileMessage(subChannelId: String, fileURL: URL, fileName: String? = nil, parentId: String? = nil) async throws -> AmityMessage {
        let attachment = AmityMessageAttachment.localURL(url: fileURL)
        let options = AmityFileMessageCreateOptions(
            subChannelId: subChannelId,
            attachment: attachment,
            fileName: fileName ?? fileURL.lastPathComponent,
            parentId: parentId
        )
        return try await repository.createFileMessage(options: options)
    }
    
    @MainActor
    func createTextMessage(options: AmityTextMessageCreateOptions) async throws -> AmityMessage {
        return try await repository.createTextMessage(options: options)
    }

    @MainActor
    func updateTextMessage(messageId: String, text: String, metadata: [String: Any]? = nil, mentionees: AmityMentioneesBuilder? = nil) async throws {
        return try await repository.editTextMessage(withId: messageId, text, metadata: metadata, mentionees: mentionees)
    }
    
    @MainActor
    func deleteMessage(messageId: String) async throws {
        return try await repository.softDeleteMessage(withId: messageId)
    }

    @MainActor
    func flagMessage(messageId: String) async throws {
        return try await repository.flagMessage(withId: messageId)
    }
    
    @MainActor
    func flagMessage(messageId: String, reason: AmityContentFlagReason) async throws {
        return try await repository.flagMessage(withId: messageId, reason: reason)
    }
    
    @MainActor
    func unflagMessage(messageId: String) async throws {
        return try await repository.unflagMessage(withId: messageId)
    }
    
    func getChannel(channelId: String) -> AmityChannel? {
        return channelRepository.getChannel(channelId).snapshot
    }

    func getCurrentUserChannelMember(channelId: String) -> AmityChannelMember? {
        return channelRepository.getChannel(channelId).snapshot?.currentMember
    }

    // MARK: - Reactions

    @MainActor
    func addReaction(_ reaction: String, referenceId: String, referenceType: AmityReactionReferenceType = .message) async throws {
        try await reactionRepository.addReaction(reaction, referenceId: referenceId, referenceType: referenceType)
    }

    @MainActor
    func removeReaction(_ reaction: String, referenceId: String, referenceType: AmityReactionReferenceType = .message) async throws {
        try await reactionRepository.removeReaction(reaction, referenceId: referenceId, referenceType: referenceType)
    }
}
