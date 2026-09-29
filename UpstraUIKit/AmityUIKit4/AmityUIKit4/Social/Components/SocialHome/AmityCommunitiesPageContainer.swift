//
//  AmityCommunitiesPageContainer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/10/25.
//

import SwiftUI

struct AmityCommunitiesPageContainer: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = []

    public init() { }

    /// Explore belongs to Discovery, My Communities to Community, and this bar
    /// had neither gate — Discovery off left the Explore tab selected and its
    /// categories, trending and recommended rows drawing underneath.
    private var exploreVisible: Bool { !viewConfig.isHidden(elementId: .exploreButton) }

    private var tabTitles: [String] {
        var t: [String] = []
        if exploreVisible { t.append(AmityLocalizedStringSet.Social.socialHomeExploreTab.localizedString) }
        t.append(AmityLocalizedStringSet.Social.socialHomeMyCommunitiesTab.localizedString)
        return t
    }

    var body: some View {
        if AmityUIKitManagerInternal.shared.isGuestUser {
            if exploreVisible { AmityExplorePageContainer() }
        } else if !exploreVisible {
            // One tab left, so the bar and its rule go too: a two-tab bar showing
            // one tab is the seam rule 3 exists to remove.
            AmityMyCommunitiesComponent(pageId: .socialHomePage)
        } else {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                        .selectedTabColor(viewConfig.theme.primaryColor)
                        .tabBarAccessibilityIDs([
                            AccessibilityID.Social.CommunitiesTab.explore,
                            AccessibilityID.Social.CommunitiesTab.myCommunities
                        ])
                        .onChange(of: tabIndex) { value in

                        }
                        .padding(.leading, 16)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)
                }
                
                TabView(selection: $tabIndex) {
                    AmityExplorePageContainer()
                        .tag(0)
                    
                    AmityMyCommunitiesComponent(pageId: .socialHomePage)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 8)
            }
            .onAppear { tabs = tabTitles }
            .onReceive(NotificationCenter.default.publisher(for: .showExploreCommunities)) { _ in
                tabIndex = 0
            }
        }
    }
}
