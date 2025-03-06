//
//  AmityCommunityJoinController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 1/8/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommunityJoinControllerProtocol {
    func join(_ completion: @escaping (AmityError?) -> Void)
}

final class AmityCommunityJoinController: AmityCommunityJoinControllerProtocol {
    
    private let repository: AmityCommunityRepository
    private let communityId: String
    
    init(withCommunityId _communityId: String) {
        communityId = _communityId
        repository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func join(_ completion: @escaping (AmityError?) -> Void) {
        Task { @MainActor in
            do {
                let _ = try await repository.joinCommunity(withId: communityId)
                completion(nil)
            } catch let error {
                completion(AmityError(error: error))
            }
        }
    }
    
}

