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
}
