//
//  CommunityManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/9/24.
//

import Foundation
import AmitySDK

class CommunityManager {
    private let communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func searchCommunitites(keyword: String, filter: AmityCommunityQueryFilter) -> AmityCollection<AmityCommunity> {
        let searchOptions = AmityCommunitySearchOptions(keyword: keyword, filter: filter, sortBy: .displayName, categoryId: nil, includeDeleted: false)
        return communityRepository.searchCommunities(with: searchOptions)
    }
    
    func getCommunity(withId: String) -> AmityObject<AmityCommunity> {
        communityRepository.getCommunity(withId: withId)
    }
    
    @discardableResult
    func joinCommunity(withId: String) async throws -> Bool {
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
    
    @discardableResult
    func leaveCommunity(withId: String) async throws -> Bool {
        try await communityRepository.leaveCommunity(withId: withId)
    }
    
    func deleteCommunity(withId: String, completion: ((AmityError?) -> Void)?) {
        communityRepository.deleteCommunity(withId: withId) { success, error in
            if success {
                completion?(nil)
            } else {
                completion?(AmityError(error: error) ?? .unknown)
            }
        }
    }
}
