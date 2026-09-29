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
    /// Bumped when the config or a module changes, so `pagerTabs` is read again.
    @State private var gateRevision = 0
    private let pageId: PageId?
    private let onForYouDisabled: (() -> Void)?
    private let onSwitchToFollowing: (() -> Void)?
    private let onExploreCommunities: (() -> Void)?

    init(_ selectedTab: Binding<AmitySocialHomePageTab>, pageId: PageId?, onForYouDisabled: (() -> Void)? = nil, onSwitchToFollowing: (() -> Void)? = nil, onExploreCommunities: (() -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.pageId = pageId
        self.onForYouDisabled = onForYouDisabled
        self.onSwitchToFollowing = onSwitchToFollowing
        self.onExploreCommunities = onExploreCommunities
        self.tabs = [selectedTab.wrappedValue]
    }

    /// The tabs loaded so far, minus any the gate now excludes (PDT-5561). A
    /// gated tab's page renders nothing, zero wide, while the pager still
    /// offsets for it — so it cannot stay in the list the pager indexes.
    private var pagerTabs: [AmitySocialHomePageTab] {
        _ = gateRevision
        return SocialHomeTabs.pagerTabs(tabs, pageId: pageId ?? .socialHomePage)
    }

    var body: some View {
        Pager(page: page, data: pagerTabs) { tab in
            switch tab {
            case .forYou:
                AmityForYouFeedComponent(pageId: pageId, onFeatureDisabled: onForYouDisabled, onSwitchToFollowingRequested: onSwitchToFollowing)
            case .newsFeed:
                AmityNewsFeedComponent(pageId: pageId, onExploreCommunities: onExploreCommunities)
            case .explore:
                AmityExplorePageContainer()
            case .myCommunities:
                AmityMyCommunitiesComponent(pageId: pageId)
            case .communities:
                AmityCommunitiesPageContainer()
            case .events:
                AmityEventPageContainer()
            case .clips:
                Text(AmityLocalizedStringSet.General.clips.localizedString)
            }
        }
        .allowsDragging(false)
        .onChange(of: selectedTab) { _ in
            // Append page into Pager on demand, as Pager does not support it out of the box
            if !tabs.contains(selectedTab) {
                tabs.append(selectedTab)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                page.update(.new(index: pagerTabs.firstIndex(of: selectedTab) ?? 0))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .configDidUpdate).receive(on: DispatchQueue.main)) { _ in
            // A tab gated while the page is up leaves the list, and every page
            // after it moves down one.
            gateRevision += 1
            page.update(.new(index: pagerTabs.firstIndex(of: selectedTab) ?? 0))
        }
        .padding(.top, 8)
    }
}
