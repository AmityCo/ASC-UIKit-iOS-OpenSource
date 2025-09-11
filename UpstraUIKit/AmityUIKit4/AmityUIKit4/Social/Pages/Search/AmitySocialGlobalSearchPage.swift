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
    @State private var tabs: [String] = ["Posts", "Communities", "Users"]
    
    public init(searchKeyword: String? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .socialGlobalSearchPage))
        self._viewModel = StateObject(wrappedValue: AmityGlobalSearchViewModel(searchType: .posts, searchKeyword: searchKeyword))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityTopSearchBarComponent(viewModel: viewModel, pageId: id)
                .padding(.top, 64)
                .environmentObject(host)
            
            VStack(spacing: 0) {
                TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                    .selectedTabColor(viewConfig.theme.highlightColor)
                    .onChange(of: tabIndex) { value in
                        
                        switch value {
                        case 0:
                            viewModel.searchType = .posts
                        case 1:
                            viewModel.searchType = .community
                        case 2:
                            viewModel.searchType = .user
                        default:
                            viewModel.searchType = .community
                        }
                        
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
                    AmityPostSearchResultComponent(viewModel: viewModel, pageId: id)
                        .tag(0)
                    
                    AmityCommunitySearchResultComponent(viewModel: viewModel, pageId: id)
                        .tag(1)
                    
                    AmityUserSearchResultComponent(viewModel: viewModel, pageId: id)
                        .tag(2)
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
