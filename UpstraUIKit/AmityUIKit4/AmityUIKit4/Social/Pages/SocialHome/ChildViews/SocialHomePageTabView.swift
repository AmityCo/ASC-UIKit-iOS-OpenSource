//
//  SocialHomePageTabView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/30/24.
//

import SwiftUI

public enum AmitySocialHomePageTab: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }
    
    case newsFeed = "NewsFeed"
    case explore = "Explore"
    case myCommunities = "MyCommunities"
}

struct SocialHomePageTabView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @State private var tabItems: [TabItem]
    @Binding var selectedTab: AmitySocialHomePageTab
    
    init(_ selectedTab: Binding<AmitySocialHomePageTab>) {
        self._selectedTab = selectedTab
        
        let items = AmitySocialHomePageTab.allCases.map { tab in
            TabItem(tab: tab, selected: tab == selectedTab.wrappedValue)
        }
        
        self._tabItems = State(initialValue: items)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(tabItems) { item in
                    TabButtonView(title: getTitle(tab: item.tab), selected: item.selected)
                        .onTapGesture {
                            selectedTab = item.tab
                        }
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 2)
        }
        .onChange(of: selectedTab) { value in
            for (index, item) in tabItems.enumerated() {
                tabItems[index].selected = item.tab == value
            }
        }
        .onAppear {
            /// Filter out tabs if element is excluded in config
            tabItems = tabItems.compactMap({ item in
                if viewConfig.isHidden(elementId: .newsFeedButton) && item.tab == .newsFeed {
                    return nil
                }
                
                if viewConfig.isHidden(elementId: .exploreButton) && item.tab == .explore {
                    return nil
                }
                
                if viewConfig.isHidden(elementId: .myCommunitiesButton) && item.tab == .myCommunities {
                    return nil
                }
                
                return item
            })
        }
    }
    
    private func getTitle(tab: AmitySocialHomePageTab) -> String {
        switch tab {
        case .newsFeed:
            return viewConfig.getConfig(elementId: .newsFeedButton, key: "text", of: String.self) ?? ""
        case .explore:
            return viewConfig.getConfig(elementId: .exploreButton, key: "text", of: String.self) ?? ""
        case .myCommunities:
            return viewConfig.getConfig(elementId: .myCommunitiesButton, key: "text", of: String.self) ?? ""
        }
    }
    
    private struct TabItem: Identifiable {
        var id: String {
            tab.rawValue
        }
        
        var tab: AmitySocialHomePageTab
        var selected: Bool
    }
}


private struct TabButtonView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    private let selected: Bool
    private let title: String
    
    @State private var buttonWidth: CGFloat = 0
    
    init(title: String, selected: Bool) {
        self.title = title
        self.selected = selected
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(selected ? Color(viewConfig.defaultLightTheme.backgroundColor) : Color(viewConfig.theme.secondaryColor.blend(.shade1)))
                .font(.system(size: 17, weight: selected ? .semibold : .regular))
                .padding([.leading, .trailing], 12)
                .frame(width: buttonWidth)
        }
        .frame(height: 38)
        .background(selected ? Color(viewConfig.theme.primaryColor) : .clear)
        .clipShape(RoundedCorner())
        .overlay(
            RoundedCorner()
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .onAppear {
            buttonWidth = title.size(usingFont: .systemFont(ofSize: 17, weight: .semibold)).width + 25
        }
        
    }
}

