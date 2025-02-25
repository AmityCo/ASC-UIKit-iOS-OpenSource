//
//  ExploreComponentsStateHandler.swift
//  AmityUIKit4
//
//  Created by Nishan on 2/9/2567 BE.
//

import SwiftUI
import Combine

/// "Explore" section itself is not a page. We develop it as a container which contains other components such as categories, trending & recommended communities.
/// But we need to handle various states in this container which directly depends upon the state of above components. To allow user to use these components as standalone without need to pass anything in initializer, we create this singleton class to manage & communicate states of above components with the parent container.
// Even though this class is public, we do not document it in our public doc as most users do not need to use this class.
class ExploreComponentsStateManager: ObservableObject {
    
    enum ComponentState: String {
        case initial // Idle state
        case loading
        case dataAvailable
        case dataEmpty
        case refreshing
        case error
    }
    
    @Published var categoriesState: ComponentState = .initial
    @Published var recommendedCommunitiesState: ComponentState = .initial
    @Published var trendingCommunitiesState: ComponentState = .initial
    
    static let shared = ExploreComponentsStateManager()
    
    private init() { /* Private Initialization */ }
    
    // Show "community creation" empty state
    var isNoCommunitiesAvailable: Bool {
        return recommendedCommunitiesState == .dataEmpty && trendingCommunitiesState == .dataEmpty
    }
    
    // Show "something went wrong" empty state
    var isErrorInFetchingCommunities: Bool {
        return recommendedCommunitiesState == .error && trendingCommunitiesState == .error
    }
    
    func refreshAllComponents() {
        Log.add(event: .info, "Refreshing all components")
        self.categoriesState = .refreshing
        self.recommendedCommunitiesState = .refreshing
        self.trendingCommunitiesState = .refreshing
    }
    
    // Helpers
    
    var isCategoriesVisible: Bool {
        let isHidden = categoriesState == .dataEmpty || categoriesState == .error
        return !isHidden
    }
    
    var isTrendingCommunitiesVisible: Bool {
        let isHidden = trendingCommunitiesState == .dataEmpty || trendingCommunitiesState == .error
        return !isHidden
    }
    
    var isRecommendedCommunitiesVisible: Bool {
        let isHidden = recommendedCommunitiesState == .dataEmpty || recommendedCommunitiesState == .error
        return !isHidden
    }
}
