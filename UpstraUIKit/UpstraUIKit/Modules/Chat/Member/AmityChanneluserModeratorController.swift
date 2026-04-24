//
//  AmityChanneluserModeratorController.swift
//  AmityUIKit
//
//  Created by min khant on 12/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChannelUserRolesControllerProtocol {
    func getUserRoles(withUserId userId: String, role: AmityChannelRole, completionHandler: @escaping (Bool) -> ())
}

final class AmityChannelUserRolesController: AmityChannelUserRolesControllerProtocol {
    
    private var membersRepo: AmityChannelMembership?
    private var membership: AmityChannelMember?
    private var token: AmityNotificationToken?
    
    init(channelId: String) {
        membersRepo = AmityChannelMembership(channelId: channelId)
    }
    
    func getUserRoles(withUserId userId: String, role: AmityChannelRole, completionHandler: @escaping (Bool) -> ()) {
        token?.invalidate()
        completionHandler(false)
        token = membersRepo?.getMembers(filter: .all, sortBy: .lastCreated, roles: [], includeDeleted: false).observe({ [weak self] collection, error in
            guard let weakSelf = self else { return }
            if error != nil {
                completionHandler(false)
            } else {
                var result = false
                for index in 0..<collection.snapshots.count {
                    let member = collection.snapshots[index]
                    if member.userId == userId {
                        result = member.roles.contains(role.rawValue)
                        break
                    }
                }
                switch collection.dataStatus {
                case .fresh, .error:
                    weakSelf.token?.invalidate()
                default:
                    break
                }
                completionHandler(result)
            }
        })
    }
}
