//
//  UserRelationshipManager.swift
//  AmityUIKit
//
//  Created by Nishan Niraula on 20/2/25.
//  Copyright © 2025 Amity. All rights reserved.
//

import SwiftUI
import AmitySDK

class UserRelationshipManager {
    
    let userRelationship = AmityUserRelationship(client: AmityUIKitManagerInternal.shared.client)
    
    func followUser(userId: String, completion: @escaping (Bool, AmityFollowResponse?, Error?) -> Void) {
        Task { @MainActor in
            do {
                let response = try await userRelationship.follow(withUserId: userId)
                completion(response.0, response.1, nil)
            } catch let error {
                completion(false, nil, error)
            }
        }
    }
    
    func unfollowUser(userId: String, completion: @escaping (Bool, AmityFollowResponse?, Error?) -> Void) {
        Task { @MainActor in
            do {
                let response = try await userRelationship.unfollow(withUserId: userId)
                completion(response.0, response.1, nil)
            } catch let error {
                completion(false, nil, error)
            }
        }
    }
    
    func declineUser(userId: String, completion: @escaping (Bool, AmityFollowResponse?, Error?) -> Void) {
        Task { @MainActor in
            do {
                let response = try await userRelationship.declineMyFollower(withUserId: userId)
                completion(response.0, response.1, nil)
            } catch let error {
                completion(false, nil, error)
            }
        }
    }
}

class UserModerationManager {
    
    let repository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func flagUser(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        Task { @MainActor in
            do {
                let result = try await repository.flagUser(withId: userId)
                completion(result, nil)
            } catch let error {
                completion(false, error)
            }
        }
    }
    
    func unflagUser(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        Task { @MainActor in
            do {
                let result = try await repository.unflagUser(withId: userId)
                completion(result, nil)
            } catch let error {
                completion(false, error)
            }
        }
    }
    
    func isFlaggedByMe(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        Task { @MainActor in
            do {
                let result = try await repository.isUserFlaggedByMe(withId: userId)
                completion(result, nil)
            } catch let error {
                completion(false, error)
            }
        }
    }
}
