//
//  AmityCommunityRoleController.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 1/5/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommunityRoleControllerProtocol {
    func add(roles: [String], userIds: [String], completion: ((AmityError?) -> Void)?)
    func remove(roles: [String], userIds: [String], completion: ((AmityError?) -> Void)?)
}

final class AmityCommunityRoleController: AmityCommunityRoleControllerProtocol {
    
    private let moderation: AmityCommunityModeration
    
    init(communityId: String) {
        moderation = AmityCommunityModeration(client: AmityUIKitManagerInternal.shared.client, andCommunity: communityId)
    }
    
    // Add role permisstion to users
    func add(roles: [String], userIds: [String], completion: ((AmityError?) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await moderation.addRoles(roles, userIds: userIds)
                completion?(nil)
            } catch let error {
                completion?(AmityError(error: error))
            }
        }
    }
    
    // Remove role permisstion from users
    func remove(roles: [String], userIds: [String], completion: ((AmityError?) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await moderation.removeRoles(roles, userIds: userIds)
                completion?(nil)
            } catch let error {
                completion?(AmityError(error: error))
            }
        }
    }
}
