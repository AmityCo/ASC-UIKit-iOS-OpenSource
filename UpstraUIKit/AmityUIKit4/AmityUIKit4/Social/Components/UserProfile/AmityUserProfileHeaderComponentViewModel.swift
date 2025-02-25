//
//  AmityUserProfileHeaderComponentViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/18/24.
//

import Combine
import AmitySDK
import Foundation

class AmityUserProfileHeaderComponentViewModel: ObservableObject {
    @Published var followInfo: AmityFollowInfoModel? = nil
    @Published var followRequestCount: Int = 0
    
    private let userId: String
    private var myFollowInfoObject: AmityObject<AmityMyFollowInfo>?
    private var userFollowInfoObject: AmityObject<AmityUserFollowInfo>?
    private var pendingFollowerCollection: AmityCollection<AmityFollowRelationship>?
    private let userManager = UserManager()
    
    private var isOwnUser: Bool {
        AmityUIKitManagerInternal.shared.currentUserId == userId
    }
    
    init(_ userId: String) {
        self.userId = userId
        self.load()
    }
    
    func load() {
        if isOwnUser {
            myFollowInfoObject = userManager.getMyFollowInfo()
            myFollowInfoObject?.$snapshot
                .map { $0.flatMap { AmityFollowInfoModel($0) }}
                .assign(to: &$followInfo)
        } else {
            userFollowInfoObject = userManager.getFollowInfo(withId: userId)
            userFollowInfoObject?.$snapshot
                .map { $0.flatMap { AmityFollowInfoModel($0) }}
                .assign(to: &$followInfo)
        }
        
        pendingFollowerCollection = userManager.getMyFollowers(.pending)
        
        pendingFollowerCollection?.$snapshots
            .map { $0.count }
            .assign(to: &$followRequestCount)
    }
    
    @discardableResult
    func follow() async throws -> Bool {
        try await userManager.followUser(withId: userId).0
    }
    
    @discardableResult
    func unfollow() async throws -> Bool {
        try await userManager.unfollowUser(withId: userId).0
    }
    
    func unblock() async throws {
        try await userManager.unblockUser(withId: userId)
    }
}
