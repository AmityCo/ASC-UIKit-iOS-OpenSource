//
//  AmityUserPendingFollowRequestsPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/26/24.
//

import Foundation
import AmitySDK
import Combine

class AmityUserPendingFollowRequestsPageViewModel: ObservableObject {
    @Published var users: [AmityUser] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    
    private let userId: String
    private let userManager = UserManager()
    private var userCollection: AmityCollection<AmityFollowRelationship>?
    var cancellables = Set<AnyCancellable>()
    
    init(_ userId: String) {
        self.userId = userId
        getPendingFollowers()
    }
    
    func getPendingFollowers() {
        userCollection = userManager.getMyFollowers(.pending)
        userCollection?.$snapshots
            .map { $0.compactMap { $0.sourceUser } }
            .assign(to: &$users)
        
        userCollection?.$loadingStatus
            .assign(to: &$loadingStatus)
    }
    
    func loadMore() {
        if let userCollection, userCollection.hasNext {
            userCollection.nextPage()
        }
    }
    
    @discardableResult
    func acceptMyFollower(_ userId: String) async throws -> Bool {
        try await userManager.acceptMyFollower(withId: userId).0
    }
    
    @discardableResult
    func declineMyFollower(_ userId: String) async throws -> Bool {
        try await userManager.declineMyFollower(withId: userId).0
    }
}
