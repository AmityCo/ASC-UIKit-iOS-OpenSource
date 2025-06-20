//
//  InvitationManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/22/25.
//

import Foundation
import AmitySDK

class InvitationManager {
    let repository = AmityInvitationRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func getMyCommunityInvitations() -> AmityCollection<AmityInvitation> {
        return repository.getMyCommunityInvitations()
    }
}
