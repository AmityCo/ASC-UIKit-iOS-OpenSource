//
//  SocialHomeContainerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/2/24.
//

import SwiftUI

struct SocialHomeContainerView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @Binding var selectedTab: AmitySocialHomePageTab
    @State private var page: Page
    private let pageId: PageId?
    
    init(_ selectedTab: Binding<AmitySocialHomePageTab>, pageId: PageId?) {
        self._selectedTab = selectedTab
        self.pageId = pageId
        self._page = State(initialValue: Page.withIndex(AmitySocialHomePageTab.allCases.firstIndex(of: selectedTab.wrappedValue) ?? 0))
    }
    
    var body: some View {
        Pager(page: page, data: AmitySocialHomePageTab.allCases) { tab in
            switch tab {
            case .newsFeed:
                AmityNewsFeedComponent(pageId: pageId)
            case .explore:
                ComponentA()
            case .myCommunities:
                AmityMyCommunitiesComponent(pageId: pageId)
            }
        }
        .allowsDragging(false)
        .onChange(of: selectedTab) { _ in
            page.update(.new(index: AmitySocialHomePageTab.allCases.firstIndex(of: selectedTab) ?? 0))
        }
        .padding(.top, 8)
        //.background(Color(postFeedViewModel.postItems.isEmpty ? viewConfig.theme.backgroundColor : viewConfig.theme.baseColorShade4))
    }
}


struct ComponentA: View {
    var body: some View {
        VStack {
            Text("Explore Component")
        }
    }
}

