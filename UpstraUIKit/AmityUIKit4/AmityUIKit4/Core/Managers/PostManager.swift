//
//  PostManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/10/24.
//

import Foundation
import AmitySDK

class PostManager {
    private let postRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    
    @discardableResult
    func getPost(withId: String) -> AmityObject<AmityPost> {
        postRepository.getPost(withId: withId)
    }
    
    @discardableResult
    func deletePost(withId: String) async throws -> Bool {
        try await postRepository.hardDeletePost(withId: withId, parentId: nil)
    }
    
    @discardableResult
    func flagPost(withId: String) async throws -> Bool {
        try await postRepository.flagPost(withId: withId)
    }
    
    @discardableResult
    func unflagPost(withId: String) async throws -> Bool {
        try await postRepository.unflagPost(withId: withId)
    }
    
    @discardableResult
    func isFlagByMe(withId: String) async throws -> Bool {
        try await postRepository.isFlaggedByMe(withId: withId)
    }
    
    func getCommunityAnnouncementPost(communityId: String) -> AmityCollection<AmityPinnedPost> {
        return postRepository.getPinnedPosts(communityId: communityId, placement: AmityPinPlacement.announcement.rawValue, sortBy: .lastPinned)
    }
    
    func getAllPinnedPost(communityId: String) -> AmityCollection<AmityPinnedPost> {
        return postRepository.getPinnedPosts(communityId: communityId, placement: nil, sortBy: .lastPinned)
    }
    
    func approvePost(postId: String) async throws -> Bool {
        try await postRepository.approvePost(withId: postId)
    }
    
    func declinePost(postId: String) async throws -> Bool {
        try await postRepository.declinePost(withId: postId)
    }
    
    func createPost(_ builder: any AmitySDK.AmityPostBuilder, targetId: String?, targetType: AmitySDK.AmityPostTargetType, metadata: [String : Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?) async throws -> AmityPost {
        if let mentionees, let metadata {
            try await postRepository.createPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees)
        } else {
            try await postRepository.createPost(builder, targetId: targetId, targetType: targetType)
        }
    }
    
    @discardableResult
    func editPost(withId: String, builder: any AmitySDK.AmityPostBuilder, metadata: [String : Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?) async throws -> AmityPost {
        if let mentionees, let metadata {
            try await postRepository.editPost(withId: withId, builder: builder, metadata: metadata, mentionees: mentionees)
        } else {
            try await postRepository.editPost(withId: withId, builder: builder)
        }
    }
}
