//
//  RecommendedCommunityViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 4/9/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

class RecommendedCommunityViewModel: ObservableObject {
    
    private let repository: AmityCommunityRepository = .init(client: AmityUIKit4Manager.client)
    private var token: AmityNotificationToken?
    private var communityCollection: AmityCollection<AmityCommunity>?
    
    @Published var communities: [AmityCommunityModel] = []
    @Published var queryState: QueryState = .idle
    
    var queryStateObserver: AnyCancellable?
    var refreshStateObserver: AnyCancellable?

    func fetchCommunities(limit: Int? = 4) {
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        communityCollection = repository.getRecommendedCommunities()
        token = communityCollection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
                        
            if let error {
                self.queryState = .error
                self.token?.invalidate()
                self.communityCollection = nil
                self.unObserveState()
                return
            }
            
            if let limit, limit > 0 {
                let notJoinedCommunities = liveCollection.snapshots.filter { !$0.isJoined }
                let items = Array(notJoinedCommunities.prefix(limit).map { AmityCommunityModel(object: $0)} )
                self.communities = items
            } else {
                let items = liveCollection.snapshots.map {
                    AmityCommunityModel(object: $0)
                }
                self.communities = items
            }
            
            self.queryState = .loaded
        }
    }
    
    func observeState() {
        refreshStateObserver = ExploreComponentsStateManager.shared.$recommendedCommunitiesState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .refreshing:
                self.fetchCommunities()
            default:
                break
            }
        }
        
        queryStateObserver = $queryState
            .receive(on: DispatchQueue.main)
            .sink { state in
            switch state {
            case .error:
                ExploreComponentsStateManager.shared.recommendedCommunitiesState = .error
            case .idle:
                ExploreComponentsStateManager.shared.recommendedCommunitiesState = .initial
            case .loaded:
                if self.communities.isEmpty {
                    ExploreComponentsStateManager.shared.recommendedCommunitiesState = .dataEmpty
                } else {
                    ExploreComponentsStateManager.shared.recommendedCommunitiesState = .dataAvailable
                }
            case .loading:
                ExploreComponentsStateManager.shared.recommendedCommunitiesState = .loading
            }
        }
    }
    
    func unObserveState() {
        queryStateObserver = nil
        refreshStateObserver = nil
    }
}
