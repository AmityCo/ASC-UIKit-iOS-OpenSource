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
    private var joinRequestToken: AmityNotificationToken?
    private var communityCollection: AmityCollection<AmityCommunity>?
    private var joinRequestManager = JoinRequestManager()
    
    @Published var communities: [AmityCommunityModel] = []
    @Published var queryState: QueryState = .idle
    
    var queryStateObserver: AnyCancellable?
    var refreshStateObserver: AnyCancellable?
    
    let debouncer = Debouncer(delay: 0.5)

    func fetchCommunities(limit: Int? = 4) {
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        communityCollection = repository.getRecommendedCommunities(includeDiscoverablePrivateCommunity: true)
        token = communityCollection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let _ = error {
                self.queryState = .error
                self.token?.invalidate()
                self.token = nil
                self.communityCollection = nil
                self.unObserveState()
                return
            }
            
            debouncer.run {
                self.processSnapshots(liveCollection: liveCollection, limit: limit)
            }
        }
    }
    
    func processSnapshots(liveCollection: AmityCollection<AmityCommunity>, limit: Int?) {
        if let limit, limit > 0 {
            self.processRecommendedCommunities(liveCollection.snapshots, limit: limit)
        }
    }
    
    func processRecommendedCommunities(_ communities: [AmityCommunity], limit: Int) {
        // Filter out joined communities
        let unjoinedCommunities = communities.filter { !$0.isJoined }
        
        // We consider more than required communities because some of them might be in pending state
        // which needs to be filtered out.
        let initialLimit = min(unjoinedCommunities.count, limit * 2)
        let recommendedCommunities = unjoinedCommunities.prefix(initialLimit)
        
        // We query join requests for those communities which requires join approval
        let joinApprovalRequiredCommIds = recommendedCommunities.filter { $0.requiresJoinApproval }.map { $0.communityId }
        
        if joinApprovalRequiredCommIds.isEmpty {
            self.communities = recommendedCommunities.prefix(limit).map { AmityCommunityModel(object: $0) }
            self.queryState = .loaded
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.joinRequestManager.fetchJoinRequests(communityIds: joinApprovalRequiredCommIds) { statusInfo in
                   
                    let filteredCommunities = recommendedCommunities.filter {
                        // Return those communities which are not in pending state or requires join approval
                        if let joinRequestStatus = $0.joinRequest?.status {
                            return joinRequestStatus != .pending && joinRequestStatus != .approved
                        } else {
                            return !$0.requiresJoinApproval
                        }
                    }.prefix(limit)
                    
                    self.communities = filteredCommunities.prefix(limit).map { AmityCommunityModel(object: $0) }
                    self.queryState = .loaded
                }
            }
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
