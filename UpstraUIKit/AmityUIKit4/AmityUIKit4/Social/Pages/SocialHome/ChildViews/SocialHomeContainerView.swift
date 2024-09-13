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
    @State private var page: Page = .first()
    @State private var tabs: [AmitySocialHomePageTab]
    private let pageId: PageId?
    
    init(_ selectedTab: Binding<AmitySocialHomePageTab>, pageId: PageId?) {
        self._selectedTab = selectedTab
        self.pageId = pageId
        self.tabs = [selectedTab.wrappedValue]
    }
    
    var body: some View {
        Pager(page: page, data: tabs) { tab in
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
            // Append page into Pager on demand, as Pager does not support it out of the box
            if !tabs.contains(selectedTab) {
                tabs.append(selectedTab)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                page.update(.new(index: tabs.firstIndex(of: selectedTab) ?? 0))
            }
        }
        .padding(.top, 8)
    }
}


struct ComponentA: View {
    var body: some View {
        VStack {
            Text("Explore Component")
        }
    }
}

