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
    
    @discardableResult
    func createTextPost(text: String, communityId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) async throws -> AmityPost {
        
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
    
        let textPostBuilder = AmityTextPostBuilder()
        textPostBuilder.setText(text)
        
        return try await postRepository.createTextPost(textPostBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees)
    }
}
