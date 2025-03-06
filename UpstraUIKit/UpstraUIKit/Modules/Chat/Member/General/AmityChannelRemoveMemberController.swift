//
//  AmityChannelRemoveMemberController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 22/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChannelRemoveMemberControllerProtocol {
    func remove(users: [AmityChannelMembershipModel], at indexPath: IndexPath, _ completion: @escaping (AmityError?) -> Void)
}

final class AmityChannelRemoveMemberController: AmityChannelRemoveMemberControllerProtocol {
    
    private var membershipParticipation: AmityChannelMembership?
    
    init(channelId: String) {
        membershipParticipation = AmityChannelMembership(client: AmityUIKitManagerInternal.shared.client, andChannel: channelId)
    }
    
    func remove(users: [AmityChannelMembershipModel], at indexPath: IndexPath, _ completion: @escaping (AmityError?) -> Void) {
        let userId = users[indexPath.row].userId
        Task { @MainActor in
            do {
                let result = try await membershipParticipation?.removeMembers([userId])
                completion(nil)
            } catch let error {
                completion(AmityError(error: error) ?? .unknown)
            }
        }
    }

}
