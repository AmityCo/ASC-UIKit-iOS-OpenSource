//
//  UserManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/23/24.
//

import Foundation
import AmitySDK
import UIKit

class UserManager {
    let userRepostiory = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func searchUsers(keyword: String) -> AmityCollection<AmityUser> {
        userRepostiory.searchUsers(keyword, sortBy: .displayName)
    }
    
    func editUser(user: UserModel) async throws -> Bool {
        let builder = AmityUserUpdateBuilder()
        builder.setUserDescription(user.about)
        
        if let avatar = user.avatar {
            let imageData = try await fileRepository.uploadImage(avatar, progress: nil)
            builder.setAvatar(imageData)
        }
        
        return try await AmityUIKitManagerInternal.shared.client.editUser(builder)
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
    
    func getMyFollowInfo() -> AmityObject<AmityMyFollowInfo> {
        userRepostiory.userRelationship.getMyFollowInfo()
    }
    
    func getFollowInfo(withId: String) -> AmityObject<AmityUserFollowInfo> {
        userRepostiory.userRelationship.getFollowInfo(withUserId: withId)
    }
    
    func getUser(withId: String) -> AmityObject<AmityUser> {
        userRepostiory.getUser(withId)
    }
    
    func followUser(withId: String) async throws -> (Bool, AmityFollowResponse) {
        try await userRepostiory.userRelationship.follow(withUserId: withId)
    }
    
    func acceptMyFollower(withId: String) async throws -> (Bool, AmityFollowResponse) {
        try await userRepostiory.userRelationship.acceptMyFollower(withUserId: withId)
    }
    
    func declineMyFollower(withId: String) async throws -> (Bool, AmityFollowResponse) {
        try await userRepostiory.userRelationship.declineMyFollower(withUserId: withId)
    }
    
    func unfollowUser(withId: String) async throws -> (Bool, AmityFollowResponse) {
        try await userRepostiory.userRelationship.unfollow(withUserId: withId)
    }
    
    func blockUser(withId: String) async throws {
        try await userRepostiory.userRelationship.blockUser(userId: withId)
    }
    
    func unblockUser(withId: String) async throws {
        try await userRepostiory.userRelationship.unblockUser(userId: withId)
    }
    
    func getMyFollowings(_ option: AmityFollowQueryOption) -> AmityCollection<AmityFollowRelationship> {
        userRepostiory.userRelationship.getMyFollowings(with: option)
    }
    
    func getMyFollowers(_ option: AmityFollowQueryOption) -> AmityCollection<AmityFollowRelationship> {
        userRepostiory.userRelationship.getMyFollowers(with: option)
    }
    
    func getUserFollowings(withId: String) -> AmityCollection<AmityFollowRelationship> {
        userRepostiory.userRelationship.getFollowings(withUserId: withId)
    }
    
    func getUserFollowers(withId: String) -> AmityCollection<AmityFollowRelationship> {
        userRepostiory.userRelationship.getFollowers(withUserId: withId)
    }
    
    func getBlockedUsers() -> AmityCollection<AmityUser> {
        userRepostiory.getBlockedUsers()
    }
}
