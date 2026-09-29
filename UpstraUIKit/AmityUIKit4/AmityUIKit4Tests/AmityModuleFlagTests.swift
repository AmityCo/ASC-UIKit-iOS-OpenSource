import XCTest
import SwiftUI
@testable import AmityUIKit4

/// The gate is only worth anything if a withheld module actually hides the
/// surface. Apollo proves the three platforms generate the same owner maps
/// and that isExcluded consults them; it cannot prove the traversal is right,
/// and each platform writes that traversal by hand. This is iOS's half of that
/// proof — Android's lives in AmityModuleFlagTest, Web's in moduleFlags.test.ts.
///
/// A module is withheld here the only way one can be: by the network's
/// entitlement, under `enforce`, through the debug seam — `config.json`
/// carries no module switch. The bundle rules come from the network's catalog
/// and nowhere else, so every cascade below runs under a row. Without a row
/// nothing cascades (TC-uikit-mavail-005).
final class AmityModuleFlagTests: XCTestCase {

    private let controller = AmityUIKitConfigController.shared

    override func setUp() {
        super.setUp()
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: false, granted: [:],
                                        catalog: AmityModuleAvailabilityTests.catalog))
    }

    override func tearDown() {
        controller.setEntitlementForTesting(nil)
        controller.setConfigForTesting(["excludes": [String]()])
        super.tearDown()
    }

    /// Withhold exactly these modules: an enforcing row that grants every
    /// catalog key but the ones switched off here.
    private func withholding(_ features: [String: Any]) {
        controller.setConfigForTesting(["excludes": [String]()])
        let off = Set(features.filter { (($0.value as? [String: Any])?["enabled"] as? Bool) == false }.keys)
        let catalog = AmityModuleAvailabilityTests.catalog
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(
                isEnforcing: true,
                granted: Dictionary(uniqueKeysWithValues: catalog.keys.map { ($0, !off.contains($0)) }),
                catalog: catalog))
    }

    func testAbsentFeaturesBlockLeavesEveryModuleOn() {
        withholding([:])
        XCTAssertFalse(controller.isExcluded(configId: "post_detail_page/*/*"))
        XCTAssertFalse(controller.isExcluded(configId: "clip_feed_page/*/*"))
        XCTAssertTrue(controller.isFeatureEnabled(AmityUIKitFeature.ads))
    }

    func testSwitchingAModuleOffHidesThePagesItOwns() {
        withholding(["post": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "post_detail_page/*/*"))
        // Clip's pages are Post's.
        XCTAssertTrue(controller.isExcluded(configId: "clip_feed_page/*/*"))
        XCTAssertTrue(controller.isExcluded(configId: "draft_clip_page/*/*"))
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"))
    }

    func testADependencyGoingOffTakesItsDependentsWithIt() {
        withholding(["community": ["enabled": false]])
        // post requires community; feed requires post — two hops of the catalog.
        XCTAssertTrue(controller.isExcluded(configId: "community_profile_page/*/*"))
        XCTAssertTrue(controller.isExcluded(configId: "post_detail_page/*/*"))
        XCTAssertFalse(controller.isFeatureEnabled(AmityUIKitFeature.feed))
        // chat depends on nothing, so it survives.
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"))
    }

    func testAModuleWithNoPageOfItsOwnIsGatedAtItsComponents() {
        withholding(["feed": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "social_home_page/newsfeed_component/*"))
        XCTAssertTrue(controller.isExcluded(configId: "social_home_page/global_feed_component/*"))
        // The page hosting the feed is not the feed, and stays.
        XCTAssertFalse(controller.isExcluded(configId: "social_home_page/*/*"))
    }

    func testRequiresAnySurvivesWhileOneAlternativeIsOn() {
        withholding(["post": ["enabled": false], "story": ["enabled": false]])
        // reaction needs one of post/comment/chat/story — chat is still on.
        XCTAssertTrue(controller.isFeatureEnabled(AmityUIKitFeature.reaction))
        // product needs one of post/story — both are off.
        XCTAssertFalse(controller.isFeatureEnabled(AmityUIKitFeature.product))
    }

    func testTheNotificationTrayPageHasNoOwningModule() {
        // features.json leaves the tray unowned: it is fed by seven modules at
        // once, so any single owner emptied the items of the modules a customer
        // still has. Push Notification is OS-level push and owns only its
        // preference page; Feed no longer owns the tray either.
        withholding(["pushNotification": ["enabled": false]])
        XCTAssertFalse(controller.isExcluded(configId: "notification_tray_page/*/*"))
        XCTAssertTrue(controller.isExcluded(configId: "notification_preference_page/*/*"))

        withholding(["feed": ["enabled": false]])
        XCTAssertFalse(controller.isExcluded(configId: "notification_tray_page/*/*"))
        XCTAssertNil(amityPageModule["notification_tray_page"])
    }

    func testAComponentInsideAnotherModulesPageIsStillGated() {
        // The page table alone could not reach these: the story tab renders in
        // the newsfeed, the live chat feed inside the livestream player. Both
        // survived their own module being switched off.
        withholding(["story": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "social_home_page/story_tab_component/*"))

        withholding(["chat": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "livestream_player_page/livestream_chat_feed/*"))
        // Live itself is untouched.
        XCTAssertFalse(controller.isExcluded(configId: "livestream_player_page/*/*"))
    }

    func testTheDoorsIntoAModuleCloseWithIt() {
        // The third segment. Reading only page and component emptied a module's
        // pages and left the Clips tab, the Create Story button and the follow
        // button standing on pages other modules own.
        withholding(["post": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "social_home_page/*/clipsfeed_button"))

        withholding(["story": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "social_home_page/*/create_story_button"))

        withholding(["userRelationship": ["enabled": false]])
        XCTAssertTrue(controller.isExcluded(configId: "user_profile_page/*/follow_user_button"))
        // The profile page itself is base layer and stays.
        XCTAssertFalse(controller.isExcluded(configId: "user_profile_page/*/*"))
    }

    func testTheRelationshipRowsCloseWithUserRelationship() {
        // §10.2: the `…` menu rows and the chat sheet's block row carried no id,
        // so withholding the module left them standing — Manage blocked users
        // opening a page the module had already withheld (PDT-5564).
        withholding(["userRelationship": ["enabled": false]])
        for id in ["user_profile_page/*/block_user_button",
                   "user_profile_page/*/unblock_user_button",
                   "user_profile_page/*/manage_blocked_users_button",
                   "user_profile_page/user_profile_header/unfollow_user_button",
                   "chat_page/conversation_chat_user_action_component/block_user_button",
                   "chat_page/conversation_chat_user_action_component/unblock_user_button"] {
            XCTAssertTrue(controller.isExcluded(configId: id), id)
        }
        // The pages they sit on are not the module's, and stay.
        XCTAssertFalse(controller.isExcluded(configId: "user_profile_page/*/*"))
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/conversation_chat_user_action_component/*"))

        withholding([:])
        XCTAssertFalse(controller.isExcluded(configId: "user_profile_page/*/manage_blocked_users_button"))
    }

    func testTheEventLivestreamPlatformGoesWithLive() {
        // PDT-5613: a Virtual event's location sheet drew "Live stream" and
        // opened on it with Live off, so an event could be set up on a
        // capability the network is not entitled to.
        withholding(["live": ["enabled": false]])
        XCTAssertFalse(controller.isFeatureEnabled(AmityUIKitFeature.live))
        let options = EventPlatformOptions()
        XCTAssertEqual(options.platforms, [.external])
        XCTAssertEqual(options.defaultPlatform, .external)
        // A new location opens on the one option left.
        XCTAssertEqual(options.opening(nil).platform, .external)
        // A saved livestream location opens on External in the sheet; the
        // saved value is only replaced if the user saves a link.
        let saved = EventLocation(type: .virtual, platform: .livestream)
        XCTAssertEqual(options.opening(saved).platform, .external)
        XCTAssertEqual(options.opening(saved).type, .virtual)
        // An external location is left exactly as it was.
        let external = EventLocation(type: .virtual, platform: .external, externalPlatformUrl: "https://example.com")
        XCTAssertEqual(options.opening(external), external)
        // The page is Events', and Events stays.
        XCTAssertTrue(controller.isFeatureEnabled(AmityUIKitFeature.events))
    }

    func testTheEventLivestreamPlatformStaysWithLiveOn() {
        // Negative control: nothing changes with every module on.
        withholding([:])
        let options = EventPlatformOptions()
        XCTAssertEqual(options.platforms, [.livestream, .external])
        XCTAssertEqual(options.defaultPlatform, .livestream)
        XCTAssertEqual(options.opening(nil).platform, .livestream)
        let saved = EventLocation(type: .virtual, platform: .livestream)
        XCTAssertEqual(options.opening(saved), saved)
    }

    func testCommentOffTakesTheComposerOffEveryMount() {
        // PDT-5563: switching Comment off removed the count and the list and
        // left the composer on post detail, because the composer carried no
        // id and never asked. The same composer sits in the comment tray the
        // clip feed and stories open.
        withholding(["comment": ["enabled": false]])
        for page: PageId? in [.postDetailPage, .clipFeedPage, .storyPage, nil] {
            XCTAssertFalse(CommentComposerView.isShown(on: page),
                           "composer still shown on \(page?.rawValue ?? "*") with Comment off")
        }
        // The door into the tray from the clip feed closes with it.
        XCTAssertTrue(controller.isExcluded(configId: "clip_feed_page/*/comment_button"))
        // Post itself stays: the page is not Comment's.
        XCTAssertFalse(controller.isExcluded(configId: "post_detail_page/*/*"))

        // Negative control: with Comment on nothing changes.
        withholding([:])
        for page: PageId? in [.postDetailPage, .clipFeedPage, .storyPage, nil] {
            XCTAssertTrue(CommentComposerView.isShown(on: page),
                          "composer hidden on \(page?.rawValue ?? "*") with Comment on")
        }
        XCTAssertFalse(controller.isExcluded(configId: "clip_feed_page/*/comment_button"))
    }

    func testTheEventDetailPostDoorsCloseWithPost() {
        // PDT-5566 / PDT-5616: the page is Events', so Post off left the
        // discussion tab, its create-post button, "Post event to feed" and the
        // success sheet's prompt standing — none of them asked the gate.
        withholding(["post": ["enabled": false]])
        // The gate already knew (§10.2); the page never asked it.
        XCTAssertTrue(controller.isExcluded(configId: "event_detail_page/event_discussion/*"))
        XCTAssertTrue(controller.isExcluded(configId: "event_detail_page/*/create_event_post_button"))
        let doors = EventDetailPostDoors()
        XCTAssertFalse(doors.showsDiscussion)
        XCTAssertFalse(doors.showsDiscussionCreatePost)
        XCTAssertFalse(doors.showsPostToFeed)
        XCTAssertEqual(doors.tabs, [EventDetailPostDoors.eventTab])
        // A Discussion selection falls back to the Event tab.
        XCTAssertEqual(doors.visibleTab(EventDetailPostDoors.discussionTab), EventDetailPostDoors.eventTab)
        // The page itself is Events', and stays.
        XCTAssertFalse(controller.isExcluded(configId: "event_detail_page/*/*"))
    }

    func testTheEventDetailPostDoorsStayWithPostOn() {
        // Negative control: the same doors with every module on.
        withholding([:])
        let doors = EventDetailPostDoors()
        XCTAssertTrue(doors.showsDiscussion)
        XCTAssertTrue(doors.showsDiscussionCreatePost)
        XCTAssertTrue(doors.showsPostToFeed)
        XCTAssertEqual(doors.tabs, [EventDetailPostDoors.eventTab, EventDetailPostDoors.discussionTab])
        XCTAssertEqual(doors.visibleTab(EventDetailPostDoors.discussionTab), EventDetailPostDoors.discussionTab)

        // A customer's own exclude of the discussion button hides only the button.
        controller.setConfigForTesting(["excludes": ["event_detail_page/event_discussion/event_discussion_create_post_button"]])
        let customised = EventDetailPostDoors()
        XCTAssertTrue(customised.showsDiscussion)
        XCTAssertFalse(customised.showsDiscussionCreatePost)
        XCTAssertTrue(customised.showsPostToFeed)
    }

    func testThePureTraversalMatchesTheLoadedOne() {
        // A host rendering its own switches resolves through resolveFeature(_:flags:).
        // If it answered differently from the gate for the same flags, the host
        // would show a module as on that the UIKit treats as off.
        withholding(["community": ["enabled": false]])
        let flags = ["community": false]
        for key in AmityUIKitFeature.allCases.map(\.rawValue) {
            XCTAssertEqual(
                controller.isFeatureEnabled(key),
                controller.resolveFeature(key, flags: flags),
                "\(key) resolves differently through the gate than through the flags"
            )
        }
    }

    // MARK: PDT-5867 — the create-content "+" follows its menu

    /// Whether the social home's "+" is drawn, through the same view configs
    /// AmitySocialHomeTopNavigationComponent builds. The per-user inputs
    /// default to granted, so only the module gate decides.
    private func showsCreateContentButton(allowsStoryCreation: Bool = true, canCreateEvent: Bool = true) -> Bool {
        AmitySocialHomeTopNavigationComponent.showsPostCreationButton(
            navigation: AmityViewConfigController(pageId: .socialHomePage, componentId: .socialHomePageTopNavigationComponent),
            menu: AmityViewConfigController(pageId: .socialHomePage, componentId: .createPostMenu),
            allowsStoryCreation: allowsStoryCreation, canCreateEvent: canCreateEvent)
    }

    /// The items the menu draws, with the user's inputs.
    private func shownMenuItems(allowsStoryCreation: Bool, canCreateEvent: Bool) -> [PostMenuType] {
        AmityCreatePostMenuComponent.shownItems(
            AmityViewConfigController(pageId: .socialHomePage, componentId: .createPostMenu),
            allowsStoryCreation: allowsStoryCreation, canCreateEvent: canCreateEvent)
    }

    /// The menu items the gate lets through, in the menu's order.
    private func availableMenuItems() -> [PostMenuType] {
        let menu = AmityViewConfigController(pageId: .socialHomePage, componentId: .createPostMenu)
        return PostMenuType.allCases.filter { !menu.isHidden(elementId: $0.elementId) }
    }

    func testTheCreateContentButtonStaysWithPostOff() {
        // PDT-5867: the "+" was Post's, so Post off took event and story
        // creation with it from the Event Hub. Post takes its own two items,
        // post and clip. Poll and Live require nothing in the network's
        // catalog, so they stay, as Story and Event do.
        withholding(["post": ["enabled": false]])
        XCTAssertEqual(availableMenuItems(), [.poll, .liveStream, .story, .event])
        XCTAssertTrue(showsCreateContentButton())
        // The door and the menu are unowned (§10.1).
        XCTAssertNil(amityElementModule["post_creation_button"])
        XCTAssertNil(amityComponentModule["create_post_menu"])
        XCTAssertFalse(controller.isExcluded(configId: "social_home_page/top_navigation/post_creation_button"))
    }

    func testTheCreateContentButtonGoesWhenEveryItemIsWithheld() {
        // Every item's owner withheld: post and clip (Post), poll, live, story,
        // events. A menu with nothing in it is not drawn, and neither is its door.
        let everyOwner: [String: Any] = ["post": ["enabled": false], "poll": ["enabled": false],
                                         "live": ["enabled": false], "story": ["enabled": false],
                                         "events": ["enabled": false]]
        withholding(everyOwner)
        XCTAssertEqual(availableMenuItems(), [])
        XCTAssertFalse(showsCreateContentButton())

        // One item left is enough.
        withholding(everyOwner.filter { $0.key != "events" })
        XCTAssertEqual(availableMenuItems(), [.event])
        XCTAssertTrue(showsCreateContentButton())
    }

    func testTheCreateContentButtonIsUnchangedWithEveryModuleOn() {
        // Negative control: nothing withheld, every item and the "+" stay.
        withholding([:])
        XCTAssertEqual(availableMenuItems(), PostMenuType.allCases)
        XCTAssertTrue(showsCreateContentButton())

        // A customer's own exclude still reaches the "+" itself.
        controller.setConfigForTesting(["excludes": ["social_home_page/top_navigation/post_creation_button"]])
        XCTAssertFalse(showsCreateContentButton())
        // Excluding the whole menu empties it, and the "+" goes with it.
        controller.setConfigForTesting(["excludes": ["*/create_post_menu/*"]])
        XCTAssertEqual(availableMenuItems(), [])
        XCTAssertFalse(showsCreateContentButton())
    }

    func testTheCreateContentButtonFollowsWhatTheMenuShowsThisUser() {
        // The evidence pass on eccc3b3b: Post and Story withheld, Events
        // available, a user without create-event permission — the "+" was
        // drawn and opened an empty menu, because it asked only the gate.
        // Staging's catalog takes Poll and Live with Post; this catalog does
        // not, so they are withheld here by hand.
        let off: [String: Any] = ["enabled": false]
        withholding(["post": off, "poll": off, "live": off, "story": off])
        XCTAssertEqual(availableMenuItems(), [.event])
        XCTAssertEqual(shownMenuItems(allowsStoryCreation: true, canCreateEvent: false), [])
        XCTAssertFalse(showsCreateContentButton(canCreateEvent: false))
        // With the permission, the event item keeps the door open.
        XCTAssertEqual(shownMenuItems(allowsStoryCreation: true, canCreateEvent: true), [.event])
        XCTAssertTrue(showsCreateContentButton(canCreateEvent: true))

        // The same for Story and the network's story setting.
        withholding(["post": off, "poll": off, "live": off, "events": off])
        XCTAssertEqual(availableMenuItems(), [.story])
        XCTAssertFalse(showsCreateContentButton(allowsStoryCreation: false))
        XCTAssertTrue(showsCreateContentButton(allowsStoryCreation: true))

        // Negative control: an item the gate lets through and that needs no
        // permission keeps the "+" regardless of the other two.
        withholding([:])
        XCTAssertEqual(shownMenuItems(allowsStoryCreation: false, canCreateEvent: false),
                       [.post, .poll, .liveStream, .clip])
        XCTAssertTrue(showsCreateContentButton(allowsStoryCreation: false, canCreateEvent: false))
    }

    // MARK: PDT-5617 — the community page's floating "+" follows its sheet

    /// Whether the community page's floating "+" is drawn, through the view
    /// config AmityCommunityProfilePage builds.
    private func showsCommunityCreateButton(post: Bool = true, story: Bool = true, event: Bool = true) -> Bool {
        AmityCommunityProfilePage.showsCreateButton(
            AmityViewConfigController(pageId: .communityProfilePage),
            canCreatePost: post, canManageStory: story, canCreateEvent: event)
    }

    private func communitySheetItems(post: Bool = true, story: Bool = true, event: Bool = true) -> [PostMenuType] {
        AmityCommunityProfilePage.createSheetItems(
            AmityViewConfigController(pageId: .communityProfilePage),
            canCreatePost: post, canManageStory: story, canCreateEvent: event)
    }

    func testTheCommunityCreateButtonStaysForEventsWithPostAndStoryOff() {
        // PDT-5617: the "+" was drawn on post or story permission alone, so a
        // network with Events but not Post, or an event-only member, lost the
        // only way to create an event from a community. Staging's catalog
        // takes Poll and Live with Post; this catalog does not, so they are
        // withheld here by hand.
        let off: [String: Any] = ["enabled": false]
        withholding(["post": off, "poll": off, "live": off, "story": off])
        XCTAssertNil(amityElementModule["community_create_post_button"])
        XCTAssertEqual(communitySheetItems(), [.event])
        XCTAssertTrue(showsCommunityCreateButton(event: true))
        XCTAssertFalse(showsCommunityCreateButton(event: false))

        // An event-only member, nothing withheld: the sheet holds Event.
        withholding([:])
        XCTAssertEqual(communitySheetItems(post: false, story: false, event: true), [.event])
        XCTAssertTrue(showsCommunityCreateButton(post: false, story: false, event: true))
    }

    func testTheCommunityCreateButtonGoesWhenEveryItemIsWithheld() {
        // Every item's owner withheld, every permission granted: an empty
        // sheet is not drawn, and neither is its "+".
        let off: [String: Any] = ["enabled": false]
        withholding(["post": off, "poll": off, "live": off, "story": off, "events": off])
        XCTAssertEqual(communitySheetItems(), [])
        XCTAssertFalse(showsCommunityCreateButton())
    }

    func testTheCommunityCreateButtonIsUnchangedWithEveryModuleOn() {
        // Negative control: nothing withheld, every item and the "+" stay;
        // no permission at all, no "+".
        withholding([:])
        XCTAssertEqual(communitySheetItems(), PostMenuType.allCases)
        XCTAssertTrue(showsCommunityCreateButton())
        XCTAssertFalse(showsCommunityCreateButton(post: false, story: false, event: false))
    }

    func testACustomerExcludeOfTheCommunityCreateButtonHidesIt() {
        // The id §10 names, declared so a customer can still exclude the "+".
        withholding([:])
        controller.setConfigForTesting(["excludes": ["community_profile_page/*/community_create_post_button"]])
        XCTAssertFalse(showsCommunityCreateButton())
        // Only the "+": the sheet's items are not the excluded id.
        XCTAssertEqual(communitySheetItems(), PostMenuType.allCases)
    }

    func testAnUnmappedPageIsNeverGated() {
        withholding(["community": ["enabled": false]])
        XCTAssertFalse(controller.isExcluded(configId: "visitor_usage_limit_page/*/*"))
    }

    // MARK: PDT-5561 — Social Home with For You and Following gated

    /// Where the Pager draws the page for `focused`, on a 390pt-wide screen,
    /// holding the pages SocialHomeContainerView would give it for `loaded`.
    /// For You and Following are their feed components under AmityModuleGate,
    /// as in the container; every other page reports its own left edge.
    private func socialHomePagerMinX(loaded: [AmitySocialHomePageTab], focused: AmitySocialHomePageTab) -> CGFloat? {
        final class Box { var minX: CGFloat? }
        let box = Box()
        let tabs = SocialHomeTabs.pagerTabs(loaded)
        guard let index = tabs.firstIndex(of: focused) else { return nil }
        let forYou = AmityViewConfigController(pageId: .socialHomePage, componentId: .forYouFeedComponent)
        let newsFeed = AmityViewConfigController(pageId: .socialHomePage, componentId: .newsFeedComponent)
        let view = Pager(page: .withIndex(index), data: tabs) { tab in
            switch tab {
            case .forYou: Color.red.modifier(AmityModuleGate(viewConfig: forYou))
            case .newsFeed: Color.red.modifier(AmityModuleGate(viewConfig: newsFeed))
            default:
                GeometryReader { proxy -> Color in
                    if tab == focused { box.minX = proxy.frame(in: .global).minX }
                    return Color.clear
                }
            }
        }
        .allowsDragging(false)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        host.view.layoutIfNeeded()
        return box.minX
    }

    private func signedIn(forYou: Bool = true) -> SocialHomeTabs {
        SocialHomeTabs(isForYouEnabled: forYou, isGuest: false, clipViewAccess: .signedInUserOnly)
    }

    func testSocialHomeLandsOnCommunitiesWhenPostTakesTheFeedTabs() {
        // PDT-5561: Post off takes Feed with it (catalog), and For You and
        // Following are Feed's (§10.2). The row dropped them; the selection and
        // the pager did not.
        // Clips is Post's, not Feed's: Feed off alone leaves it in the row.
        let remaining: [String: [AmitySocialHomePageTab]] = [
            "post": [.communities, .events],
            "feed": [.communities, .events, .clips],
        ]
        for (module, row) in remaining {
            withholding([module: ["enabled": false]])
            let tabs = signedIn()
            XCTAssertEqual(tabs.visible, row, "\(module) off")
            // PO decision: the first remaining tab, as for visitors (REQ-007).
            XCTAssertEqual(tabs.landing(from: .forYou), .communities, "\(module) off")
            XCTAssertEqual(tabs.landing(from: .newsFeed), .communities, "\(module) off")
            XCTAssertEqual(signedIn(forYou: false).landing(from: .newsFeed), .communities, "\(module) off")
            XCTAssertEqual(tabs.landing(from: .events), .events, "\(module) off")
        }
    }

    func testSocialHomePagerDrawsTheRemainingTabsFullWidth() {
        // The page selected on Following, then Communities, then Events — what
        // the container had loaded in the ticket. The gated Following page was
        // zero wide while the pager still offset for it: Communities drew at
        // -195 on a 390pt screen, half of it off the left edge.
        withholding(["post": ["enabled": false]])
        XCTAssertEqual(SocialHomeTabs.pagerTabs([.newsFeed, .communities, .events]), [.communities, .events])
        XCTAssertEqual(socialHomePagerMinX(loaded: [.newsFeed, .communities], focused: .communities) ?? .nan, 0, accuracy: 0.5)
        XCTAssertEqual(socialHomePagerMinX(loaded: [.newsFeed, .communities, .events], focused: .events) ?? .nan, 0, accuracy: 0.5)
        XCTAssertEqual(socialHomePagerMinX(loaded: [.forYou, .communities], focused: .communities) ?? .nan, 0, accuracy: 0.5)
    }

    func testSocialHomeIsUnchangedWithEveryModuleOn() {
        // Negative control: nothing gated, nothing moves.
        withholding([:])
        let tabs = signedIn()
        XCTAssertEqual(tabs.visible, [.forYou, .newsFeed, .communities, .events, .clips])
        XCTAssertEqual(tabs.landing(from: .forYou), .forYou)
        XCTAssertEqual(tabs.landing(from: .events), .events)
        // REQ-006: For You disabled lands on Following.
        XCTAssertEqual(signedIn(forYou: false).landing(from: .forYou), .newsFeed)
        // REQ-007: a visitor lands on Communities.
        let visitor = SocialHomeTabs(isForYouEnabled: false, isGuest: true, clipViewAccess: .signedInUserOnly)
        XCTAssertEqual(visitor.visible, [.communities, .events])
        XCTAssertEqual(visitor.landing(from: .communities), .communities)
        XCTAssertEqual(SocialHomeTabs.pagerTabs([.newsFeed, .communities]), [.newsFeed, .communities])
        XCTAssertEqual(socialHomePagerMinX(loaded: [.newsFeed, .communities], focused: .communities) ?? .nan, 0, accuracy: 0.5)
    }
}
