//
//  SocialHomePageTabView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/30/24.
//

import SwiftUI

public enum AmitySocialHomePageTab: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case forYou = "ForYou"
    case newsFeed = "NewsFeed"
    case clips = "Clips"
    case explore = "Explore"
    case communities = "Communities"
    case events = "Events"
    case myCommunities = "MyCommunities"
}

struct SocialHomePageTabView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @State private var tabItems: [TabItem]
    @Binding var selectedTab: AmitySocialHomePageTab

    let isForYouEnabled: Bool
    let onSelection: (AmitySocialHomePageTab) -> Void

    init(_ selectedTab: Binding<AmitySocialHomePageTab>, isForYouEnabled: Bool, onSelection: @escaping (AmitySocialHomePageTab) -> Void) {
        self._selectedTab = selectedTab
        self.isForYouEnabled = isForYouEnabled
        self.onSelection = onSelection

        self._tabItems = State(initialValue: Self.makeTabItems(selectedTab: selectedTab.wrappedValue, isForYouEnabled: isForYouEnabled))
    }

    static func makeTabItems(selectedTab: AmitySocialHomePageTab, isForYouEnabled: Bool) -> [TabItem] {
        SocialHomeTabs(isForYouEnabled: isForYouEnabled).visible.map { tab in
            TabItem(tab: tab, selected: tab == selectedTab)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabItems) { item in
                    TabButtonView(title: getTitle(tab: item.tab), selected: item.selected)
                        .onTapGesture {
                            onSelection(item.tab)

                            if item.tab != .clips {
                                selectedTab = item.tab
                            }
                        }
                        .accessibilityIdentifier(getAccessibilityID(tab: item.tab))
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 2)
        }
        .onChange(of: selectedTab) { value in
            for (index, item) in tabItems.enumerated() {
                tabItems[index].selected = item.tab == value
            }
        }
        .onChange(of: isForYouEnabled) { newValue in
            tabItems = Self.makeTabItems(selectedTab: selectedTab, isForYouEnabled: newValue)
        }
        .onAppear {
            applyConfigFilter()
        }
        // A module switched on or off while the page is up changes the row.
        .onReceive(NotificationCenter.default.publisher(for: .configDidUpdate).receive(on: DispatchQueue.main)) { _ in
            applyConfigFilter()
        }
    }

    /// Rebuilds the row from `SocialHomeTabs`, which already drops every tab
    /// whose element the config or the module gate excludes — the same list
    /// the page lands on and the pager pages over.
    private func applyConfigFilter() {
        tabItems = Self.makeTabItems(selectedTab: selectedTab, isForYouEnabled: isForYouEnabled)
    }

    private func getTitle(tab: AmitySocialHomePageTab) -> String {
        switch tab {
        case .forYou:
            let t = viewConfig.forElement(.forYouButton).text
            return (t?.isEmpty == false) ? t! : AmityLocalizedStringSet.Social.socialHomeForYouTab.localizedString
        case .newsFeed:
            let t = viewConfig.forElement(.newsFeedButton).text
            return (t?.isEmpty == false) ? t! : AmityLocalizedStringSet.Social.socialHomeNewsfeedTab.localizedString
        case .explore:
            let t = viewConfig.forElement(.exploreButton).text
            return (t?.isEmpty == false) ? t! : AmityLocalizedStringSet.Social.socialHomeExploreTab.localizedString
        case .clips:
            let t = viewConfig.forElement(.clipsFeedButton).text
            return (t?.isEmpty == false) ? t! : AmityLocalizedStringSet.Social.socialHomeClipsTab.localizedString
        case .myCommunities:
            let t = viewConfig.forElement(.myCommunitiesButton).text
            return (t?.isEmpty == false) ? t! : AmityLocalizedStringSet.Social.socialHomeMyCommunitiesTab.localizedString
        case .communities:
            return AmityLocalizedStringSet.Social.socialHomeCommunitiesTab.localizedString
        case .events:
            return AmityLocalizedStringSet.Social.socialHomeEventsTab.localizedString
        }
    }

    private func getAccessibilityID(tab: AmitySocialHomePageTab) -> String {
        switch tab {
        case .forYou: AccessibilityID.Social.SocialHomePage.forYouButton
        case .newsFeed: AccessibilityID.Social.SocialHomePage.newsFeedButton
        case .explore: AccessibilityID.Social.SocialHomePage.exploreButton
        case .myCommunities: AccessibilityID.Social.SocialHomePage.myCommunitiesButton
        case .clips: AccessibilityID.Social.SocialHomePage.clipsButton
        case .communities: AccessibilityID.Social.SocialHomePage.communitiesButton
        case .events:
            "events_button"
        }
    }

    struct TabItem: Identifiable {
        var id: String {
            tab.rawValue
        }

        var tab: AmitySocialHomePageTab
        var selected: Bool
    }
}


private struct TabButtonView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController

    private let selected: Bool
    private let title: String

    @State private var buttonWidth: CGFloat = 0

    init(title: String, selected: Bool) {
        self.title = title
        self.selected = selected
    }

    var body: some View {
        HStack {
            Text(title)
                .applyTextStyle(selected ? .titleBold(Color(viewConfig.defaultLightTheme.backgroundColor)) : .title(Color(viewConfig.theme.secondaryColorShade1)))
                .padding([.leading, .trailing], 12)
                .frame(width: buttonWidth)
        }
        .frame(height: 38)
        .background(selected ? Color(viewConfig.theme.primaryColor) : .clear)
        .clipShape(RoundedCorner())
        .overlay(
            RoundedCorner()
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .onAppear {
            buttonWidth = title.size(usingFont: .systemFont(ofSize: 17, weight: .semibold)).width + 25
        }

    }
}


/// The tabs Social Home shows, in order, and the one it lands on. The tab row,
/// the page's selection and the pager all read this one list, so a tab the
/// gate takes away goes from all three at once.
///
/// PDT-5561: the row used to filter itself while the selection and the pager
/// did not. Feed off (Post off takes Feed with it) hid For You and Following
/// but left the page selected on one of them, and left that tab first in the
/// pager — rendering as `EmptyView` under `AmityModuleGate`, zero wide, while
/// the pager still offset for it. Communities and Events then drew half a
/// screen to the left.
struct SocialHomeTabs {
    let visible: [AmitySocialHomePageTab]

    init(isForYouEnabled: Bool,
         isGuest: Bool = AmityUIKitManagerInternal.shared.isGuestUser,
         clipViewAccess: AccessLevel = AmityUIKitConfigController.shared.featureFlag?.post.clip.canViewTab ?? .signedInUserOnly,
         pageId: PageId = .socialHomePage) {
        var tabs: [AmitySocialHomePageTab]
        if isGuest {
            tabs = [.communities, .events]
            if clipViewAccess == .all {
                tabs.append(.clips)
            }
        } else {
            tabs = isForYouEnabled ? [.forYou] : []
            tabs.append(contentsOf: [.newsFeed, .communities, .events, .clips])
        }
        visible = tabs.filter { !Self.isGated($0, pageId: pageId) }
    }

    /// The element the tab's button is, as the config and the gate know it.
    static func elementId(_ tab: AmitySocialHomePageTab) -> ElementId {
        switch tab {
        case .forYou: .forYouButton
        case .newsFeed: .newsFeedButton
        case .explore: .exploreButton
        case .myCommunities: .myCommunitiesButton
        case .communities: .communitiesButton
        case .events: .eventsButton
        case .clips: .clipsFeedButton
        }
    }

    /// Whether the config or the module gate excludes this tab's button. For
    /// You and Following are Feed's (§10.2), and Feed requires Post.
    static func isGated(_ tab: AmitySocialHomePageTab, pageId: PageId = .socialHomePage) -> Bool {
        AmityUIKitConfigController.shared.isExcluded(configId: "\(pageId.rawValue)/*/\(elementId(tab).rawValue)")
    }

    /// The tab to show for `selected`: itself while it is still in the row,
    /// otherwise the first tab left. Clips is never landed on — it leaves the
    /// page (REQ-013). So For You disabled lands on Following (REQ-006), a
    /// visitor on Communities (REQ-007), and a signed-in user with For You and
    /// Following both gated on Communities (PO decision on PDT-5561).
    func landing(from selected: AmitySocialHomePageTab) -> AmitySocialHomePageTab {
        let landable = visible.filter { $0 != .clips }
        if landable.contains(selected) { return selected }
        return landable.first ?? selected
    }

    /// The pages the pager holds: `loaded` without any tab the gate now
    /// excludes, since a gated page renders nothing and the pager's offsets
    /// would still count it.
    static func pagerTabs(_ loaded: [AmitySocialHomePageTab], pageId: PageId = .socialHomePage) -> [AmitySocialHomePageTab] {
        let shown = loaded.filter { !isGated($0, pageId: pageId) }
        return shown.isEmpty ? loaded : shown
    }
}
