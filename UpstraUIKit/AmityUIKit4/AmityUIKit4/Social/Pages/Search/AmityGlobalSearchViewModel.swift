//
//  AmityGlobalSearchViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import Combine
import AmitySDK

public enum SearchType {
    case community, user, myCommunities
}


public class AmityGlobalSearchViewModel: ObservableObject {
    private let communityManger = CommunityManager()
    private var communityCollection: AmityCollection<AmityCommunity>?
    
    private let userManager = UserManager()
    private var userCollection: AmityCollection<AmityUser>?
    
    private var cancellable: Set<AnyCancellable> = Set()
    public var searchType: SearchType
    
    @Published public var searchKeyword: String = ""
    @Published public var communities: [AmityCommunity] = []
    @Published public var users: [AmityUser] = []
    @Published public var loadingState: AmityLoadingStatus = .notLoading
    @Published public var isFirstTimeSearching: Bool = true
    
    public init(searchType: SearchType = .community) {
        self.searchType = searchType
    
        $searchKeyword
            .drop { $0.isEmpty }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                guard let self else { return }
                isFirstTimeSearching = false
                
                if self.searchType == .community {
                    self.searchCommunities(keyword: value)
                } else if self.searchType == .user {
                    self.searchUsers(keyword: value)
                } else {
                    self.searchMyCommunities(keyword: value)
                }
            })
            .store(in: &cancellable)
    }
    
    /// Search Communities globally
    private func searchCommunities(keyword: String) {
        communityCollection = communityManger.searchCommunitites(keyword: keyword, filter: .all)
        communityCollection?.$snapshots
            .sink(receiveValue: { [weak self] communities in
                self?.communities = communities
            })
            .store(in: &cancellable)
        
        communityCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingState = status
                Log.add(event: .info, "Search State: \(status)")
            })
            .store(in: &cancellable)
    }
    
    public func loadMoreCommunities() {
        if let communityCollection, communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
    
    /// Search Users globally
    private func searchUsers(keyword: String) {
        userCollection = userManager.searchUsers(keyword: keyword)
        userCollection?.$snapshots
            .sink(receiveValue: { [weak self] users in
                self?.users = users
            })
            .store(in: &cancellable)
        
        userCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingState = status
                Log.add(event: .info, "Search State: \(status)")
            })
            .store(in: &cancellable)
    }
    
    public func loadMoreUsers() {
        if let userCollection, userCollection.hasNext {
            userCollection.nextPage()
        }
    }
    
    /// Search My Communities globally
    private func searchMyCommunities(keyword: String) {
        communityCollection = communityManger.searchCommunitites(keyword: keyword, filter: .userIsMember)
        communityCollection?.$snapshots
            .sink(receiveValue: { [weak self] communities in
                self?.communities = communities
            })
            .store(in: &cancellable)
        
        communityCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingState = status
            })
            .store(in: &cancellable)
    }
    
    public func loadMoreMyCommunities() {
        if let communityCollection, communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
}
