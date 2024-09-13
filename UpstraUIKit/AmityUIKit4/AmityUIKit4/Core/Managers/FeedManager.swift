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
    
    func getCommunityFeedPosts(communityId: String) -> AmityCollection<AmityPost> {
        feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: .lastCreated, includeDeleted: false, feedType: .published)
    }
    
    func getPendingCommunityFeedPosts(communityId: String) -> AmityCollection<AmityPost> {
        feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: .lastCreated, includeDeleted: false, feedType: .reviewing)
    }
}
