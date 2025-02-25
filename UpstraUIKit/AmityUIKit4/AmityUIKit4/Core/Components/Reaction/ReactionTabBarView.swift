//
//  ReactionTabBarView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/13/24.
//

import SwiftUI

struct ReactionTabBarView: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    @Binding var tabBarOptions: [ReactionTabItem]
        
    init(currentTab: Binding<Int>, tabBarOptions: Binding<[ReactionTabItem]>) {
        self._currentTab = currentTab
        self._tabBarOptions = tabBarOptions
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabBarOptions) { item in
                    ReactionTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: item)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ReactionTabBarItemView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    var tabItem: ReactionTabItem
    
    var body: some View {
        Button {
            self.currentTab = tabItem.index
        } label: {
            VStack(spacing: 7) {
                
                HStack {
                    if let imageResource = tabItem.image {
                        Image(imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        Text(tabItem.name)
                            .applyTextStyle(.titleBold(currentTab == tabItem.index ? Color(viewConfig.theme.highlightColor) : Color(viewConfig.theme.baseInverseColor)))
                    }
                    
                    Text("\(tabItem.count.formattedCountString)")
                        .applyTextStyle(.titleBold(currentTab == tabItem.index ? Color(viewConfig.theme.highlightColor) : Color(viewConfig.theme.baseInverseColor)))
                }
                
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

struct ReactionTabItem: Identifiable, Equatable {
    let id: UUID
    let index: Int
    let name: String
    let image: ImageResource?
    let count: Int
    
    init(index: Int, name: String, image: ImageResource?, count: Int) {
        self.id = UUID()
        self.index = index
        self.name = name
        self.image = image
        self.count = count
    }
    
    internal func isAllReactionTab() -> Bool {
        return self.name.localizedCaseInsensitiveCompare(AmityLocalizedStringSet.Reaction.allTab.localizedString) == .orderedSame
    }
}
