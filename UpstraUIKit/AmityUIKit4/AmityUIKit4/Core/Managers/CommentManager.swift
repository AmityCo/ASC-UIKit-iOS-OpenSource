//
//  CommentManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation
import AmitySDK

class CommentManager {
    private let commentRepository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
    

    func getComments(queryOptions: AmityCommentQueryOptions) -> AmityCollection<AmityComment> {
        return commentRepository.getComments(with: queryOptions)
    }
    
    func getComment(commentId: String) -> AmityObject<AmityComment> {
        return commentRepository.getComment(withId: commentId)
    }
    
    @MainActor
    @discardableResult
    func createComment(createOptions: AmityCommentCreateOptions) async throws -> AmityComment {
        try await commentRepository.createComment(with: createOptions)
    }
    
    @MainActor
    @discardableResult
    func deleteComment(withId commentId: String) async throws -> Bool {
        try await commentRepository.softDeleteComment(withId: commentId)
    }
    
    @MainActor
    @discardableResult
    func editComment(withId commentId: String, options: AmityCommentUpdateOptions) async throws -> AmityComment {
        try await commentRepository.editComment(withId: commentId, options: options)
    }
    
    @MainActor
    @discardableResult
    func flagComment(withId commentId: String) async throws -> Bool {
        try await commentRepository.flagComment(withId: commentId)
    }
    
    @MainActor
    @discardableResult
    func unflagComment(withId commentId: String) async throws -> Bool {
        try await commentRepository.unflagComment(withId: commentId)
    }
    
    @MainActor
    func isCommentFlaggedByMe(withId commentId: String) async throws -> Bool {
        try await commentRepository.isCommentFlaggedByMe(withId: commentId)
    }
}
