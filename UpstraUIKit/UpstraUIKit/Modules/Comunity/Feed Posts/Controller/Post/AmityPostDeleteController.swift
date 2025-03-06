//
//  AmityPostDeleteController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/13/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityPostDeleteControllerProtocol {
    func delete(withPostId postId: String, parentId: String?, completion: AmityRequestCompletion?)
}

final class AmityPostDeleteController: AmityPostDeleteControllerProtocol {
    private let repository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func delete(withPostId postId: String, parentId: String?, completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                let result = try await repository.softDeletePost(withId: postId, parentId: parentId)
                completion?(result, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
}
