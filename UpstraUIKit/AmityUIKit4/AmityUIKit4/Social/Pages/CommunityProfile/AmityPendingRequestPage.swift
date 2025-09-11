//
//  AmityPendingRequestPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 27/5/25.
//

import SwiftUI
import AmitySDK

public enum AmityPendingRequestPageTab: Int {
    case pendingPosts = 0
    case joinRequests
}

public struct AmityPendingRequestPage: AmityPageView {
    
    public var id: PageId {
        return .pendingRequestPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = []
    
    private let community: AmityCommunity
    
    public init(community: AmityCommunity, selectedTab: AmityPendingRequestPageTab = .pendingPosts) {
        self.community = community
        
        var finalTabs = [String]()
        if community.isPostReviewEnabled {
            let tabTitle = AmityLocalizedStringSet.Social.communityPendingRequestTabPostsTitle.localized(arguments: "\(0)")
            finalTabs.append(tabTitle)
        }
        
        if community.requiresJoinApproval {
            let tabTitle = AmityLocalizedStringSet.Social.communityPendingRequestTabJoinRequestsTitle.localized(arguments: "\(0)")
            finalTabs.append(tabTitle)
        }
        
        let selection = min(finalTabs.count - 1, selectedTab.rawValue)
        self._tabIndex = State(initialValue: selection)
        self._tabs = State(initialValue: finalTabs)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .pendingRequestPage))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                    .selectedTabColor(viewConfig.theme.highlightColor)
                    .onChange(of: tabIndex) { value in
                        // Left empty
                    }
                    .padding(.horizontal)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            .padding(.top, 15)
            
            ZStack(alignment: .top) {
                TabView(selection: $tabIndex) {
                    
                    if community.isPostReviewEnabled {
                        AmityPendingPostListComponent(community: community, pageId: id, onChange: { count in
                            // First tab is always pending posts 
                            let countValue = count > 10 ? "10+" : "\(count)"
                            let tabTitle = AmityLocalizedStringSet.Social.communityPendingRequestTabPostsTitle.localized(arguments: countValue)
                            tabs[0] = tabTitle
                        })
                        .tag(0)
                    }
                    
                    if community.requiresJoinApproval {
                        AmityJoinRequestContentComponent(community: community, pageId: id, onChange: { count in
                            // Join Request Page is always last tab
                            let countValue = count > 10 ? "10+" : "\(count)"
                            let tabTitle = AmityLocalizedStringSet.Social.communityPendingRequestTabJoinRequestsTitle.localized(arguments: countValue)

                            let lastIndex = tabs.count - 1
                            tabs[lastIndex] = tabTitle
                        })
                        .tag(tabs.count > 1 ? 1 : 0)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    private var navigationBarView: some View {
        return AmityNavigationBar(title: AmityLocalizedStringSet.Social.communityPendingRequestPageTitle.localizedString, showBackButton: true)
    }
}

