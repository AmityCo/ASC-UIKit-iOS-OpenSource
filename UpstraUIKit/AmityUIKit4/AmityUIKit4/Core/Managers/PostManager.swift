//
//  PostManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/10/24.
//

import Foundation
import AmitySDK

// FIXME: Use PostDataType instead
enum PostTypeFilter: String {
    case image, video, clip
}

class PostManager {
    let postRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    
    @discardableResult
    func getPost(withId: String) -> AmityObject<AmityPost> {
        postRepository.getPost(withId: withId)
    }
    
    func getPosts(options: AmityPostQueryOptions) -> AmityCollection<AmityPost> {
        postRepository.getPosts(options)
    }
    
    func getPosts(ids: [String]) -> AmityCollection<AmityPost> {
        postRepository.getPosts(postIds: ids)
    }
    
    @discardableResult
    func deletePost(withId: String) async throws -> Bool {
        try await postRepository.softDeletePost(withId: withId, parentId: nil)
    }
    
    @discardableResult
    func flagPost(withId: String) async throws -> Bool {
        try await postRepository.flagPost(withId: withId)
    }
    
    func flagPost(withId: String, reason: AmityContentFlagReason) async throws {
        try await postRepository.flagPost(withId: withId, reason: reason)
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
    
    func getGlobalPinnedPost() -> AmityCollection<AmityPinnedPost> {
        return postRepository.getGlobalPinnedPosts()
    }
    
    func approvePost(postId: String) async throws -> Bool {
        try await postRepository.approvePost(withId: postId)
    }
    
    func declinePost(postId: String) async throws -> Bool {
        try await postRepository.declinePost(withId: postId)
    }
    
    @discardableResult
    func editPost(withId: String, builder: any AmitySDK.AmityPostBuilder, metadata: [String : Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?, hashtags: AmitySDK.AmityHashtagBuilder?) async throws -> AmityPost {
        try await postRepository.editPost(withId: withId, builder: builder, metadata: metadata, mentionees: mentionees, hashtags: hashtags)
    }
    
    func createStreamPost(builder: AmityLiveStreamPostBuilder, targetId: String?, targetType: AmityPostTargetType, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?) async throws -> AmityPost {
        return try await postRepository.createLiveStreamPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees)
    }
    
    func searchPosts(keyword: String) -> AmityCollection<AmityPost> {
        let searchOptions = AmityPostSemanticSearchOptions(query: keyword, targetId: nil, targetType: nil, matchingOnlyParentPost: true)
        return postRepository.semanticSearchPosts(options: searchOptions)
    }
    
    func searchPosts(hashtags: [String]) -> AmityCollection<AmityPost> {
        let searchOptions = AmityPostHashtagSearchOptions(hashtags: hashtags)
        return postRepository.searchPostsByHashtag(options: searchOptions)
    }
}
