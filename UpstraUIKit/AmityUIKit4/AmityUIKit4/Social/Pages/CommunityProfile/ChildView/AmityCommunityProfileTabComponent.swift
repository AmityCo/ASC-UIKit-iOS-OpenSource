//
//  AmityCommunityProfileTabComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import SwiftUI

public struct AmityCommunityProfileTabComponent: AmityComponentView {
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .communityProfileTab
    }
        
    @Binding var currentTab: Int
    @Namespace var namespace
    @StateObject var viewConfig: AmityViewConfigController

    public init(currentTab: Binding<Int>, pageId: PageId = .communityProfilePage) {
        self.pageId = pageId
        self._currentTab = currentTab
        
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityProfileTab))
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            let feedIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityFeedTabButton, key: "image", of: String.self) ?? "")
            let feedTabItem = TabItem(index: 0, image: feedIcon)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: feedTabItem)
                .isHidden(viewConfig.isHidden(elementId: .communityFeedTabButton))
                .accessibilityIdentifier(AccessibilityID.Social.CommunityProfileTab.communityFeedTabButton)
            
            let pinIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityPinTabButton, key: "image", of: String.self) ?? "")
            let pinTabItem = TabItem(index: 1, image: pinIcon)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: pinTabItem)
                .isHidden(viewConfig.isHidden(elementId: .communityPinTabButton))
                .accessibilityIdentifier(AccessibilityID.Social.CommunityProfileTab.communityPinTabButton)
            
            let imageFeedTabIcon = AmityIcon.communityImageFeedIcon.getImageResource()
            let imageFeedTabItem = TabItem(index: 2, image: imageFeedTabIcon)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: imageFeedTabItem)
            
            let videoFeedTabIcon = AmityIcon.communityVideoFeedIcon.getImageResource()
            let videoFeedTabItem = TabItem(index: 3, image: videoFeedTabIcon)
            TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: videoFeedTabItem)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}
