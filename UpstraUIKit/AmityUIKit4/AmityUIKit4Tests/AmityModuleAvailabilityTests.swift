import XCTest
import AmitySDK
@testable import AmityUIKit4

/// Spec: UIKit module availability (Phase 1c).
///
/// The network's entitlements are the only source that withholds a module;
/// `config.json` carries no module switch (§3.1). `AmityModuleFlagTests`
/// covers the traversal over the owner maps.
///
/// Every network launches `mode: "off"`, so an enforcing network is reachable
/// only from the debug seam these tests use.
final class AmityModuleAvailabilityTests: XCTestCase {

    private let controller = AmityUIKitConfigController.shared

    /// The 15 `api` keys the catalog carries, with the chains it carries them
    /// with — Live and Poll follow Post, as staging's catalog says. `clip` is
    /// deliberately absent: it is part of Post, and the network is never asked
    /// to grant it.
    static let catalog: [String: AmityUIKitModuleEntitlement.CatalogEntry] = [
        "community": .init(requires: []),
        "chat": .init(requires: []),
        "live": .init(requires: []),
        "poll": .init(requires: []),
        "userRelationship": .init(requires: []),
        "pushNotification": .init(requires: []),
        "post": .init(requires: ["community"]),
        "story": .init(requires: ["community"]),
        "events": .init(requires: ["community"]),
        "feed": .init(requires: ["post"]),
        "comment": .init(requires: ["post", "story"]),
        "reaction": .init(requires: ["post", "comment", "chat", "story"]),
        "product": .init(requires: ["post", "story"]),
        "ads": .init(requires: ["post", "story"]),
        "discovery": .init(requires: ["community", "post", "chat"]),
    ]

    private func withConfig(_ features: [String: Any] = [:]) {
        controller.setConfigForTesting(["features": features, "excludes": [String]()])
    }

    private func withEntitlement(enforcing: Bool, granted: [String: Bool] = [:]) {
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: enforcing,
                                        granted: granted,
                                        catalog: Self.catalog)
        )
    }

    override func tearDown() {
        controller.setEntitlementForTesting(nil)
        withConfig()
        super.tearDown()
    }

    // tc: TC-uikit-mavail-001
    func testAFeaturesBlockInConfigWithholdsNothing() {
        // The customer's switch is withdrawn: the plan is the only source.
        // Every module switched off in the file, clip included, and a network
        // that granted them all — every module stays available.
        let everyModuleOff = Dictionary(uniqueKeysWithValues:
            (AmityUIKitFeature.allCases.map(\.rawValue) + ["clip"]).map { ($0, ["enabled": false]) })
        withEntitlement(enforcing: true,
                        granted: Dictionary(uniqueKeysWithValues: Self.catalog.keys.map { ($0, true) }))
        withConfig(everyModuleOff)
        for feature in AmityUIKitFeature.allCases {
            XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(feature),
                           .available(feature: feature), feature.rawValue)
        }
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"))
        assertClipSurfaces(excluded: false, "config.json carries no clip switch")

        // And with no row at all.
        controller.setEntitlementForTesting(nil)
        XCTAssertTrue(AmityUIKit4Manager.moduleAvailability.allSatisfy(\.isAvailable))
    }

    func testTheBundledConfigCarriesNoFeaturesBlock() throws {
        let path = try XCTUnwrap(AmityUIKit4Manager.bundle.path(forResource: "AmityUIKitConfig", ofType: "json"))
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path)))
        let config = try XCTUnwrap(json as? [String: Any])
        XCTAssertNil(config["features"])
    }

    // tc: TC-uikit-mavail-002
    func testUngrantedUnderEnforceIsNotGranted() {
        withEntitlement(enforcing: true, granted: ["community": true, "post": true])
        withConfig()
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.chat),
                       .notGranted(feature: .chat))
        XCTAssertTrue(controller.isExcluded(configId: "chat_page/*/*"))
        XCTAssertFalse(controller.isExcluded(configId: "post_detail_page/*/*"))
    }

    // tc: TC-uikit-mavail-003
    func testAGrantedModuleIsAvailable() {
        withEntitlement(enforcing: true, granted: ["community": true, "post": true])
        withConfig()
        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.post))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.post),
                       .available(feature: .post))
    }

    // tc: TC-uikit-mavail-004
    func testOffWithNoGrantsLeavesEveryModuleAvailable() {
        // What staging returns for every network that exists today. A gate that
        // resolved unavailable here would hide 15 working modules everywhere.
        withEntitlement(enforcing: false, granted: [:])
        withConfig()
        for feature in AmityUIKitFeature.allCases {
            XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(feature), feature.rawValue)
        }
    }

    // tc: TC-uikit-mavail-005
    func testNoEntitlementPayloadLeavesEveryModuleAvailableWithNoCascade() {
        controller.setEntitlementForTesting(nil)
        withConfig()
        for feature in AmityUIKitFeature.allCases {
            XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(feature), feature.rawValue)
        }
        XCTAssertFalse(controller.isExcluded(configId: "post_detail_page/*/*"))
        // Nothing cascades: the rules arrive with the grants, and the client
        // has no authority to invent them (REQ-012). With no row there are no
        // rules, so even a host's own switch holding Community off leaves Post.
        XCTAssertTrue(AmityUIKit4Manager.moduleRequirements.values.allSatisfy {
            $0.all.isEmpty && $0.any.isEmpty
        })
        XCTAssertTrue(AmityUIKit4Manager.isModuleEnabled("post", under: ["community": false]))

        // Community withheld by a row does cascade, because now the catalog
        // has said so.
        withEntitlement(enforcing: true, granted: ["post": true])
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.post),
                       .prerequisiteUnavailable(feature: .post, unsatisfied: ["community"]))
    }

    // tc: TC-uikit-mavail-006
    func testCatalogRequiresIsAnyOf() {
        // comment requires post OR story; this network has story, not post.
        withEntitlement(enforcing: true,
                        granted: ["community": true, "story": true, "comment": true])
        withConfig()
        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.comment))
        XCTAssertFalse(AmityUIKit4Manager.isModuleAvailable(.post))
    }

    // tc: TC-uikit-mavail-007
    func testTheCatalogWinsOverFeaturesJson() {
        // features.json says feed requires post (all-of). A catalog that sells
        // feed with community alone must not keep withholding it — and since
        // no client reads features.json's rules any more, it cannot.
        var relaxed = Self.catalog
        relaxed["feed"] = .init(requires: ["community"])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: true,
                                        granted: ["community": true, "feed": true],
                                        catalog: relaxed)
        )
        withConfig()
        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.feed))
        XCTAssertFalse(AmityUIKit4Manager.isModuleAvailable(.post))
    }

    // MARK: Clip — part of Post, and nothing else (§6.2)

    /// Every clip surface: the pages, the components that sit on pages other
    /// modules own, and the doors into them. Listed by hand, not matched on
    /// "clip" in the name — a name pass is what missed `clip_caption` before.
    private static let clipConfigIds = [
        "clip_feed_page/*/*",
        "create_clip_post_page/*/*",
        "draft_clip_page/*/*",
        "community_profile_page/community_clip_feed/*",
        "user_profile_page/user_clip_feed/*",
        "*/*/blocked_user_clip_feed",
        "*/*/blocked_user_clip_feed_info",
        "*/*/private_user_clip_feed",
        "*/*/private_user_clip_feed_info",
        "*/*/cancel_create_clip_button",
        "*/*/clip_caption",
        "*/*/clips_button",
        "social_home_page/*/clipsfeed_button",
        "*/*/create_clip_button",
        "*/*/create_new_clip_button",
        "*/*/empty_clip_feed",
        "*/*/empty_user_clip_feed",
    ]

    private func assertClipSurfaces(excluded: Bool, _ why: String,
                                    line: UInt = #line) {
        for id in Self.clipConfigIds {
            XCTAssertEqual(controller.isExcluded(configId: id), excluded,
                           "\(id) — \(why)", line: line)
        }
    }

    // tc: TC-uikit-mavail-008
    func testClipFollowsPost() {
        // Post ungranted under enforce: every clip surface is withheld.
        withConfig()
        withEntitlement(enforcing: true, granted: ["community": true])
        assertClipSurfaces(excluded: true, "Post is not granted")
        XCTAssertFalse(AmityUIKitSupportedPostTypes.current.contains(.clip))

        // Post available: every clip surface is available.
        withEntitlement(enforcing: true, granted: ["community": true, "post": true])
        assertClipSurfaces(excluded: false, "Post is available")
        XCTAssertTrue(AmityUIKitSupportedPostTypes.current.contains(.clip))

        // Clip never reports notGranted: nothing reports it at all.
        XCTAssertFalse(AmityUIKit4Manager.moduleAvailability.contains { $0.feature.rawValue == "clip" })
    }

    // tc: TC-uikit-mavail-008
    func testClipIsNeverLookedUpInTheGrants() {
        // The negative control for "entitlement never controls clip": a catalog
        // that does carry `clip`, enforcing, with clip not granted. Routing clip
        // through the module verdict would withhold it here.
        var catalog = Self.catalog
        catalog["clip"] = .init(requires: [])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: true,
                                        granted: ["community": true, "post": true],
                                        catalog: catalog))
        withConfig()
        assertClipSurfaces(excluded: false, "clip is not an entitlement")
    }

    // tc: TC-uikit-mavail-008
    func testClipIsInNoPublicAPI() {
        withEntitlement(enforcing: false)
        withConfig()
        XCTAssertNil(AmityUIKitFeature(rawValue: "clip"))
        XCTAssertFalse(AmityUIKit4Manager.moduleAvailability.map(\.feature.rawValue).contains("clip"))
        XCTAssertNil(AmityUIKit4Manager.moduleRequirements["clip"])
    }

    // tc: TC-uikit-mavail-009
    func testASettingKindCatalogEntryIsIgnoredAsAModuleAndAsAPrerequisite() {
        // A catalog in which chat's rule names a Console capability that is
        // not granted. Read as a module, it would withhold chat.
        var catalog = Self.catalog.mapValues { (kind: AmityModuleKind.api, requires: $0.requires) }
        catalog["chat"] = (kind: .api, requires: ["moderationConsole"])
        catalog["moderationConsole"] = (kind: .setting, requires: [])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(enforcement: .enforce,
                                        granted: ["chat": true],
                                        catalog: catalog))
        withConfig()

        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.chat))
        XCTAssertFalse(AmityUIKit4Manager.moduleAvailability.map(\.feature.rawValue)
            .contains("moderationConsole"))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability.count, AmityUIKitFeature.allCases.count)
    }

    func testAnApiCatalogKeyTheEnumDoesNotNameIsCarriedAndIgnored() {
        // externalContent: in staging's catalog, no UIKit surface, no case in
        // AmityUIKitFeature. It must not disturb the modules the gate does know.
        var catalog = Self.catalog.mapValues { (kind: AmityModuleKind.api, requires: $0.requires) }
        catalog["externalContent"] = (kind: .api, requires: [])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(enforcement: .enforce,
                                        granted: ["chat": true, "externalContent": false],
                                        catalog: catalog))
        withConfig()
        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.chat))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability.count, AmityUIKitFeature.allCases.count)
    }

    // tc: TC-uikit-mavail-010a
    func testAnUnknownPrerequisiteKeyIsCarriedInUnsatisfied() {
        // chat requires one of externalContent (a key this build's enum does
        // not name) or community, and neither is granted. Filtering the list
        // down to AmityUIKitFeature left only "community" — hiding the other
        // prerequisite that would have done. Order is the catalog's.
        var catalog = Self.catalog.mapValues { (kind: AmityModuleKind.api, requires: $0.requires) }
        catalog["externalContent"] = (kind: .api, requires: [])
        catalog["chat"] = (kind: .api, requires: ["externalContent", "community"])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(enforcement: .enforce,
                                        granted: ["chat": true],
                                        catalog: catalog))
        withConfig()
        XCTAssertNil(AmityUIKitFeature(rawValue: "externalContent"))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.chat),
                       .prerequisiteUnavailable(feature: .chat,
                                                unsatisfied: ["externalContent", "community"]))

        // Alone, too: an unknown key that is the whole requirement.
        catalog["chat"] = (kind: .api, requires: ["externalContent"])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(enforcement: .enforce,
                                        granted: ["chat": true, "community": true],
                                        catalog: catalog))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.chat),
                       .prerequisiteUnavailable(feature: .chat, unsatisfied: ["externalContent"]))
    }

    func testOnlyEnforceWithholds() {
        withConfig()
        let catalog = Self.catalog.mapValues { (kind: AmityModuleKind.api, requires: $0.requires) }
        for mode in [AmityModuleEnforcementMode.off, .shadow] {
            controller.setEntitlementForTesting(
                AmityUIKitModuleEntitlement(enforcement: mode, granted: [:], catalog: catalog))
            XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.chat), mode.rawValue)
        }
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(enforcement: .enforce, granted: [:], catalog: catalog))
        XCTAssertFalse(AmityUIKit4Manager.isModuleAvailable(.chat))
    }

    // tc: TC-uikit-mavail-010
    func testPrerequisiteUnavailableCarriesEveryUnsatisfiedEntry() {
        withEntitlement(enforcing: true, granted: ["community": true, "comment": true])
        withConfig()
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.comment),
                       .prerequisiteUnavailable(feature: .comment,
                                                unsatisfied: ["post", "story"]))
    }

    // tc: TC-uikit-mavail-012b
    func testASecondEntitlementReplacesTheFirstAndReachesIsExcluded() {
        // iOS memoises no exclusion — isExcluded asks the snapshot — so there
        // is no excludedCache to go stale. What must hold is the effect.
        withConfig()
        withEntitlement(enforcing: true, granted: ["chat": true])
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"))
        withEntitlement(enforcing: true, granted: ["community": true])
        XCTAssertTrue(controller.isExcluded(configId: "chat_page/*/*"),
                      "an exclusion decision taken under the old grants survived")
        withEntitlement(enforcing: true, granted: ["chat": true])
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"))
    }

    // tc: TC-uikit-mavail-013
    func testAConfigReloadRebuildsTheSnapshotAndKeepsTheEntitlement() throws {
        // The syncNetworkConfig() path: RemoteConfig writes the file, then
        // refreshConfig() -> loadConfig(). Driven through setConfigFile, which
        // takes that same loadConfig.
        withEntitlement(enforcing: true, granted: ["community": true, "post": true, "chat": true])
        withConfig()
        XCTAssertTrue(AmityUIKit4Manager.isModuleAvailable(.chat))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mavail-013-\(UUID().uuidString).json")
        let json = try JSONSerialization.data(withJSONObject: [
            "features": ["chat": ["enabled": false]], "excludes": ["chat_page/*/*"],
        ])
        try json.write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
            // Point the controller back at the bundled file, so a later reload
            // elsewhere in the suite does not read a deleted temp path.
            if let bundled = AmityUIKit4Manager.bundle.path(forResource: "AmityUIKitConfig", ofType: "json") {
                AmityUIKit4Manager.setConfigFile(bundled)
            }
        }

        AmityUIKit4Manager.setConfigFile(url.path)
        // The reload replaced `config.excludes`, which isExcluded reads...
        XCTAssertTrue(controller.isExcluded(configId: "chat_page/*/*"))
        // ...and its `features` block moved no module.
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.chat), .available(feature: .chat))
        // The rebuild kept the grants it was built from.
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.story), .notGranted(feature: .story))
        XCTAssertTrue(controller.snapshotMatchesEntitlementForTesting())
    }

    // tc: TC-uikit-mavail-015
    func testTenThousandReadsIssueNoIOAndNoWalk() {
        withConfig()
        var reads = 0
        AmityUIKitConfigController.moduleEntitlementReaderForTesting = {
            reads += 1
            return nil
        }
        defer { AmityUIKitConfigController.moduleEntitlementReaderForTesting = nil }
        withEntitlement(enforcing: true, granted: ["community": true, "post": true])
        AmityUIKitConfigController.walksForTesting = 0

        for i in 0..<10_000 {
            _ = AmityUIKit4Manager.isModuleAvailable(AmityUIKitFeature.allCases[i % AmityUIKitFeature.allCases.count])
        }
        XCTAssertEqual(reads, 0, "a gate read went to the store")
        XCTAssertEqual(AmityUIKitConfigController.walksForTesting, 0,
                       "a gate read walked the dependency chain instead of the snapshot")

        // And the counter is live: a rebuild is one walk.
        withConfig()
        XCTAssertEqual(AmityUIKitConfigController.walksForTesting, 1)
    }

    // tc: TC-uikit-mavail-016
    func testARebuildConcurrentWithReadsNeverYieldsAPartialSnapshot() {
        withConfig()
        let everything = AmityUIKitModuleEntitlement(
            isEnforcing: true,
            granted: Dictionary(uniqueKeysWithValues: Self.catalog.keys.map { ($0, true) }),
            catalog: Self.catalog)
        let chatOnly = AmityUIKitModuleEntitlement(
            isEnforcing: true, granted: ["chat": true], catalog: Self.catalog)

        controller.setEntitlementForTesting(everything)
        let whole1 = controller.moduleAvailabilities()
        controller.setEntitlementForTesting(chatOnly)
        let whole2 = controller.moduleAvailabilities()
        XCTAssertNotEqual(whole1, whole2)

        let lock = NSLock()
        var torn = 0
        DispatchQueue.concurrentPerform(iterations: 2_000) { i in
            if i % 2 == 0 {
                controller.setEntitlementForTesting(i % 4 == 0 ? everything : chatOnly)
            } else {
                let seen = controller.moduleAvailabilities()
                if seen != whole1 && seen != whole2 {
                    lock.lock(); torn += 1; lock.unlock()
                }
            }
        }
        XCTAssertEqual(torn, 0, "a read saw a snapshot that was neither whole answer")
        // Out-of-order rebuilds leave a snapshot that disagrees with the
        // entitlement held beside it.
        XCTAssertTrue(controller.snapshotMatchesEntitlementForTesting())
    }

    // tc: TC-uikit-mavail-011
    func testUngrantedAndShortOfPrerequisitesIsNotGranted() {
        // live ungranted under enforce, and its prerequisite post ungranted as
        // well. Both hold; the one about Live itself is the reason —
        // prerequisiteUnavailable would send the customer to ask for Post,
        // which would not give them Live.
        var catalog = Self.catalog
        catalog["live"] = .init(requires: ["post"])
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: true,
                                        granted: ["community": true],
                                        catalog: catalog))
        withConfig()
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.post), .notGranted(feature: .post))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.live), .notGranted(feature: .live))

        // The control: granted, the same short prerequisite is the reason.
        controller.setEntitlementForTesting(
            AmityUIKitModuleEntitlement(isEnforcing: true,
                                        granted: ["community": true, "live": true],
                                        catalog: catalog))
        XCTAssertEqual(AmityUIKit4Manager.moduleAvailability(.live),
                       .prerequisiteUnavailable(feature: .live, unsatisfied: ["post"]))
    }
}

/// Spec: UIKit module availability REQ-003a, REQ-019 · SDK getModuleSettings
/// REQ-004b.
///
/// `refreshModuleEntitlements()` runs during setup, and on a first install
/// there is no row to read then — the SDK writes it once the session
/// establishes, afterwards. The iOS SDK tells its holders: after each
/// successful write it posts `AmityModuleSettings.didUpdateNotification`, and
/// the UIKit re-reads on it. Gate queries never read the store.
///
/// The notification is posted here exactly as the SDK posts it — on the main
/// thread, `object` nil, no `userInfo` — and the SDK read is replaced by
/// `moduleEntitlementReaderForTesting`, whose calls are counted.
final class AmityModuleEntitlementArrivalTests: XCTestCase {

    private let controller = AmityUIKitConfigController.shared

    private static let catalog: [String: AmityUIKitModuleEntitlement.CatalogEntry] = [
        "community": .init(requires: []),
        "chat": .init(requires: []),
        "post": .init(requires: ["community"]),
    ]

    private static func enforcing(_ granted: String...) -> AmityUIKitModuleEntitlement {
        AmityUIKitModuleEntitlement(
            isEnforcing: true,
            granted: Dictionary(uniqueKeysWithValues: granted.map { ($0, true) }),
            catalog: catalog)
    }

    /// What the reader answers, and how many times it has been asked.
    private var row: AmityUIKitModuleEntitlement?
    private var reads = 0

    override func setUp() {
        super.setUp()
        controller.setConfigForTesting(["excludes": [String]()])
        row = nil
        reads = 0
        AmityUIKitConfigController.moduleEntitlementReaderForTesting = { [unowned self] in
            self.reads += 1
            return self.row
        }
        // Setup: a first install, nothing persisted yet.
        controller.refreshModuleEntitlements()
    }

    override func tearDown() {
        AmityUIKitConfigController.moduleEntitlementReaderForTesting = nil
        controller.setEntitlementForTesting(nil)
        controller.setConfigForTesting(["excludes": [String]()])
        super.tearDown()
    }

    /// The SDK wrote a row.
    private func sdkWroteTheRow() {
        NotificationCenter.default.post(name: AmityModuleSettings.didUpdateNotification, object: nil)
    }

    private func queryTheGate(_ times: Int) {
        for i in 0..<times {
            let feature = AmityUIKitFeature.allCases[i % AmityUIKitFeature.allCases.count]
            _ = controller.isFeatureEnabled(feature)
            _ = controller.moduleAvailability(feature)
            _ = controller.isExcluded(configId: "chat_page/*/*")
        }
        _ = controller.moduleAvailabilities()
    }

    // tc: TC-uikit-mavail-012
    func testSetupWithNoEntitlementsSucceeds() {
        // setUp ran the setup read against no row.
        XCTAssertEqual(reads, 1, "setup reads once")
        XCTAssertTrue(controller.isObservingModuleSettingsForTesting,
                      "setup registered for the SDK's change signal")
        XCTAssertTrue(controller.moduleAvailabilities().allSatisfy(\.isAvailable))
        XCTAssertTrue(AmityUIKit4Manager.moduleRequirements.values.allSatisfy {
            $0.all.isEmpty && $0.any.isEmpty
        }, "no row, no rules: nothing cascades")
    }

    // tc: TC-uikit-mavail-012a
    func testARowWrittenAfterSetupReachesTheGateThroughTheNotification() {
        // The first install: nothing to read at setup, so nothing is withheld.
        XCTAssertTrue(controller.isFeatureEnabled(.chat))

        // The SDK's fetch lands and it posts.
        row = Self.enforcing("community", "post")
        sdkWroteTheRow()

        XCTAssertFalse(controller.isFeatureEnabled(.chat),
                       "the gate is still answering from the snapshot it was built with")
        XCTAssertTrue(controller.isFeatureEnabled(.post))
        XCTAssertTrue(controller.isExcluded(configId: "chat_page/*/*"))
    }

    // tc: TC-uikit-mavail-012b
    func testASecondChangedRowInTheSameLaunchReplacesTheSnapshot() {
        row = Self.enforcing("community", "post")
        sdkWroteTheRow()
        XCTAssertTrue(controller.isExcluded(configId: "chat_page/*/*"))

        row = Self.enforcing("chat")
        sdkWroteTheRow()
        XCTAssertFalse(controller.isExcluded(configId: "chat_page/*/*"),
                       "an exclusion decision taken under the old grants survived")
        XCTAssertEqual(controller.moduleAvailability(.post), .notGranted(feature: .post))
        XCTAssertTrue(controller.snapshotMatchesEntitlementForTesting())
    }

    // tc: TC-uikit-mavail-012c
    func testGateQueriesNeverReadTheStoreBeforeOrAfterTheRow() {
        // Both halves: "no read per query" alone passes when the notification
        // is never observed either.
        XCTAssertEqual(reads, 1)
        queryTheGate(1_000)
        XCTAssertEqual(reads, 1, "a gate query read the store before the row arrived")

        row = Self.enforcing("community", "post")
        sdkWroteTheRow()
        XCTAssertEqual(reads, 2, "the notification did not make the UIKit read")
        XCTAssertFalse(controller.isFeatureEnabled(.chat))

        queryTheGate(1_000)
        XCTAssertEqual(reads, 2, "a gate query read the store after the row arrived")
    }

    // tc: TC-uikit-mavail-014
    func testAFailedRefreshKeepsThePreviousAnswer() {
        row = Self.enforcing("community", "post")
        sdkWroteTheRow()
        XCTAssertFalse(controller.isFeatureEnabled(.chat))

        // A fetch that fails writes nothing and posts nothing (SDK REQ-004b)...
        queryTheGate(10)
        XCTAssertFalse(controller.isFeatureEnabled(.chat))

        // ...and a post whose read comes back empty is not an answer either:
        // the snapshot is not rebuilt.
        row = nil
        AmityUIKitConfigController.walksForTesting = 0
        sdkWroteTheRow()
        XCTAssertEqual(AmityUIKitConfigController.walksForTesting, 0, "the snapshot was rebuilt")
        XCTAssertFalse(controller.isFeatureEnabled(.chat))
        XCTAssertTrue(controller.isFeatureEnabled(.post))
    }

    func testSettingUpAgainDoesNotSubscribeTwice() {
        // A re-setup or network switch runs the setup read again.
        controller.refreshModuleEntitlements()
        controller.refreshModuleEntitlements()
        let before = reads

        row = Self.enforcing("community")
        sdkWroteTheRow()
        XCTAssertEqual(reads - before, 1, "one post was answered by more than one observer")
    }

    func testSettingUpOnANetworkWithNoRowDropsThePreviousAnswer() {
        row = Self.enforcing("community", "post")
        sdkWroteTheRow()
        XCTAssertFalse(controller.isFeatureEnabled(.chat))

        // Switched network: the SDK dropped the store, so setup reads nothing.
        // Holding the previous network's grants would be wrong for the launch.
        row = nil
        controller.refreshModuleEntitlements()
        XCTAssertTrue(controller.moduleAvailabilities().allSatisfy(\.isAvailable))

        // And the new network's row still arrives through the notification.
        row = Self.enforcing("chat")
        sdkWroteTheRow()
        XCTAssertFalse(controller.isFeatureEnabled(.community))
    }
}
