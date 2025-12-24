//
//  InvitationManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/22/25.
//

import Foundation
import AmitySDK
import Combine

class InvitationManager {
    let repository = AmityInvitationRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func getMyCommunityInvitations() -> AmityCollection<AmityInvitation> {
        return repository.getMyCommunityInvitations()
    }
    
    func getInvitations(targetId: String, targetType: AmityInvitationTargetType) -> AnyPublisher<[AmitySDK.AmityInvitation], Never> {
        return repository.getInvitations(targetId: targetId, targetType: targetType)
    }
}
