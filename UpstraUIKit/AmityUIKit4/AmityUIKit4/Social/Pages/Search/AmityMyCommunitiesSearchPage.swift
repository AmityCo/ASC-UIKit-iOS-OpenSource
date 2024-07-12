//
//  AmityMyCommunitiesSearchPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/11/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityMyCommunitiesSearchPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .myCommunitiesSearchPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var searchViewModel: AmityGlobalSearchViewModel
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .myCommunitiesSearchPage))
        self._searchViewModel = StateObject(wrappedValue: AmityGlobalSearchViewModel(searchType: .myCommunities))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityTopSearchBarComponent(viewModel: searchViewModel, pageId: .socialGlobalSearchPage)
                .padding(.top, 60)
                .environmentObject(host)
            
            if !searchViewModel.isFirstTimeSearching {
                ZStack {
                    if searchViewModel.communities.isEmpty && searchViewModel.loadingState == .loaded {
                        VStack(spacing: 15) {
                            Image(AmityIcon.noSearchableIcon.getImageResource())
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                            
                            Text("No results found")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(searchViewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                                VStack {
                                    let model = AmityCommunityModel(object: community)
                                    CommunityCellView(community: model, pageId: id)
                                   
                                    Rectangle()
                                        .fill(Color(viewConfig.theme.baseColorShade4))
                                        .frame(height: 1)
                                        .padding([.leading, .trailing], 16)
                                }.onAppear {
                                    if index == searchViewModel.communities.count - 1 {
                                        searchViewModel.loadMoreMyCommunities()
                                    }
                                }
                                
                            }
                        }
                    }
                }
            } else { Spacer() }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .ignoresSafeArea()
    }
}
