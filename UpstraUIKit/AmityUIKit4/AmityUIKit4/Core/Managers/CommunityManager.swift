//
//  CommunityManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/9/24.
//

import Foundation
import AmitySDK

class CommunityManager {
    private let communityRepository = AmityCommunityRepository()
    
    func searchCommunitites(keyword: String, filter: AmityCommunityQueryFilter) -> AmityCollection<AmityCommunity> {
        let searchOptions = AmityCommunitySearchOptions(keyword: keyword, filter: filter, sortBy: .displayName, categoryId: nil, includeDeleted: false, includeDiscoverablePrivateCommunity: true)
        return communityRepository.searchCommunities(with: searchOptions)
    }
    
    func getCommunity(withId: String) -> AmityObject<AmityCommunity> {
        communityRepository.getCommunity(withId: withId)
    }
    
    func getCommunities(filter: AmityCommunityQueryFilter) -> AmityCollection<AmityCommunity> {
        let queryOptions = AmityCommunityQueryOptions(filter: filter, sortBy: .lastCreated, includeDeleted: false)
        return communityRepository.getCommunities(with: queryOptions)
    }
    
    func joinCommunity(withId: String) async throws {
        return try await communityRepository.joinCommunity(withId: withId)
    }
    
    func getCategories() -> AmityCollection<AmityCommunityCategory> {
        communityRepository.getCategories(sortBy: .displayName, includeDeleted: false)
    }
    
    func createCommunity(_ createOptions: AmityCommunityCreateOptions) async throws -> AmityCommunity {
        try await communityRepository.createCommunity(with: createOptions)
    }
    
    @discardableResult
    func editCommunity(withId: String, updateOptions: AmityCommunityUpdateOptions) async throws -> AmityCommunity {
        try await communityRepository.editCommunity(withId: withId, options: updateOptions)
    }
    
    func leaveCommunity(withId: String) async throws {
        try await communityRepository.leaveCommunity(withId: withId)
    }
    
    func deleteCommunity(withId: String) async throws {
        try await communityRepository.deleteCommunity(withId: withId)
    }
}

extension CommunityManager {
    
    func getPendingJoinRequests(community: AmityCommunity) -> AmityCollection<AmityJoinRequest> {
        return community.getJoinRequests(status: .pending)
    }
}
