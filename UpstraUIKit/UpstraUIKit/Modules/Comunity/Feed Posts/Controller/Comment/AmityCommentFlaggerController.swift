//
//  AmityCommentFlaggerController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/14/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommentFlaggerControllerProtocol {
    func report(withCommentId commentId: String, completion: AmityRequestCompletion?)
    func unreport(withCommentId commentId: String, completion: AmityRequestCompletion?)
    func getReportStatus(withCommentId commentId: String, completion: ((Bool) -> Void)?)
}

final class AmityCommentFlaggerController: AmityCommentFlaggerControllerProtocol {
    
    private var flagger: AmityCommentRepository = AmityCommentRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func report(withCommentId commentId: String, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await flagger.flagComment(withId: commentId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func unreport(withCommentId commentId: String, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await flagger.unflagComment(withId: commentId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func getReportStatus(withCommentId commentId: String, completion: ((Bool) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await flagger.isCommentFlaggedByMe(withId: commentId)
                completion?(result)
            } catch let error {
                completion?(false)
            }
        }
    }
}
