//
//  AmityEventPageContainer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 3/11/25.
//

import SwiftUI

struct AmityEventPageContainer: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = ["Explore", "My event"]
    
    public init() {
        var items: [String] = ["Explore"]
        if !AmityUIKitManagerInternal.shared.isGuestUser {
            items.append("My event")
        }
        
        self._tabs = State(initialValue: items)
    }
    
    var body: some View {
        let isGuestUser = AmityUIKitManagerInternal.shared.isGuestUser
        
        VStack(spacing: 0) {
            if !isGuestUser {
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
            }
            
            TabView(selection: $tabIndex) {
                AmityExploreEventFeedComponent()
                    .tag(0)
                
                if !isGuestUser {
                    AmityMyEventFeedComponent()
                        .tag(1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.top, isGuestUser ? 0 : 8)
        }
        .updateTheme(with: viewConfig)
    }
}



