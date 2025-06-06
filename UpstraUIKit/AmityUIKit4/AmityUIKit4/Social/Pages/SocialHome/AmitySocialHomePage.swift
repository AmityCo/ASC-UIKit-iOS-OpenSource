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
    
    @StateObject private var viewModel: AmitySocialHomePageViewModel = AmitySocialHomePageViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    
    let showBackButton: Bool
    
    public init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .socialHomePage))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showBackButton {
                AmityNavigationBar(title: "", showBackButton: showBackButton)
            }
            
            AmitySocialHomeTopNavigationComponent(pageId: id, selectedTab: viewModel.selectedTab, searchButtonAction: {
                if viewModel.selectedTab == .newsFeed || viewModel.selectedTab == .explore {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToGlobalSearchPage(context: context)
                    
                } else if viewModel.selectedTab == .myCommunities {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToMyCommunitiesSearchPage(context: context)
                }
            }) {
                let context = AmitySocialHomePageBehavior.Context(page: self)
                AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToNotificationTrayPage(context: context)

            }
            
            SocialHomePageTabView($viewModel.selectedTab)
                .frame(height: 62)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 8)

            SocialHomeContainerView($viewModel.selectedTab, pageId: id)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .ignoresSafeArea(edges: .bottom)
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
}


class AmitySocialHomePageViewModel: ObservableObject {
    @Published var selectedTab: AmitySocialHomePageTab = .newsFeed
    
    init() {
        /// Observe didPostCreated event sent from AmityPostCreationPage
        /// We need to explicitly change the tab to Newsfeed.
        NotificationCenter.default.addObserver(self, selector: #selector(didPostCreated(_:)), name: .didPostCreated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didPostCreated(_ notification: Notification) {
//        selectedTab = .newsFeed
    }
}
