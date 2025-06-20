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
    private var joinRequestToken: AmityNotificationToken?
    private var joinRequestManager = JoinRequestManager()
    
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
        
        communityCollection = repository.getTrendingCommunities(includeDiscoverablePrivateCommunity: true)
        token = communityCollection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let _ = error {
                self.queryState = .error
                self.token?.invalidate()
                self.communityCollection = nil
                self.unObserveState()
                return
            }
            
            if let limit, limit > 0 {
                self.processTrendingCommunities(liveCollection.snapshots, limit: limit)
            } else {
                let items = liveCollection.snapshots.map {
                    AmityCommunityModel(object: $0)
                }
                self.communities = items
                self.queryState = .loaded
            }
        }
    }
    
    func processTrendingCommunities(_ communities: [AmityCommunity], limit: Int) {
        let trendingCommunities = communities.prefix(limit)
        let joinApprovalRequiredCommIds = communities.filter{ $0.requiresJoinApproval }.map{ $0.communityId }
        if joinApprovalRequiredCommIds.isEmpty {
            self.communities = trendingCommunities.map { AmityCommunityModel(object: $0) }
            self.queryState = .loaded
        } else {
            // There is a weird write transaction crash in realm while trying to process join request from within observer block. So we add a delay before fetching join requests.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.joinRequestManager.fetchJoinRequests(communityIds: joinApprovalRequiredCommIds) { statusInfo in
                    
                    let final = trendingCommunities.map { community in
                        if community.isJoined {
                            return AmityCommunityModel(object: community)
                        } else {
                            return AmityCommunityModel(object: community, joinRequest: community.joinRequest)
                        }
                    }
    
                    self.communities = final
                    self.queryState = .loaded
                }
            }
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
    
    func fetchJoinRequestStatus(ids: [String], completion: @escaping ([String: AmityJoinRequest]) -> Void) {
        joinRequestToken = repository.getJoinRequestList(communityIds: ids).observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            // Stop observing
            joinRequestToken?.invalidate()
            joinRequestToken = nil
            
            var statusMap: [String: AmityJoinRequest] = [:]
            liveCollection.snapshots.forEach { request in
                statusMap[request.targetId] = request
            }
            
            completion(statusMap)
        }
    }
}

class JoinRequestManager {
    
    private var token: AmityNotificationToken?
    private var cache: [String: AmityJoinRequest] = [:]
    private let repository: AmityCommunityRepository = .init(client: AmityUIKit4Manager.client)
    private var isFetching = false
    
    func fetchJoinRequests(communityIds: [String], completion: @escaping ([String: AmityJoinRequest]) -> Void) {
        
        let newData = communityIds.filter { cache[$0] == nil }
        
        guard !newData.isEmpty else {
            Log.add(event: .info, "Returning join requests data from cache")
            completion(cache)
            return
        }
        
        guard !isFetching else { return }
        isFetching = true
        token = repository.getJoinRequestList(communityIds: communityIds).observe({ [weak self] liveCollection, _, error in
            guard let self else { return }
            
            // Stop observing
            token?.invalidate()
            token = nil
            
            liveCollection.snapshots.forEach { request in
                self.cache[request.targetId] = request
            }
            
            Log.add(event: .info, "Returning fresh join requests data from server")
            completion(cache)
            
            isFetching = false
        })
    }
}
