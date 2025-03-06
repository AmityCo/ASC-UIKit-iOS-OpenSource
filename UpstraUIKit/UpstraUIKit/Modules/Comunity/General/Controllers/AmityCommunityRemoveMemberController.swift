//
//  AmityCommunityRemoveMemberController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 22/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommunityRemoveMemberControllerProtocol {
    func remove(users: [AmityCommunityMembershipModel], at indexPath: IndexPath, _ completion: @escaping (AmityError?) -> Void)
}

final class AmityCommunityRemoveMemberController: AmityCommunityRemoveMemberControllerProtocol {
    
    private var membershipParticipation: AmityCommunityMembership
    
    init(communityId: String) {
        membershipParticipation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
    }
    
    func remove(users: [AmityCommunityMembershipModel], at indexPath: IndexPath, _ completion: @escaping (AmityError?) -> Void) {
        let userId = users[indexPath.row].userId
        Task { @MainActor in
            do {
                let result = try await membershipParticipation.removeMembers([userId])
                completion(nil)
            } catch let error {
                completion(AmityError(error: error) ?? .unknown)
            }
        }
    }

}
