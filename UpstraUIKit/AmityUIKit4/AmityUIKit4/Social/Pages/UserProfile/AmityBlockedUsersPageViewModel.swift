//
//  AmityBlockedUsersPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/25/24.
//

import Foundation
import AmitySDK

class AmityBlockedUsersPageViewModel: ObservableObject {
    @Published var blockedUsers: [AmityUser] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
   
    private let userId: String
    private let blockedUserCollection: AmityCollection<AmityUser>
    private let userManager = UserManager()
    
    init(_ userId: String) {
        self.userId = userId
        self.blockedUserCollection = userManager.getBlockedUsers()
        
        self.blockedUserCollection
            .$snapshots
            .assign(to: &$blockedUsers)
        
        self.blockedUserCollection
            .$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func loadMore() {
        guard blockedUserCollection.hasNext else { return }
        blockedUserCollection.nextPage()
    }
    
    func unblockUser(withId: String) async throws {
        try await userManager.unblockUser(withId: withId)
    }
}
