//
//  FeedManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/7/24.
//

import Foundation
import AmitySDK

class FeedManager {
    private let feedRepository = AmityFeedRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func getGlobalFeedPosts() -> AmityCollection<AmityPost> {
        feedRepository.getGlobalFeed()
    }
    
    func getGlobalFeedPosts(dataTypes: Set<String>) -> AmityCollection<AmityPost> {
        feedRepository.getGlobalFeed(dataTypes: dataTypes)
    }
    
    func getCommunityFeedPosts(communityId: String) -> AmityCollection<AmityPost> {
        feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: .lastCreated, includeDeleted: false, feedType: .published)
    }
    
    func getPendingCommunityFeedPosts(communityId: String) -> AmityCollection<AmityPost> {
        feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: .lastCreated, includeDeleted: false, feedType: .reviewing)
    }
    
    func getUserFeed(userId: String, feedSources: [AmityFeedSource], dataTypes: [AmityPostDataType]? = nil, matchingOnlyParentPost: Bool = true) -> AmityCollection<AmityPost> {
        feedRepository.getUserFeed(userId, feedSources: feedSources, dataTypes: dataTypes, sortBy: .lastCreated, includeDeleted: false, matchingOnlyParentPost: matchingOnlyParentPost)
    }
}
