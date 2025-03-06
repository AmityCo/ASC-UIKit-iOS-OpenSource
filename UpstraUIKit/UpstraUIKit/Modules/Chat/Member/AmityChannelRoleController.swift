//
//  AmityChannelRoleController.swift
//  AmityUIKit
//
//  Created by min khant on 12/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChannelRoleControllerProtocol {
    func add(role: AmityChannelRole, userIds: [String], completion: ((AmityError?) -> Void)?)
    func remove(role: AmityChannelRole, userIds: [String], completion: ((AmityError?) -> Void)?)
}

final class AmityChannelRoleController: AmityChannelRoleControllerProtocol {
    
    private var moderation: AmityChannelModeration?
    
    init(channelId: String) {
        moderation = AmityChannelModeration(client: AmityUIKitManagerInternal.shared.client, andChannel: channelId)
    }
    
    // Add role permisstion to users
    func add(role: AmityChannelRole, userIds: [String], completion: ((AmityError?) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await moderation?.addRole(role.rawValue, userIds: userIds)
                completion?(nil)
            } catch let error {
                completion?(AmityError(error: error))
            }
        }
    }
    
    // Remove role permisstion from users
    func remove(role: AmityChannelRole, userIds: [String], completion: ((AmityError?) -> Void)?) {
        Task { @MainActor in
            do {
                let result = try await moderation?.removeRole(role.rawValue, userIds: userIds)
                completion?(nil)
            } catch let error {
                completion?(AmityError(error: error))
            }
        }
    }

}
