//
//  AmityCommunityAddMemberController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 22/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

enum AmityCommunityAddMemberError {
    case addMemberFailure(AmityError?)
    case removeMemberFailure(AmityError?)
}

protocol AmityCommunityAddMemberControllerProtocol {
    func add(currentUsers: [AmityCommunityMembershipModel], newUsers users: [AmitySelectMemberModel], _ completion: @escaping (_ addMemberError: AmityError?, _ removeMemberError: AmityError?) -> Void)
}

final class AmityCommunityAddMemberController: AmityCommunityAddMemberControllerProtocol {
    
    private var membershipParticipation: AmityCommunityMembership
        
    init(communityId: String) {
        membershipParticipation = AmityCommunityMembership(client: AmityUIKitManagerInternal.shared.client, andCommunityId: communityId)
    }
    
    func add(currentUsers: [AmityCommunityMembershipModel], newUsers users: [AmitySelectMemberModel], _ completion: @escaping (_ addMemberError: AmityError?, _ removeMemberError: AmityError?) -> Void) {
        // get userId
        let currentUserIds = currentUsers.filter { !$0.isCurrentUser}.map { $0.userId }
        let newUserIds = users.map { $0.userId }
        
        // filter userid it has been removed
        let diffRemoveUsers = currentUserIds.filter { !newUserIds.contains($0) }
        // filter userid has been added
        let diffAddUsers = newUserIds.filter { !currentUserIds.contains($0) }
        
        Task { @MainActor in
            var addMemberError: AmityError?
            var removeMemberError: AmityError?
            
            if !diffAddUsers.isEmpty {
                do {
                    let addMemberResult = try await membershipParticipation.addMembers(diffAddUsers)
                } catch let error {
                    addMemberError = AmityError(error: error) ?? .unknown
                }
            }
            
            if !diffRemoveUsers.isEmpty {
                do {
                    let removeMemberResult = try await membershipParticipation.removeMembers(diffRemoveUsers)
                } catch let error {
                    removeMemberError = AmityError(error: error) ?? .unknown
                }
            }
            
            completion(addMemberError, removeMemberError)
        }
    }
}
