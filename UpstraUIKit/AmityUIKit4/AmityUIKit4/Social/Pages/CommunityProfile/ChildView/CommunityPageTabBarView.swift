//
//  CommunityPageTabBarView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import SwiftUI

struct CommunityPageTabBarView: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    @Binding var tabBarOptions: [CommunityPageTabItem]
    
    init(currentTab: Binding<Int>, tabBarOptions: Binding<[CommunityPageTabItem]>) {
        self._currentTab = currentTab
        self._tabBarOptions = tabBarOptions
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabBarOptions) { item in
                    CommunityPageTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: item)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}

struct CommunityPageTabBarItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    var tabItem: CommunityPageTabItem
    
    var body: some View {
        Button {
            self.currentTab = tabItem.index
        } label: {
            VStack(spacing: 0) {
                
                HStack {
                    Image(tabItem.image)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(currentTab == tabItem.index ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade3))
                }
                .frame(width: 70)
                .padding(.bottom, 12)
                
                // Underline
                if currentTab == tabItem.index {
                    Color(viewConfig.theme.highlightColor)
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

struct CommunityPageTabItem: Identifiable, Equatable {
    let id: UUID
    let index: Int
    let image: ImageResource
    
    init(index: Int, image: ImageResource) {
        self.id = UUID()
        self.index = index
        self.image = image
    }
    
}
