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
    case clips = "Clips"
    case myCommunities = "MyCommunities"
}

struct SocialHomePageTabView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @State private var tabItems: [TabItem]
    @Binding var selectedTab: AmitySocialHomePageTab
    
    let onSelection: (AmitySocialHomePageTab) -> Void
    
    init(_ selectedTab: Binding<AmitySocialHomePageTab>, onSelection: @escaping (AmitySocialHomePageTab) -> Void) {
        self._selectedTab = selectedTab
        self.onSelection = onSelection
        
        let clipViewAccess = AmityUIKitConfigController.shared.featureFlag?.post.clip.canViewTab ?? .signedInUserOnly
        
        var items: [TabItem] = []
        if AmityUIKitManagerInternal.shared.isGuestUser {
            items.append(TabItem(tab: .explore, selected: selectedTab.wrappedValue == .explore))

            if clipViewAccess == .all {
                items.append(TabItem(tab: .clips, selected: selectedTab.wrappedValue == .clips))
            }
        } else {
            items = AmitySocialHomePageTab.allCases.map { tab in
                TabItem(tab: tab, selected: tab == selectedTab.wrappedValue)
            }
        }
        
        self._tabItems = State(initialValue: items)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabItems) { item in
                    TabButtonView(title: getTitle(tab: item.tab), selected: item.selected)
                        .onTapGesture {
                            onSelection(item.tab)
                            
                            if item.tab != .clips {
                                selectedTab = item.tab
                            }
                        }
                        .accessibilityIdentifier(getAccessibilityID(tab: item.tab))
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
                
                if viewConfig.isHidden(elementId: .clipsButton) && item.tab == .clips {
                    return nil
                }
                
                return item
            })
            
            print("Filtered Tab Items: \(tabItems.count)")
        }
    }
    
    private func getTitle(tab: AmitySocialHomePageTab) -> String {
        switch tab {
        case .newsFeed:
            return viewConfig.forElement(.newsFeedButton).text ?? ""
        case .explore:
            return viewConfig.forElement(.exploreButton).text ?? ""
        case .clips:
            return viewConfig.forElement(.clipsButton).text ?? ""
        case .myCommunities:
            return viewConfig.forElement(.myCommunitiesButton).text ?? ""
        }
    }
    
    private func getAccessibilityID(tab: AmitySocialHomePageTab) -> String {
        switch tab {
        case .newsFeed: AccessibilityID.Social.SocialHomePage.newsFeedButton
        case .explore: AccessibilityID.Social.SocialHomePage.exploreButton
        case .myCommunities: AccessibilityID.Social.SocialHomePage.myCommunitiesButton
        case .clips: AccessibilityID.Social.SocialHomePage.clipsButton
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
                .applyTextStyle(selected ? .titleBold(Color(viewConfig.defaultLightTheme.backgroundColor)) : .title(Color(viewConfig.theme.secondaryColorShade1)))
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

