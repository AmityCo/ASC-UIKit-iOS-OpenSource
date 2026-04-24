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
    let postRepository = AmityPostRepository()
    
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
    
    func deletePost(withId: String) async throws {
        try await postRepository.softDeletePost(withId: withId, parentId: nil)
    }
    
    func flagPost(withId: String) async throws {
        try await postRepository.flagPost(withId: withId, reason: .communityGuidelines)
    }
    
    func flagPost(withId: String, reason: AmityContentFlagReason) async throws {
        try await postRepository.flagPost(withId: withId, reason: reason)
    }
    
    func unflagPost(withId: String) async throws {
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
    
    func approvePost(postId: String) async throws {
        try await postRepository.approvePost(withId: postId)
    }
    
    func declinePost(postId: String) async throws {
        try await postRepository.declinePost(withId: postId)
    }
    
    @discardableResult
    func editPost(withId: String, builder: any AmitySDK.AmityPostBuilder, metadata: [String : Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?, hashtags: AmitySDK.AmityHashtagBuilder?, links: [AmityLink]?, productTags: [AmityTextProductTag]? = nil, attachmentProductTags: AmityAttachmentProductTags? = nil) async throws -> AmityPost {

        return try await postRepository.editPost(withId: withId, builder: builder, metadata: metadata, mentionees: mentionees, hashtags: hashtags, links: links, productTags: productTags, attachmentProductTags: attachmentProductTags)
    }
    
    func createStreamPost(builder: AmityLiveStreamPostBuilder, targetId: String?, targetType: AmityPostTargetType, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?) async throws -> AmityPost {
        return try await postRepository.createLiveStreamPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees)
    }
    
    func createLiveStreamRoomPost(builder: AmityRoomPostBuilder, targetId: String?, targetType: AmityPostTargetType, metadata: [String: Any]?, mentionees: AmitySDK.AmityMentioneesBuilder?, productTags: [AmityProductTag]? = nil, pinnedProductId: String? = nil) async throws -> AmityPost {
        return try await postRepository.createRoomPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, hashtags: nil, links: nil, productTags: productTags, pinnedProductId: pinnedProductId)
    }
    
    func searchPosts(keyword: String) -> AmityCollection<AmityPost> {
        let searchOptions = AmityPostSemanticSearchOptions(query: keyword, targetId: nil, targetType: nil, matchingOnlyParentPost: true)
        return postRepository.semanticSearchPosts(options: searchOptions)
    }
    
    func searchPosts(hashtags: [String]) -> AmityCollection<AmityPost> {
        let searchOptions = AmityPostHashtagSearchOptions(hashtags: hashtags)
        return postRepository.searchPostsByHashtag(options: searchOptions)
    }
    
    func getCommunityLiveRoomPosts(communityId: String) -> AmityCollection<AmityPost> {
        postRepository.getCommunityLiveRoomPosts(withIds: [communityId])
    }
    
    func getGlobalLiveRoomPosts() -> AmityCollection<AmityPost> {
        postRepository.getLiveRoomPosts()
    }
    
    // MARK: - Product Tag Operations
    
    func updateProductTags(postId: String, productTags: [AmityMediaProductTag]) async throws -> AmityPost {
        return try await postRepository.updateProductTags(postId: postId, productTags: productTags)
    }
    
    func pinProductTag(postId: String, productId: String) async throws -> AmityPost {
        return try await postRepository.pinProduct(postId: postId, productId: productId)
    }
    
    func unpinProductTag(postId: String) async throws -> AmityPost {
        return try await postRepository.unpinProduct(postId: postId)
    }
}
