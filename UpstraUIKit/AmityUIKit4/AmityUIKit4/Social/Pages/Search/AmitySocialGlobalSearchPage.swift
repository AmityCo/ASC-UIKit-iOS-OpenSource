//
//  AmitySocialGlobalSearchPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI

public struct AmitySocialGlobalSearchPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .socialGlobalSearchPage
    }
    
    @StateObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0

    // A tab searching for something this build cannot display is an offer the app
    // cannot keep: with `post` off the Posts tab opened selected and permanently
    // empty. User search has no module of its own beyond `discovery`, which owns
    // the whole page, so it is always here.
    private let searchTypes: [SearchType] = AmitySocialGlobalSearchPage.availableSearchTypes()

    static func availableSearchTypes() -> [SearchType] {
        let config = AmityUIKitConfigController.shared
        var types: [SearchType] = []
        if config.isFeatureEnabled(AmityUIKitFeature.post) { types.append(.posts) }
        if config.isFeatureEnabled(AmityUIKitFeature.community) { types.append(.community) }
        types.append(.user)
        return types
    }

    private static func tabTitle(for type: SearchType) -> String {
        switch type {
        case .posts: return AmityLocalizedStringSet.Social.socialSearchPostsTab.localizedString
        case .community: return AmityLocalizedStringSet.Social.socialHomeCommunitiesTab.localizedString
        default: return AmityLocalizedStringSet.Social.socialSearchUsersTab.localizedString
        }
    }

    @State private var tabs: [String] = AmitySocialGlobalSearchPage.availableSearchTypes()
        .map { AmitySocialGlobalSearchPage.tabTitle(for: $0) }
    
    public init(searchKeyword: String? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .socialGlobalSearchPage))
        // The first tab that survived the gate, not always posts.
        let initialType = AmitySocialGlobalSearchPage.availableSearchTypes().first ?? .user
        self._viewModel = StateObject(wrappedValue: AmityGlobalSearchViewModel(searchType: initialType, searchKeyword: searchKeyword))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityTopSearchBarComponent(viewModel: viewModel, pageId: id)
                .padding(.top, 64)
                .environmentObject(host)
            
            VStack(spacing: 0) {
                TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                    .selectedTabColor(viewConfig.theme.primaryColor)
                    .onChange(of: tabIndex) { value in
                        // Read from the gated list, never from a fixed index:
                        // dropping a tab shifts every index after it.
                        viewModel.searchType = searchTypes.indices.contains(value)
                            ? searchTypes[value]
                            : (searchTypes.first ?? .user)
                        
                        viewModel.searchKeyword = viewModel.searchKeyword
                    }
                    .padding(.horizontal)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            .padding(.top, 15)
            
            ZStack(alignment: .top) {
                TabView(selection: $tabIndex) {
                    ForEach(Array(searchTypes.enumerated()), id: \.offset) { index, type in
                        switch type {
                        case .posts:
                            AmityPostSearchResultComponent(viewModel: viewModel, pageId: id)
                                .tag(index)
                        case .community:
                            AmityCommunitySearchResultComponent(viewModel: viewModel, pageId: id)
                                .tag(index)
                        default:
                            AmityUserSearchResultComponent(viewModel: viewModel, pageId: id)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .ignoresSafeArea()
    }
}


#if DEBUG
#Preview {
    AmitySocialGlobalSearchPage()
}
#endif
