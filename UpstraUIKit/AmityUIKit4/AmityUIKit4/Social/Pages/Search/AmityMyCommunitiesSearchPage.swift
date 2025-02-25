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
                                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                        }
                    }
                    
                    if searchViewModel.loadingState == .loading && searchViewModel.communities.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<10, id: \.self) { index in
                                    CommunityCellSkeletonView()
                                        .padding(.top, index == 0 ? 8 : 0)
                                }
                            }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(searchViewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                                    let model = AmityCommunityModel(object: community)
                                    CommunityCellView(community: model, pageId: id)
                                        .padding(.top, index == 0 ? 8 : 0)
                                        .onTapGesture {
                                            let context = AmityMyCommunitiesSearchPageBehavior.Context(page: self, communityId: community.communityId)
                                            AmityUIKitManagerInternal.shared.behavior.myCommunitiesSearchPageBehavior?.goToCommunityProfilePage(context: context)
                                        }
                                        .onAppear {
                                            if index == searchViewModel.communities.count - 1 {
                                                searchViewModel.loadMoreMyCommunities()
                                            }
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
