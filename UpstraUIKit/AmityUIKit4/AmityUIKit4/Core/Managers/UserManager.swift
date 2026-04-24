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
    let userRelationship = AmityUserRelationship()
    let userRepostiory = AmityUserRepository()
    let fileRepository = AmityFileRepository()
    
    func searchUsers(keyword: String) -> AmityCollection<AmityUser> {
        userRepostiory.searchUsers(keyword, sortBy: .displayName, matchType: .partial)
    }
    
    func editUser(user: UserModel) async throws {
        let builder = AmityUserUpdateOptions()
        builder.setUserDescription(user.about)
        builder.setDisplayName(user.displayName)
        
        if let avatar = user.avatar {
            let imageData = try await fileRepository.uploadImage(avatar, progress: nil)
            builder.setAvatar(imageData)
        }
        
        try await AmityUIKitManagerInternal.shared.client.editUser(builder)
    }
    
    func flagUser(withId: String) async throws {
        try await userRepostiory.flagUser(withId: withId)
    }
    
    func unflagUser(withId: String) async throws {
        try await userRepostiory.unflagUser(withId: withId)
    }
    
    func isUserFlaggedByMe(withId: String) async throws -> Bool {
        try await userRepostiory.isUserFlaggedByMe(withId: withId)
    }
    
    func getMyFollowInfo() -> AmityObject<AmityMyFollowInfo> {
        userRelationship.getMyFollowInfo()
    }
    
    func getFollowInfo(withId: String) -> AmityObject<AmityUserFollowInfo> {
        userRelationship.getFollowInfo(withUserId: withId)
    }
    
    func getUser(withId: String) -> AmityObject<AmityUser> {
        userRepostiory.getUser(withId)
    }
    
    func followUser(withId: String) async throws -> AmityFollowResponse {
        try await userRelationship.follow(withUserId: withId)
    }
    
    func acceptMyFollower(withId: String) async throws -> AmityFollowResponse {
        try await userRelationship.acceptMyFollower(withUserId: withId)
    }
    
    func declineMyFollower(withId: String) async throws -> AmityFollowResponse {
        try await userRelationship.declineMyFollower(withUserId: withId)
    }
    
    func unfollowUser(withId: String) async throws -> AmityFollowResponse {
        try await userRelationship.unfollow(withUserId: withId)
    }
    
    func blockUser(withId: String) async throws {
        try await userRelationship.blockUser(userId: withId)
    }
    
    func unblockUser(withId: String) async throws {
        try await userRelationship.unblockUser(userId: withId)
    }
    
    func getMyFollowings(_ option: AmityFollowQueryOption) -> AmityCollection<AmityFollowRelationship> {
        userRelationship.getMyFollowings(with: option)
    }
    
    func getMyFollowers(_ option: AmityFollowQueryOption) -> AmityCollection<AmityFollowRelationship> {
        userRelationship.getMyFollowers(with: option)
    }
    
    func getUserFollowings(withId: String) -> AmityCollection<AmityFollowRelationship> {
        userRelationship.getFollowings(withUserId: withId)
    }
    
    func getUserFollowers(withId: String) -> AmityCollection<AmityFollowRelationship> {
        userRelationship.getFollowers(withUserId: withId)
    }
    
    func getBlockedUsers() -> AmityCollection<AmityUser> {
        userRepostiory.getBlockedUsers()
    }
}
