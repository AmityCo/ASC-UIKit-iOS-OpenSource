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
    
    @StateObject private var viewModel: AmityGlobalSearchViewModel = AmityGlobalSearchViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = ["Communities", "Users"]
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .socialGlobalSearchPage))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityTopSearchBarComponent(viewModel: viewModel, pageId: id)
                .padding(.top, 60)
                .environmentObject(host)
            
            if !viewModel.isFirstTimeSearching {
                VStack(spacing: 0) {
                    TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                        .selectedTabColor(viewConfig.theme.highlightColor)
                        .onChange(of: tabIndex) { value in
                            viewModel.searchType = value == 0 ? .community : .user
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
                        AmityCommunitySearchResultComponent(viewModel: viewModel, pageId: id)
                            .tag(0)
                        
                        AmityUserSearchResultComponent(viewModel: viewModel, pageId: id)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            } else { Spacer() }
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
