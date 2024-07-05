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
}
