//
//  AmityGlobalSearchViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import Combine
import AmitySDK

public enum SearchType {
    case posts, community, user, myCommunities
}


public class AmityGlobalSearchViewModel: ObservableObject {
    private let communityManger = CommunityManager()
    private var communityCollection: AmityCollection<AmityCommunity>?
    
    private let userManager = UserManager()
    private var userCollection: AmityCollection<AmityUser>?
    
    private let postManager = PostManager()
    private var postCollection: AmityCollection<AmityPost>?
    
    private var cancellable: Set<AnyCancellable> = Set()
    // Subscriptions to the current search's collection, cleared before every new search so a
    // late response for the previous keyword or tab can't overwrite the state.
    private var collectionCancellables: Set<AnyCancellable> = Set()
    public var searchType: SearchType
    
    @Published public var searchKeyword: String = ""
    @Published public var communities: [AmityCommunity] = []
    @Published public var users: [AmityUser] = []
    @Published public var posts: [AmityPost] = []
    @Published public var loadingState: AmityLoadingStatus = .notLoading
    @Published public var isFirstTimeSearching: Bool = true
    
    public init(searchType: SearchType = .community, searchKeyword: String? = nil) {
        self.searchType = searchType
        
        if let searchKeyword {
            self.searchKeyword = searchKeyword
        }
    
        let keyword = $searchKeyword.removeDuplicates()
        
        // The search is pending from the keystroke, not from the debounce, so the previous
        // result can't show as "No results found" while the debounce waits.
        keyword
            .sink(receiveValue: { [weak self] value in
                self?.prepareSearch(keyword: value)
            })
            .store(in: &cancellable)
        
        keyword
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                guard let self else { return }
                isFirstTimeSearching = false
                self.search(keyword: value)
            })
            .store(in: &cancellable)
    }
    
    /// Switches the search to another type and searches the current keyword right away.
    /// The results of the previous type stay out of the new one.
    public func changeSearchType(_ type: SearchType) {
        searchType = type
        
        switch type {
        case .posts:
            posts = []
        case .community, .myCommunities:
            communities = []
        case .user:
            users = []
        }
        
        prepareSearch(keyword: searchKeyword)
        search(keyword: searchKeyword)
    }
    
    private func prepareSearch(keyword: String) {
        collectionCancellables.removeAll()
        postCollection = nil
        communityCollection = nil
        userCollection = nil
        
        switch searchType {
        case .posts, .community, .myCommunities:
            loadingState = keyword.isEmpty ? .notLoading : .loading
        case .user:
            if keyword.isEmpty {
                loadingState = .notLoading
            } else {
                loadingState = keyword.count < 3 ? .error : .loading
            }
        }
    }
    
    private func search(keyword: String) {
        switch searchType {
        case .posts:
            searchPosts(keyword: keyword)
        case .community:
            searchCommunities(keyword: keyword)
        case .user:
            searchUsers(keyword: keyword)
        case .myCommunities:
            searchMyCommunities(keyword: keyword)
        }
    }
    
    // A new collection reports .notLoading before its first request, so only a finished request
    // settles the state. The SDK also reports a failed request as .notLoading, which then ends it.
    private func observeLoadingStatus<P: Publisher>(_ publisher: P) where P.Output == AmityLoadingStatus, P.Failure == Never {
        var hasRequested = false
        publisher
            .sink(receiveValue: { [weak self] status in
                if status == .loading {
                    hasRequested = true
                    return
                }
                guard status != .notLoading || hasRequested else { return }
                self?.loadingState = status
                Log.add(event: .info, "Search State: \(status)")
            })
            .store(in: &collectionCancellables)
    }
    
    private func searchPosts(keyword: String) {
        if keyword.hasPrefix("#") {
            let hashtag = keyword.filter { $0 != "#" }
            postCollection = postManager.searchPosts(hashtags: [hashtag])
        } else {
            postCollection = postManager.searchPosts(keyword: keyword)
        }
        
        postCollection?.$snapshots.sink(receiveValue: { [weak self] posts in
            self?.posts = posts.filter { !$0.childrenPosts.contains { $0.dataType == "file" || $0.dataType == "audio" || $0.structureType == "mixed" } }
        })
        .store(in: &collectionCancellables)
        
        if let postCollection {
            observeLoadingStatus(postCollection.$loadingStatus)
        }
    }
    
    public func loadMorePosts() {
        if let postCollection, postCollection.hasNext {
            postCollection.nextPage()
        }
    }
    
    /// Search Communities globally
    private func searchCommunities(keyword: String) {
        guard !keyword.isEmpty else {
            communities = []
            loadingState = .notLoading
            
            return
        }
        
        communityCollection = communityManger.searchCommunitites(keyword: keyword, filter: .all)
        communityCollection?.$snapshots
            .sink(receiveValue: { [weak self] communities in
                self?.communities = communities
            })
            .store(in: &collectionCancellables)
        
        if let communityCollection {
            observeLoadingStatus(communityCollection.$loadingStatus)
        }
    }
    
    public func loadMoreCommunities() {
        if let communityCollection, communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
    
    /// Search Users globally
    private func searchUsers(keyword: String) {
        if keyword.isEmpty || keyword.count < 3 {
            self.users = []
            self.loadingState = keyword.isEmpty ? .notLoading : .error
            
            return // terminate here
        }
        
        userCollection = userManager.searchUsers(keyword: keyword)
        userCollection?.$snapshots
            .sink(receiveValue: { [weak self] users in
                self?.users = users
            })
            .store(in: &collectionCancellables)
        
        if let userCollection {
            observeLoadingStatus(userCollection.$loadingStatus)
        }
    }
    
    public func loadMoreUsers() {
        if let userCollection, userCollection.hasNext {
            userCollection.nextPage()
        }
    }
    
    /// Search My Communities globally
    private func searchMyCommunities(keyword: String) {
        guard !keyword.isEmpty else {
            communities = []
            loadingState = .notLoading
            return
        }
        
        communityCollection = communityManger.searchCommunitites(keyword: keyword, filter: .userIsMember)
        communityCollection?.$snapshots
            .sink(receiveValue: { [weak self] communities in
                self?.communities = communities
            })
            .store(in: &collectionCancellables)
        
        if let communityCollection {
            observeLoadingStatus(communityCollection.$loadingStatus)
        }
    }
    
    public func loadMoreMyCommunities() {
        if let communityCollection, communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
}
