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
                ZStack(alignment: .bottom) {
                    TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                        .selectedTabColor(viewConfig.theme.primaryColor)
                        .onChange(of: tabIndex) { value in
                            viewModel.searchType = value == 0 ? .community : .user
                            viewModel.searchKeyword = viewModel.searchKeyword
                        }
                        .padding(.horizontal)
                        
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 0.5)
                        .offset(y: -1)
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
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 15)
                        .isHidden(viewModel.loadingState != .loading)
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



extension TabBarView: AmityViewBuildable {
    func selectedTabColor(_ value: UIColor) -> Self {
        self.mutating(keyPath: \.selectedTabColor, value: value)
    }
}

struct TabBarView: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    
    @Binding var tabBarOptions: [String]
    
    private var selectedTabColor: UIColor = .blue
    
    init(currentTab: Binding<Int>, tabBarOptions: Binding<[String]>) {
        self._currentTab = currentTab
        self._tabBarOptions = tabBarOptions
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(zip(self.tabBarOptions.indices,
                                  self.tabBarOptions)),
                        id: \.0,
                        content: {
                    index, name in
                    TabBarItem(currentTab: self.$currentTab,
                               namespace: namespace.self,
                               tabBarItemName: name,
                               tab: index,
                               selectedTabColor: selectedTabColor)
                    
                })
            }
        }
    }
}

struct TabBarItem: View {
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    
    var tabBarItemName: String
    var tab: Int
    var selectedTabColor: UIColor
    
    var body: some View {
        Button {
            self.currentTab = tab
        } label: {
            VStack(spacing: 10) {
                Text(tabBarItemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(currentTab == tab ? Color(selectedTabColor) : .gray)
                
                if currentTab == tab {
                    Color.blue
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline",
                                               in: namespace,
                                               properties: .frame)
                } else {
                    Color.clear.frame(height: 2)
                }
            }
            .animation(.easeInOut(duration: 0.1), value: self.currentTab)
        }
        .buttonStyle(.plain)
    }
}
