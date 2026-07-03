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
    @ObservedObject private var globalBannedViewModel =  AmityGlobalBannedViewModel.shared
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
                if viewModel.selectedTab == .forYou || viewModel.selectedTab == .newsFeed || viewModel.selectedTab == .explore || viewModel.selectedTab == .communities || viewModel.selectedTab == .events {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToGlobalSearchPage(context: context)
                } else if viewModel.selectedTab == .myCommunities {
                    let context = AmitySocialHomePageBehavior.Context(page: self)
                    AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToMyCommunitiesSearchPage(context: context)
                }
            }, notificationButtonAction: {
                let context = AmitySocialHomePageBehavior.Context(page: self)
                AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToNotificationTrayPage(context: context)
            })
            
            if viewModel.isForYouSettingLoading {
                SocialHomePageTabSkeletonView()
            } else {
                SocialHomePageTabView($viewModel.selectedTab, isForYouEnabled: viewModel.isForYouEnabled, onSelection: { tab in
                    if tab == .clips {
                        let clipFeedAction: (ClipFeedAction) -> Void = { action in
                            switch action {
                            case .exploreCommunity:
                                self.host.controller?.navigationController?.popViewController(animated: true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    self.viewModel.selectedTab = .explore
                                }
                            case .createCommunity:
                                self.host.controller?.navigationController?.popViewController(animated: false)

                                let page = AmityCommunitySetupPage(mode: .create)
                                let vc = AmitySwiftUIHostingController(rootView: page)
                                host.controller?.navigationController?.pushViewController(vc, animation: .presentation)
                            default:
                                break
                            }
                        }
                        let context = AmitySocialHomePageBehavior.Context(page: self, clipFeedAction: clipFeedAction)
                        AmityUIKitManagerInternal.shared.behavior.socialHomePageBehavior?.goToClipFeedPage(context: context)
                    }
                })
                .frame(height: 62)
            }

            Rectangle()
                .fill(Color(viewModel.selectedTab == .communities || viewModel.selectedTab == .events ? viewConfig.theme.backgroundColor : viewConfig.theme.baseColorShade4))
                .frame(height: 8)

            if viewModel.isForYouSettingLoading {
                SocialHomeFeedSkeletonView()
            } else {
                SocialHomeContainerView($viewModel.selectedTab, pageId: id, onForYouDisabled: {
                    viewModel.handleForYouDisabled()
                }, onSwitchToFollowing: {
                    viewModel.selectedTab = .newsFeed
                })
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .ignoresSafeArea(edges: .bottom)
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .onChange(of: viewModel.selectedTab) { newTab in
            if newTab == .newsFeed {
                NotificationCenter.default.post(name: .refreshNewsfeedIfNeeded, object: nil)
            }
        }
    }
}


class AmitySocialHomePageViewModel: ObservableObject {
    @Published var selectedTab: AmitySocialHomePageTab = .forYou
    @Published var isForYouEnabled: Bool = true
    @Published var isForYouSettingLoading: Bool = false

    init() {
        if AmityUIKitManagerInternal.shared.isGuestUser {
            isForYouEnabled = false
            selectedTab = .communities
        } else {
            selectedTab = .forYou
            isForYouSettingLoading = true
            fetchForYouFeedSetting()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didPostCreated(_:)), name: .didPostCreated, object: nil)
    }

    private func fetchForYouFeedSetting() {
        Task { @MainActor [weak self] in
            let enabled = (try? await AmityUIKitManagerInternal.shared.client.getForYouFeedSetting())?.enabled ?? false
            guard let self else { return }
            if !enabled {
                self.handleForYouDisabled()
            }
            self.isForYouSettingLoading = false
        }
    }

    func handleForYouDisabled() {
        isForYouEnabled = false
        if selectedTab == .forYou {
            selectedTab = .newsFeed
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didPostCreated(_ notification: Notification) {
        //        selectedTab = .newsFeed
    }
}
