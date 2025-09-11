//
//  ReactionManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/25/24.
//

import Foundation
import AmitySDK
import Combine

public enum ReactionType: String {
    case like
}

class ReactionManager {
    
    private let reactionRepository = AmityReactionRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createLiveReaction(_ reaction: String, referenceId: String, referenceType: AmityLiveReactionReferenceType, streamId: String) {
        reactionRepository.createReaction(reaction, referenceId: referenceId, referenceType: referenceType, streamId: streamId)
    }
    
    func getLiveReactions(referenceId: String, referenceType: AmityLiveReactionReferenceType, streamId: String) -> AnyPublisher<[AmityLiveReaction], Never> {
        reactionRepository.getReactions(referenceId, referenceType: referenceType, streamId: streamId)
    }
    
    @MainActor
    @discardableResult
    func addReaction(_ reactionType: ReactionType, referenceId: String, referenceType: AmityReactionReferenceType) async throws -> Bool {
        return try await reactionRepository.addReaction(reactionType.rawValue, referenceId: referenceId, referenceType: referenceType)
    }
    
    @MainActor
    @discardableResult
    func removeReaction(_ reactionType: ReactionType, referenceId: String, referenceType: AmityReactionReferenceType) async throws -> Bool {
        return try await reactionRepository.removeReaction(reactionType.rawValue, referenceId: referenceId, referenceType: referenceType)
    }
    
    @MainActor
    @discardableResult
    func addReaction(_ reaction: String, referenceId: String, referenceType: AmityReactionReferenceType) async throws -> Bool {
        return try await reactionRepository.addReaction(reaction, referenceId: referenceId, referenceType: referenceType)
    }
    
    @MainActor
    @discardableResult
    func removeReaction(_ reaction: String, referenceId: String, referenceType: AmityReactionReferenceType) async throws -> Bool {
        return try await reactionRepository.removeReaction(reaction, referenceId: referenceId, referenceType: referenceType)
    }
    
    func getReactions(_ reactionType: String?, referenceId: String, referenceType: AmityReactionReferenceType) -> AmityCollection<AmityReaction> {
        return reactionRepository.getReactions(referenceId, referenceType: referenceType, reactionName: reactionType)
    }
}
