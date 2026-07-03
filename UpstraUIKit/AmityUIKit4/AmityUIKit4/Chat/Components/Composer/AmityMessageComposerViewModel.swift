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
    func updateTextMessage(text: String, mentionData: MentionData) async throws {
        let sanitizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard case let .edit(message) = action, !sanitizedText.isEmpty else { return }
        
        self.resetAction()
        let _ = try await chatManager.updateTextMessage(messageId: message.id, text: sanitizedText, metadata: mentionData.metadata, mentionees: mentionData.mentionee)
        
    }
    
    func resetAction() {
        self.action = .default
    }
    
    @MainActor
    func createImageMessage(imageURL: URL) async throws {
        let parentId: String? = {
            if case let .reply(message) = action { return message.id }
            return nil
        }()
        if parentId != nil { resetAction() }
        LocalImageThumbnailCache.cache(imageURL: imageURL)
        let _ = try await chatManager.createImageMessage(subChannelId: subChannelId, imageURL: imageURL, parentId: parentId)
    }

    @MainActor
    func createVideoMessage(videoURL: URL) async throws {
        let parentId: String? = {
            if case let .reply(message) = action { return message.id }
            return nil
        }()
        if parentId != nil { resetAction() }
        let localThumbURL: URL? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let url = LocalVideoThumbnailCache.generateAndCache(videoURL: videoURL)
                continuation.resume(returning: url)
            }
        }
        let createdMessage = try await chatManager.createVideoMessage(subChannelId: subChannelId, videoURL: videoURL, parentId: parentId)
        if let localThumbURL {
            LocalVideoThumbnailCache.associate(thumbnailURL: localThumbURL, withId: createdMessage.uniqueId)
            LocalVideoThumbnailCache.associate(thumbnailURL: localThumbURL, withId: createdMessage.messageId)
        }
    }

    @MainActor
    func createFileMessage(fileURL: URL, fileName: String? = nil) async throws {
        let parentId: String? = {
            if case let .reply(message) = action { return message.id }
            return nil
        }()
        if parentId != nil { resetAction() }
        let _ = try await chatManager.createFileMessage(subChannelId: subChannelId, fileURL: fileURL, fileName: fileName, parentId: parentId)
    }
}
