//
//  TabBarView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/8/24.
//

import SwiftUI

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
    
    private struct TabBarItem: View {
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
                        .applyTextStyle(.titleBold(currentTab == tab ? Color(selectedTabColor) : .gray))
                    
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
}

extension TabBarView: AmityViewBuildable {
    func selectedTabColor(_ value: UIColor) -> Self {
        self.mutating(keyPath: \.selectedTabColor, value: value)
    }
}
