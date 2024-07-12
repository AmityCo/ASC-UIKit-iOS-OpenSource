//
//  AmitySocialHomePage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/29/24.
//

import Foundation
import SwiftUI

public struct AmitySocialHomePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .socialHomePage
    }
    
    @State private var selectedTab: AmitySocialHomePageTab = .newsFeed
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .socialHomePage))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AmitySocialHomeTopNavigationComponent(pageId: id, selectedTab: selectedTab, searchButtonAction: {
                if selectedTab == .newsFeed {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToGlobalSearchPage(context: context)
                    
                } else if selectedTab == .myCommunities {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToMyCommunitiesSearchPage(context: context)
                }
            })
            
            SocialHomePageTabView($selectedTab)
                .frame(height: 62)

            SocialHomeContainerView($selectedTab, pageId: id)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .ignoresSafeArea(edges: .bottom)
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
}
