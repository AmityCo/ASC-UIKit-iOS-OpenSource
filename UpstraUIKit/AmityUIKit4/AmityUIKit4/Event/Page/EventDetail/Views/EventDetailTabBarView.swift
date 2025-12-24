//
//  EventDetailTabBarView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/11/25.
//

import SwiftUI

struct EventDetailTabBarView: View {
    
    @Binding var currentTab: Int
    @Namespace var namespace
    @StateObject var viewConfig: AmityViewConfigController
    
    public init(currentTab: Binding<Int>, pageId: PageId = .communityProfilePage) {
        self._currentTab = currentTab
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: nil))
    }
    
    var body: some View {
        HStack(spacing: 20) {
            let eventItem = TabItem(index: 0, image: AmityIcon.createEventMenuIcon.imageResource)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: eventItem)
            
            let feedItem = TabItem(index: 1, image: AmityIcon.eventDiscussionTabIcon.imageResource)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: feedItem)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}
