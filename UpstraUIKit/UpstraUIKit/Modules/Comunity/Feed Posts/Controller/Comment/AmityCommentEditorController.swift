//
//  AmityCommentEditorController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommentEditorControllerProtocol {
    func delete(withCommentId commentId: String, completion: AmityRequestCompletion?)
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?, completion: AmityRequestCompletion?)
}

final class AmityCommentEditorController: AmityCommentEditorControllerProtocol {
    
    private var commentRepository: AmityCommentRepository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func delete(withCommentId commentId: String, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await commentRepository.softDeleteComment(withId: commentId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
        
    func edit(withComment comment: AmityCommentModel, text: String, metadata: [String : Any]?, mentionees: AmityMentioneesBuilder?, completion: AmityRequestCompletion?) {
        let options = AmityCommentUpdateOptions(text: text, metadata: metadata, mentioneesBuilder: mentionees)
        
        Task { @MainActor in
            do {
                let result = try await commentRepository.editComment(withId: comment.id, options: options)
                completion?(true, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
}
