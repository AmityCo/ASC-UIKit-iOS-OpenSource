//
//  CommunityCategoriesViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

enum QueryState {
    case idle
    case loading
    case loaded
    case error
}

class CommunityCategoriesViewModel: ObservableObject {
    
    private let commRepo: AmityCommunityRepository = .init(client: AmityUIKitManagerInternal.shared.client)
    
    private var token: AmityNotificationToken?
    private var categoryCollection: AmityCollection<AmityCommunityCategory>?

    @Published var categories: [CommunityCategoryModel] = []
    @Published var queryState: QueryState = .idle
    
    var queryStateObserver: AnyCancellable?
    var refreshStateObserver: AnyCancellable?
    var limit: Int?
    
    init(limit: Int? = nil) {
        self.limit = limit        
    }
    
    var loadedCategoriesCount: Int {
        return categoryCollection?.count() ?? 0
    }
    
    func fetchCategories(limit: Int? = nil) {
        Log.add(event: .info, "Fetch categories called...")
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        categoryCollection = commRepo.getCategories(sortBy: .displayName, includeDeleted: false)
        token = categoryCollection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
                        
            if let error {
                self.queryState = .error
                self.token?.invalidate()
                self.categoryCollection = nil
                self.unObserveState()
                return
            }
            
            if let limit, limit > 0 {
                let items = Array(liveCollection.snapshots.prefix(limit)).map { CommunityCategoryModel(model: $0) }
                self.categories = items
            } else {
                let items = liveCollection.snapshots.map { CommunityCategoryModel(model: $0) }
                self.categories = items
            }
            
            self.queryState = .loaded
        }
    }
    
    func loadNextPage() {
        guard let categoryCollection, categoryCollection.hasNext, queryState != .loading else { return }
        
        queryState = .loading
        
        categoryCollection.nextPage()
    }
    
    func observeState() {
        refreshStateObserver = ExploreComponentsStateManager.shared.$categoriesState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .refreshing:
                self.fetchCategories(limit: self.limit)
            default:
                break
            }
        }
        
        queryStateObserver = $queryState
            .receive(on: DispatchQueue.main)
            .sink { state in
            switch state {
            case .error:
                ExploreComponentsStateManager.shared.categoriesState = .error
            case .idle:
                ExploreComponentsStateManager.shared.categoriesState = .initial
            case .loaded:
                if self.categories.isEmpty {
                    ExploreComponentsStateManager.shared.categoriesState = .dataEmpty
                } else {
                    ExploreComponentsStateManager.shared.categoriesState = .dataAvailable
                }
            case .loading:
                ExploreComponentsStateManager.shared.categoriesState = .loading
            }
        }
    }
    
    func unObserveState() {
        queryStateObserver = nil
        refreshStateObserver = nil
    }
}
