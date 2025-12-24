//
//  AmityCommunitiesPageContainer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/10/25.
//

import SwiftUI

struct AmityCommunitiesPageContainer: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = ["Explore", "My communities"]
    
    public init() { }
    
    var body: some View {
        if AmityUIKitManagerInternal.shared.isGuestUser {
            AmityExplorePageContainer()
        } else {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                        .selectedTabColor(viewConfig.theme.highlightColor)
                        .onChange(of: tabIndex) { value in
                            
                        }
                        .padding(.leading, 16)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
                
                TabView(selection: $tabIndex) {
                    AmityExplorePageContainer()
                        .tag(0)
                    
                    AmityMyCommunitiesComponent(pageId: .socialHomePage)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 8)
            }
        }
    }
}
