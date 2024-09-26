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
            let feedTabItem = CommunityPageTabItem(index: 0, image: feedIcon)
            CommunityPageTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: feedTabItem)
                .isHidden(viewConfig.isHidden(elementId: .communityFeedTabButton))
            
            let pinIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityPinTabButton, key: "image", of: String.self) ?? "")
            let pinTabItem = CommunityPageTabItem(index: 1, image: pinIcon)
            CommunityPageTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: pinTabItem)
                .isHidden(viewConfig.isHidden(elementId: .communityPinTabButton))
            
            let imageFeedTabIcon = AmityIcon.communityImageFeedIcon.getImageResource()
            let imageFeedTabItem = CommunityPageTabItem(index: 2, image: imageFeedTabIcon)
            CommunityPageTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: imageFeedTabItem)
            
            let videoFeedTabIcon = AmityIcon.communityVideoFeedIcon.getImageResource()
            let videoFeedTabItem = CommunityPageTabItem(index: 3, image: videoFeedTabIcon)
            CommunityPageTabBarItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: videoFeedTabItem)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
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
