//
//  AmityPostFlaggerController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/14/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityPostFlaggerControllerProtocol {
    func report(withPostId postId: String, completion: AmityRequestCompletion?)
    func unreport(withPostId postId: String, completion: AmityRequestCompletion?)
    func getReportStatus(withPostId postId: String, completion: ((Bool) -> Void)?)
}

final class AmityPostFlaggerController: AmityPostFlaggerControllerProtocol {
    private let flagger: AmityPostRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func report(withPostId postId: String, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await flagger.flagPost(withId: postId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func unreport(withPostId postId: String, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await flagger.unflagPost(withId: postId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    func getReportStatus(withPostId postId: String, completion: ((Bool) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await flagger.isFlaggedByMe(withId: postId)
                completion?(result)
            } catch let error {
                completion?(false)
            }
        }
    }
}
