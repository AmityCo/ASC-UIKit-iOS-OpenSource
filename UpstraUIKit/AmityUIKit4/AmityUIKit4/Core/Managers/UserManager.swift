//
//  UserManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/23/24.
//

import Foundation
import AmitySDK

class UserManager {
    let userRepostiory = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func searchUsers(keyword: String) -> AmityCollection<AmityUser> {
        userRepostiory.searchUsers(keyword, sortBy: .displayName)
    }
    
    func flagUser(withId: String) async throws -> Bool {
        try await userRepostiory.flagUser(withId: withId)
    }
    
    func unflagUser(withId: String) async throws -> Bool {
        try await userRepostiory.unflagUser(withId: withId)
    }
    
    func isUserFlaggedByMe(withId: String) async throws -> Bool {
        try await userRepostiory.isUserFlaggedByMe(withId: withId)
    }
}
