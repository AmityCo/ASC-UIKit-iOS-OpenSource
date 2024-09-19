//
//  TrendingCommunityViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 4/9/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

class TrendingCommunityViewModel: ObservableObject {
    
    private let repository: AmityCommunityRepository = .init(client: AmityUIKit4Manager.client)
    private var token: AmityNotificationToken?
    private var communityCollection: AmityCollection<AmityCommunity>?
    
    @Published var communities: [AmityCommunityModel] = []
    @Published var queryState: QueryState = .idle
    
    lazy var digitFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    var queryStateObserver: AnyCancellable?
    var refreshStateObserver: AnyCancellable?
    
    func fetchCommunities(limit: Int? = 5) {
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        communityCollection = repository.getTrendingCommunities()
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
                let items = Array(liveCollection.snapshots.prefix(limit).map { AmityCommunityModel(object: $0)} )
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
    
    func isLastCommunity(community: AmityCommunityModel) -> Bool {
        if let lastCommunity = communities.last, lastCommunity.communityId == community.communityId {
            return true
        }
        return false
    }
    
    func observeState() {
        refreshStateObserver = ExploreComponentsStateManager.shared.$trendingCommunitiesState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .refreshing:
                Log.add(event: .info, "Refreshing trending communities")
                self.fetchCommunities(limit: 5)
            default:
                break
            }
        }
        
        queryStateObserver = $queryState
            .receive(on: DispatchQueue.main)
            .sink { state in
            switch state {
            case .error:
                ExploreComponentsStateManager.shared.trendingCommunitiesState = .error
            case .idle:
                ExploreComponentsStateManager.shared.trendingCommunitiesState = .initial
            case .loaded:
                if self.communities.isEmpty {
                    ExploreComponentsStateManager.shared.trendingCommunitiesState = .dataEmpty
                } else {
                    ExploreComponentsStateManager.shared.trendingCommunitiesState = .dataAvailable
                }
            case .loading:
                ExploreComponentsStateManager.shared.trendingCommunitiesState = .loading
            }
        }
    }
    
    func unObserveState() {
        queryStateObserver = nil
        refreshStateObserver = nil
    }
}
