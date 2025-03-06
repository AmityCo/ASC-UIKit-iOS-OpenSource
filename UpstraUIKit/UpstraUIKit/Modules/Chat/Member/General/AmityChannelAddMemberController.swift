//
//  AmityChannelAddMemberController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 22/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChannelAddMemberControllerProtocol {
    func add(currentUsers: [AmityChannelMembershipModel], newUsers users: [AmitySelectMemberModel], _ completion: @escaping (_ addMemberError: AmityError?, _ removeMemberError: AmityError?) -> Void)
}

final class AmityChannelAddMemberController: AmityChannelAddMemberControllerProtocol {
    
    private var membershipParticipation: AmityChannelMembership
    
    init(channelId: String) {
        membershipParticipation = AmityChannelMembership(client: AmityUIKitManagerInternal.shared.client, andChannel: channelId)
    }
    
    func add(currentUsers: [AmityChannelMembershipModel], newUsers users: [AmitySelectMemberModel], _ completion: @escaping (AmityError?, AmityError?) -> Void) {
        // get userId
        let currentUserIds = currentUsers.filter { !$0.isCurrentUser}.map { $0.userId }
        let newUserIds = users.map { $0.userId }
        
        // filter userid it has been removed
        let difRemoveUsers = currentUserIds.filter { !newUserIds.contains($0) }
        // filter userid has been added
        let difAddUsers = newUserIds.filter { !currentUserIds.contains($0) }
        
        Task { @MainActor in
            var addMemberError: AmityError?
            var removeMemberError: AmityError?
            
            if !difAddUsers.isEmpty {
                do {
                    let memberResult = try await membershipParticipation.addMembers(difAddUsers)
                } catch let error {
                    addMemberError = AmityError(error: error) ?? .unknown
                }
            }
            
            if !difRemoveUsers.isEmpty {
                do {
                    let removeMemberResult = try await membershipParticipation.removeMembers(difRemoveUsers)
                } catch let error {
                    removeMemberError = AmityError(error: error) ?? .unknown
                }
            }
            
            completion(addMemberError, removeMemberError)
        }
    }
}
