//
//  AmityUIKitConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import Foundation
import AmitySDK
import UIKit

class AmityUIKitConfigController {
    static let shared = AmityUIKitConfigController()
    private(set) var config: [String: Any] = [:]
    private var excludedList: Set<String> = []
    private(set) var featureFlag: AmityFeatureFlag?
    private var configFilePath: String?

    /// One entry per `AmityUIKitFeature`, rebuilt when the entitlement changes.
    ///
    /// The dependency walk happens here rather than per read. Every gated page,
    /// component and element asks this question while views are being built,
    /// and the Android UIKit already measured what recursing per call costs —
    /// 2,435ns against 25ns for a map lookup.
    private var moduleSnapshot: [String: AmityUIKitModuleAvailability] = [:]

    /// The snapshot is written from setup and the notification path and read
    /// from the main thread at view-build time. A torn read of a half-rebuilt
    /// snapshot would gate inconsistently inside one frame. The snapshot and
    /// the entitlement it was built from are swapped together under this lock,
    /// so a reader never sees one without the other.
    private let snapshotLock = NSLock()

    /// Serialises whole rebuilds (REQ-026). Swapping under `snapshotLock` alone
    /// kept each write whole but not in order: two rebuilds racing — setup's
    /// read and a notification's, or a config reload — could each take the
    /// entitlement, build, and the one built from the older answer could land
    /// last, leaving a snapshot that disagreed with the entitlement it sat
    /// beside until the next rebuild.
    private let rebuildLock = NSLock()

    /// What the network was granted, or nil when nothing has been read for it —
    /// a genuine first launch, which resolves every module available, with no
    /// prerequisite cascade (the rules arrive with the grants, REQ-012).
    private var entitlement: AmityUIKitModuleEntitlement?

    private init() {
        loadConfig()
    }

    private func loadConfig() {
        let configFilePath = configFilePath ?? AmityUIKit4Manager.bundle.path(forResource: "AmityUIKitConfig", ofType: "json")
        let localConfig = configFilePath.flatMap { loadConfigFile(filePath: $0) } ?? [:]
        let wrappedConfig = RemoteConfig.shared.mergeWithLocalConfig(localConfig)

        config = (wrappedConfig["config"] as? [String: Any]) ?? localConfig
        excludedList = Set(config["excludes"] as? [String] ?? [])
        // A `features` block in the file is not read. It was the customer's own
        // module switch, withdrawn (module-availability §1, REQ-010): the plan
        // is the only source that withholds a module.
        featureFlag = try? AmityFeatureFlag.decode(from: config["feature_flags"] as? [String: Any] ?? [:])
        rebuildModuleSnapshot()
    }

#if DEBUG
    /// Test seam. `config` is private(set) and only loadConfig() fills it, which
    /// needs a bundle round-trip; the module-flag tests need a config in hand.
    /// Debug-only, so it is not API a consumer can reach.
    func setConfigForTesting(_ newConfig: [String: Any]) {
        config = newConfig
        excludedList = Set(newConfig["excludes"] as? [String] ?? [])
        rebuildModuleSnapshot()
    }
#endif

    /// Whether a UIKit module is available: the network's plan grants it, and
    /// its catalog prerequisites hold.
    ///
    /// Answered from the snapshot. Synchronous and free of I/O (REQ-019): this
    /// is read while views are being built, and it never reads Core Data —
    /// the store is read at setup and on `didUpdateNotification`, nowhere else.
    ///
    /// Distinct from `feature_flags`, which answers who may do something inside
    /// a feature that exists; this answers whether the feature exists at all.
    func isFeatureEnabled(_ feature: AmityUIKitFeature) -> Bool {
        isFeatureEnabled(feature.rawValue)
    }

    func isFeatureEnabled(_ key: String) -> Bool {
        let (held, inputs) = heldAnswer(for: key)
        if let held { return held.isAvailable }
#if DEBUG
        snapshotLock.lock(); Self.walksForTesting += 1; snapshotLock.unlock()
#endif
        // A key with no entry is a module this build's enum does not name — an
        // owner map pointing at one the catalog gained server-side. Resolve it
        // directly rather than defaulting: the walk is pure and touches no I/O.
        return verdict(key, inputs, visiting: []).isAvailable
    }

    /// What a verdict is computed from, read together so a fallback walk
    /// resolves against the same grants the snapshot it missed was built from.
    private struct Inputs {
        let entitlement: AmityUIKitModuleEntitlement?
    }

    /// The memo and the inputs it was built from, read together.
    private func heldAnswer(
        for key: String
    ) -> (AmityUIKitModuleAvailability?, Inputs) {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return (moduleSnapshot[key], inputsLocked)
    }

    /// Call with `snapshotLock` held.
    private var inputsLocked: Inputs {
        Inputs(entitlement: entitlement)
    }

    /// The availability of every module this UIKit gates, with its reason.
    ///
    /// `kind: setting` catalog entries — Console and Dashboard capabilities —
    /// are absent by construction: none of them is an `AmityUIKitFeature`,
    /// because none of them has a UIKit surface to withhold.
    func moduleAvailabilities() -> [AmityUIKitModuleAvailability] {
        snapshotLock.lock()
        let held = moduleSnapshot
        snapshotLock.unlock()
        return AmityUIKitFeature.allCases.map { feature in
            held[feature.rawValue] ?? .available(feature: feature)
        }
    }

    func moduleAvailability(_ feature: AmityUIKitFeature) -> AmityUIKitModuleAvailability {
        let (held, inputs) = heldAnswer(for: feature.rawValue)
        if let held { return held }
#if DEBUG
        snapshotLock.lock(); Self.walksForTesting += 1; snapshotLock.unlock()
#endif
        return verdict(feature.rawValue, inputs, visiting: [])
            .availability(of: feature)
    }

    // MARK: Reading the network's module settings (REQ-003a)

    /// The observer for `AmityModuleSettings.didUpdateNotification`, registered
    /// once for the process. The notification carries no client — `object` is
    /// nil — so one registration serves every client a re-setup or a network
    /// switch brings, and setting up again must not add a second one.
    private var moduleSettingsObserver: NSObjectProtocol?
    private let observerLock = NSLock()

    /// Setup's read. Every setup path calls this once the client exists.
    ///
    /// Registers for the SDK's change signal *before* reading, so a write that
    /// lands between the two is not missed (REQ-003a), then reads once and
    /// replaces whatever was held — nil included: a re-setup on another
    /// network, or after a log-out, has no row yet, and holding the previous
    /// network's answer would be wrong for the whole launch. A nil read is not
    /// the launch's answer either: it is fail-open (REQ-002) until the SDK's
    /// fetch writes the row and posts the notification.
    ///
    /// The UIKit reads; it does not fetch.
    func refreshModuleEntitlements() {
        observeModuleSettingsIfNeeded()
        setEntitlement(Self.readModuleEntitlements())
        announceModuleChange()
    }

    private func observeModuleSettingsIfNeeded() {
        observerLock.lock()
        defer { observerLock.unlock() }
        guard moduleSettingsObserver == nil else { return }
        moduleSettingsObserver = NotificationCenter.default.addObserver(
            forName: AmityModuleSettings.didUpdateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.moduleSettingsDidUpdate()
        }
    }

    /// The SDK wrote a new row. Read it and rebuild — the iOS equivalent of
    /// Android's `Flowable` emission: reassign the settings, rebuild the
    /// snapshot, fire the change callbacks. Nothing memoises exclusion on iOS
    /// (`isExcluded` asks the snapshot), so there is no `excludedCache` to clear.
    ///
    /// A read that yields nothing keeps the answer already held: the SDK posts
    /// only after a successful write, so an empty read here is a failure, and
    /// a failed refresh leaves the snapshot as it was (§6.2, TC-uikit-mavail-014).
    private func moduleSettingsDidUpdate() {
        guard let read = Self.readModuleEntitlements() else { return }
        setEntitlement(read)
        announceModuleChange()
    }

    /// Views are told, because an entitlement can change what is on screen.
    private func announceModuleChange() {
        NotificationCenter.default.post(name: .configDidUpdate, object: nil)
    }

#if DEBUG
    /// Replaces the SDK read so the "arrives after setup" path — the one that
    /// broke on Android — can be exercised without a network. Count its calls
    /// to prove a gate query reads nothing.
    static var moduleEntitlementReaderForTesting: (() -> AmityUIKitModuleEntitlement?)?

    /// Whether setup has registered for the SDK's change signal.
    var isObservingModuleSettingsForTesting: Bool {
        observerLock.lock()
        defer { observerLock.unlock() }
        return moduleSettingsObserver != nil
    }

    /// Dependency walks taken outside a rebuild — a gate query that missed the
    /// snapshot — plus every rebuild. A read served from the snapshot adds
    /// nothing, which is what TC-uikit-mavail-015 counts.
    static var walksForTesting = 0

    /// Whether the held snapshot is the one its held inputs produce.
    /// A rebuild that landed out of order leaves the two disagreeing.
    func snapshotMatchesEntitlementForTesting() -> Bool {
        rebuildLock.lock()
        defer { rebuildLock.unlock() }
        snapshotLock.lock()
        let (inputs, held) = (inputsLocked, moduleSnapshot)
        snapshotLock.unlock()
        return AmityUIKitFeature.allCases.allSatisfy {
            held[$0.rawValue] == verdict($0.rawValue, inputs, visiting: [])
                .availability(of: $0)
        }
    }
#endif

    /// The row the SDK persisted on its last successful fetch of
    /// `GET /api/v3/network-settings/modules`. Synchronous and optional, like
    /// `getSocialSettings()`: nil is the genuine first-launch path — no row yet.
    /// Called from setup and from the notification, never from a gate query.
    private static func readModuleEntitlements() -> AmityUIKitModuleEntitlement? {
#if DEBUG
        if let reader = moduleEntitlementReaderForTesting { return reader() }
#endif
        guard let settings = AmityUIKitManagerInternal.shared.clientIfSetUp?.getModuleSettings() else { return nil }
        return AmityUIKitModuleEntitlement(
            enforcement: settings.enforcement,
            granted: settings.modules,
            catalog: settings.catalog.mapValues { (kind: $0.kind, requires: $0.requires) })
    }

#if DEBUG
    /// Test seam, beside `setConfigForTesting`. An enforcing network is
    /// reachable in a unit test only from here.
    func setEntitlementForTesting(_ newEntitlement: AmityUIKitModuleEntitlement?) {
        setEntitlement(newEntitlement)
    }
#endif

    private func setEntitlement(_ newEntitlement: AmityUIKitModuleEntitlement?) {
        rebuildModuleSnapshot(replacingEntitlementWith: .some(newEntitlement))
    }

    /// Build the snapshot and swap it in with the inputs it was built from.
    /// `nil` keeps the entitlement held; `.some(x)` replaces it — `x` itself
    /// may be nil, which is a new client with no row yet.
    private func rebuildModuleSnapshot(
        replacingEntitlementWith replacement: AmityUIKitModuleEntitlement?? = nil
    ) {
        rebuildLock.lock()
        defer { rebuildLock.unlock() }
#if DEBUG
        snapshotLock.lock(); Self.walksForTesting += 1; snapshotLock.unlock()
#endif
        snapshotLock.lock()
        let held = inputsLocked
        snapshotLock.unlock()
        let inputs: Inputs
        if let replacement {
            inputs = Inputs(entitlement: replacement)
        } else {
            inputs = held
        }

        var built: [String: AmityUIKitModuleAvailability] = [:]
        for feature in AmityUIKitFeature.allCases {
            built[feature.rawValue] = verdict(feature.rawValue, inputs, visiting: [])
                .availability(of: feature)
        }
        snapshotLock.lock()
        self.entitlement = inputs.entitlement
        moduleSnapshot = built
        snapshotLock.unlock()
    }

    /// The held entitlement, read under the lock it is written under.
    private var heldEntitlement: AmityUIKitModuleEntitlement? {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return entitlement
    }

    /// The plan withholds a module. Nothing local can withhold or grant one
    /// (§3.1): the network's module settings are the only input.
    ///
    /// The grant is read before the prerequisite chain, so a revoked module is
    /// reported as `notGranted` rather than through whichever of its
    /// prerequisites happened to fall with it (REQ-010). One walk, over the
    /// resolved answer: the entitlement contributes the leaf — is this module
    /// granted, given the mode — and the chain is walked here (REQ-011).
    private func verdict(
        _ key: String,
        _ inputs: Inputs,
        visiting: Set<String>
    ) -> Verdict {
        // A cycle reads as unavailable rather than recursing: a module nobody
        // can reason about must not ship switched on. It still names the whole
        // requirement — an empty reason reads as "no prerequisites", which is
        // the opposite of what a cycle means.
        if visiting.contains(key) {
            let requirement = requirements(for: key, entitlement: inputs.entitlement)
            return .prerequisiteUnavailable(unsatisfied: requirement.all + requirement.any)
        }
        if let entitlement = inputs.entitlement, !entitlement.isGranted(key) { return .notGranted }

        let requirement = requirements(for: key, entitlement: inputs.entitlement)
        let seen = visiting.union([key])
        let unmetAll = requirement.all.filter {
            !verdict($0, inputs, visiting: seen).isAvailable
        }
        if !unmetAll.isEmpty {
            return .prerequisiteUnavailable(unsatisfied: unmetAll)
        }
        if !requirement.any.isEmpty,
           !requirement.any.contains(where: {
               verdict($0, inputs, visiting: seen).isAvailable
           }) {
            // The whole list: any one of them would have done.
            return .prerequisiteUnavailable(unsatisfied: requirement.any)
        }
        return .available
    }

    /// The bundle rules, from the one place they come from: the catalog.
    ///
    /// They arrive with the grants, in the same `getModuleSettings()` row, as
    /// `catalog[key].requires`. The generated `features.json` graph was a second
    /// answer to the same question and the two diverged — on 2026-09-10 the
    /// catalog required Post for Live and Poll while the graph had both
    /// standalone — so the gate no longer reads it at all.
    ///
    /// With no row there are no rules and nothing cascades (REQ-012).
    /// Inventing the rules client-side would withhold a feature on the
    /// client's own authority. A key the catalog does not carry has no rules
    /// either.
    ///
    /// The catalog's `requires` means **any one**, where `features.json` spells
    /// that `requiresAny` and keeps `requires` for all-of. Mapping the two by
    /// field name would invert five rules — comment, reaction, product, ads and
    /// discovery. So `all` is always empty here; it stays in the shape because
    /// the walk and the public requirement both still carry it.
    private func requirements(
        for key: String,
        entitlement: AmityUIKitModuleEntitlement?
    ) -> (all: [String], any: [String]) {
        guard let entry = entitlement?.catalog[key] else { return ([], []) }
        return (all: [], any: entry.requires)
    }

    /// Why a module resolved the way it did, in keys rather than features: a
    /// prerequisite can be a catalog key this build's enum does not name.
    enum Verdict {
        case available
        case notGranted
        case prerequisiteUnavailable(unsatisfied: [String])

        var isAvailable: Bool {
            if case .available = self { return true }
            return false
        }

        func availability(of feature: AmityUIKitFeature) -> AmityUIKitModuleAvailability {
            switch self {
            case .available:
                return .available(feature: feature)
            case .notGranted:
                return .notGranted(feature: feature)
            case .prerequisiteUnavailable(let unsatisfied):
                // Raw keys, unknown ones included (REQ-023). Filtering down to
                // the enum dropped a prerequisite this build predates — the one
                // a customer would be missing — and left the list empty.
                return .prerequisiteUnavailable(feature: feature, unsatisfied: unsatisfied)
            }
        }
    }

    /// The bundle traversal over any set of flags a caller supplies.
    ///
    /// For a host that renders its own switches: pure, knows nothing of
    /// grants, but follows the gate's prerequisite rules — the catalog's, and
    /// none without a row (REQ-020) — so a host's switches and
    /// `isModuleAvailable` give the same answer for the same flags.
    func resolveFeature(_ key: String, flags: [String: Bool]) -> Bool {
        let entitlement = heldEntitlement
        return resolveFeature(key, flagOn: { flags[$0] ?? true },
                              entitlement: entitlement, visiting: [])
    }

    private func resolveFeature(
        _ key: String,
        flagOn: (String) -> Bool,
        entitlement: AmityUIKitModuleEntitlement?,
        visiting: Set<String>
    ) -> Bool {
        if visiting.contains(key) { return false }
        guard flagOn(key) else { return false }
        let requirement = requirements(for: key, entitlement: entitlement)

        let seen = visiting.union([key])
        if requirement.all.contains(where: {
            !resolveFeature($0, flagOn: flagOn, entitlement: entitlement, visiting: seen)
        }) {
            return false
        }
        if !requirement.any.isEmpty,
           !requirement.any.contains(where: {
               resolveFeature($0, flagOn: flagOn, entitlement: entitlement, visiting: seen)
           }) {
            return false
        }
        return true
    }

    /// The requirement the gate itself used — the catalog's, or none without a row.
    func moduleRequirement(_ key: String) -> (all: [String], any: [String]) {
        requirements(for: key, entitlement: heldEntitlement)
    }

    func setConfigFile(_ filePath: String) {
        configFilePath = filePath
        refreshConfig()
    }

    func refreshConfig() {
        loadConfig()
        NotificationCenter.default.post(name: .configDidUpdate, object: nil)
    }
    
    // MARK: Public Functions
    
    /// A configId is always "pageId/componentId/elementId", and every page,
    /// component and element in the UIKit resolves through here. So a module
    /// the network withholds excludes the pages it owns — and with them
    /// everything nested under those pages — by the route the customer's own
    /// `excludes` list already takes. No per-page guard to add, and none to
    /// forget when the next page lands.
    func isExcluded(configId: String) -> Bool {
        let id = configId.components(separatedBy: "/")
        guard id.count == 3 else { return false }

        // All three segments. Reading only the page emptied nothing a component
        // owned, and reading only page and component emptied a module's pages
        // while leaving every door into them standing — the Clips tab, the
        // Create Story button and the follow button are elements, and they sit
        // on pages owned by other modules.
        let owners = [amityPageModule[id[0]], amityComponentModule[id[1]],
                      amityElementModule[id[2]]].compactMap { $0 }
        // Clip is not a module: every clip id is owned by `post` in these
        // maps, so clip surfaces follow Post and nothing else (§6.2).
        if owners.contains(where: { !isFeatureEnabled($0) }) {
            return true
        }

        return excludedList.contains(configId) ||
        excludedList.contains("*/\(id[1])/*") ||
        excludedList.contains("*/\(id[1])/\(id[2])") ||
        excludedList.contains("*/*/\(id[2])")
    }
    
    func getTheme(configId: String? = nil) -> AmityThemeColor {
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let configStyle = AmityThemeStyle(rawValue: config["preferred_theme"] as? String ?? "light") ?? .light
        
        let style: AmityThemeStyle = configStyle == .system ? (systemStyle == .light ? .light : .dark) : (configStyle == .light ? .light : .dark)
        
        let fallbackTheme = style == .light ? lightTheme : darkTheme
        let globalTheme = getGlobalTheme(style) ?? fallbackTheme
        
        guard let configId else {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        let customizationConfig = config["customizations"] as? [String: Any]
        let id = configId.components(separatedBy: "/")
        guard id.count == 3 else {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        let pageComponentTheme = customizationConfig?[keyPath: "\(id[0])/\(id[1])/*.theme.\(style.rawValue)"] as? [String: Any]
        let pageTheme = customizationConfig?[keyPath: "\(id[0])/*/*.theme.\(style.rawValue)"] as? [String: Any]
        let componentTheme = customizationConfig?[keyPath: "*/\(id[1])/*.theme.\(style.rawValue)"] as? [String: Any]
        
        do {
            if let pageComponentTheme {
                return try getThemeColor(theme: pageComponentTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
            
            if let componentTheme {
                return try getThemeColor(theme: componentTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
            
            if let pageTheme {
                return try getThemeColor(theme: pageTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
        } catch {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
    }
    
    
    func getConfig(configId: String) -> [String: Any] {
        let id = configId.components(separatedBy: "/")
        
        guard id.count == 3, let customizationConfig = config["customizations"] as? [String: Any] else {
            return [:]
        }
        
        // If its an exact match, return it
        if let config = customizationConfig[configId] as? [String: Any] {
            return config
        }
        
        // #1. We find obvious variation
        let variations = [
            "*/\(id[1])/\(id[2])", // */<component>/<element>
            "*/\(id[1])/*", // */<component>/* i.e any component
            "*/*/\(id[2])" // */*/<element> i.e any element
        ]
        
        for variation in variations {
            if let config = customizationConfig[variation] as? [String: Any] {
                return config
            }
        }
        
        return [:]
    }
    
    // MARK: Private Functions
    
    private func getGlobalTheme(_ style: AmityThemeStyle) -> AmityTheme? {
        let globalTheme = config[keyPath: "theme.\(style.rawValue)"] as? [String: Any]
        do {
            return try globalTheme?.decode(AmityTheme.self)
        } catch {
            return nil
        }
    }
    
    
    private func getThemeColor(theme: AmityTheme, fallbackTheme: AmityTheme) -> AmityThemeColor {
        return AmityThemeColor(primaryColor: theme.primaryColor ?? fallbackTheme.primaryColor!,
                               primaryColorShade1: theme.primaryColorShade1 ?? fallbackTheme.primaryColorShade1!,
                               primaryColorShade2: theme.primaryColorShade2 ?? fallbackTheme.primaryColorShade2!,
                               primaryColorShade3: theme.primaryColorShade3 ?? fallbackTheme.primaryColorShade3!,
                               primaryColorShade4: theme.primaryColorShade4 ?? fallbackTheme.primaryColorShade4!,
                               secondaryColor: theme.secondaryColor ?? fallbackTheme.secondaryColor!,
                               secondaryColorShade1: theme.secondaryColorShade1 ?? fallbackTheme.secondaryColorShade1!,
                               secondaryColorShade2: theme.secondaryColorShade2 ?? fallbackTheme.secondaryColorShade2!,
                               secondaryColorShade3: theme.secondaryColorShade3 ?? fallbackTheme.secondaryColorShade3!,
                               secondaryColorShade4: theme.secondaryColorShade4 ?? fallbackTheme.secondaryColorShade4!,
                               neutralGreyShade1Color: theme.neutralGreyShade1Color ?? fallbackTheme.neutralGreyShade1Color!,
                               neutralGreyShade2Color: theme.neutralGreyShade2Color ?? fallbackTheme.neutralGreyShade2Color!,
                               neutralGreyShade3Color: theme.neutralGreyShade3Color ?? fallbackTheme.neutralGreyShade3Color!,
                               neutralGreyShade4Color: theme.neutralGreyShade4Color ?? fallbackTheme.neutralGreyShade4Color!,
                               neutralGreyShade5Color: theme.neutralGreyShade5Color ?? fallbackTheme.neutralGreyShade5Color!,
                               neutralGreyShade6Color: theme.neutralGreyShade6Color ?? fallbackTheme.neutralGreyShade6Color!,
                               baseColor: theme.baseColor ?? fallbackTheme.baseColor!,
                               baseColorShade1: theme.baseColorShade1 ?? fallbackTheme.baseColorShade1!,
                               baseColorShade2: theme.baseColorShade2 ?? fallbackTheme.baseColorShade2!,
                               baseColorShade3: theme.baseColorShade3 ?? fallbackTheme.baseColorShade3!,
                               baseColorShade4: theme.baseColorShade4 ?? fallbackTheme.baseColorShade4!,
                               alertColor: theme.alertColor ?? fallbackTheme.alertColor!,
                               alertColorShade1: theme.alertColorShade1 ?? fallbackTheme.alertColorShade1!,
                               backgroundColor: theme.backgroundColor ?? fallbackTheme.backgroundColor!,
                               baseInverseColor: theme.baseInverseColor ?? fallbackTheme.baseInverseColor!,
                               backgroundShade1Color: theme.backgroundShade1Color ?? fallbackTheme.backgroundShade1Color!,
                               highlightColor: theme.highlightColor ?? fallbackTheme.highlightColor!,
                               destructiveShade1Color: theme.destructiveShade1Color ?? fallbackTheme.destructiveShade1Color!,
                               destructiveShade2Color: theme.destructiveShade2Color ?? fallbackTheme.destructiveShade2Color!,
                               destructiveShade3Color: theme.destructiveShade3Color ?? fallbackTheme.destructiveShade3Color!,
                               destructiveShade4Color: theme.destructiveShade4Color ?? fallbackTheme.destructiveShade4Color!,
                               destructiveShade5Color: theme.destructiveShade5Color ?? fallbackTheme.destructiveShade5Color!,
                               transparentBlackShade1Color: theme.transparentBlackShade1Color ?? fallbackTheme.transparentBlackShade1Color!,
                               transparentBlackShade2Color: theme.transparentBlackShade2Color ?? fallbackTheme.transparentBlackShade2Color!,
                               transparentBlackShade3Color: theme.transparentBlackShade3Color ?? fallbackTheme.transparentBlackShade3Color!,
                               transparentBlackShade4Color: theme.transparentBlackShade4Color ?? fallbackTheme.transparentBlackShade4Color!,
                               transparentBlackShade5Color: theme.transparentBlackShade5Color ?? fallbackTheme.transparentBlackShade5Color!,
                               transparentWhiteShade1Color: theme.transparentWhiteShade1Color ?? fallbackTheme.transparentWhiteShade1Color!,
                               transparentWhiteShade2Color: theme.transparentWhiteShade2Color ?? fallbackTheme.transparentWhiteShade2Color!,
                               transparentWhiteShade3Color: theme.transparentWhiteShade3Color ?? fallbackTheme.transparentWhiteShade3Color!,
                               transparentWhiteShade4Color: theme.transparentWhiteShade4Color ?? fallbackTheme.transparentWhiteShade4Color!,
                               transparentWhiteShade5Color: theme.transparentWhiteShade5Color ?? fallbackTheme.transparentWhiteShade5Color!,
                               transparentWhiteShade6Color: theme.transparentWhiteShade6Color ?? fallbackTheme.transparentWhiteShade6Color!,
                               transparentWhiteShade7Color: theme.transparentWhiteShade7Color ?? fallbackTheme.transparentWhiteShade7Color!,
                               transparentRedShade1Color: theme.transparentRedShade1Color ?? fallbackTheme.transparentRedShade1Color!
        )
    }
    
    private func loadConfigFile(filePath: String) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
            return try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any]
        } catch {
            Log.warn("Error loading config file at path: \(filePath), error: \(error)")
            return nil
        }
    }
    
    public func getCurrentThemeStyle() -> AmityThemeStyle {
        let configStyle = AmityThemeStyle(rawValue: config["preferred_theme"] as? String ?? "light") ?? .light
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let style: AmityThemeStyle = configStyle == .system ? (systemStyle == .light ? .light : .dark) : (configStyle == .light ? .light : .dark)
        return style
    }

    // MARK: - Chat feature flag accessors

    func enabledChannelTypes() -> [AmityChatChannelTypeFlag] {
        let raw = featureFlag?.chat.enabledChannelTypes ?? []
        let known = raw.compactMap { AmityChatChannelTypeFlag(rawValue: $0) }
        return known.isEmpty ? [.conversation, .community] : known
    }

    func isChatUserActionEnabled(_ name: String) -> Bool {
        guard let actions = featureFlag?.chat.conversationChatUserActions else {
            return true
        }
        if let entry = actions.first(where: { $0.name == name }) {
            return entry.enabled
        }
        return false
    }

    func hasAnyEnabledChatUserAction() -> Bool {
        guard let actions = featureFlag?.chat.conversationChatUserActions else {
            return true
        }
        let supported: Set<String> = ["mute", "report", "block"]
        return actions.contains(where: { supported.contains($0.name) && $0.enabled })
    }
}

struct AmityFeatureFlag: Codable {
    let post: PostFeatures
    let chat: ChatFeatures

    enum CodingKeys: String, CodingKey {
        case post
        case chat
    }

    init(post: PostFeatures = PostFeatures(),
         chat: ChatFeatures = ChatFeatures()) {
        self.post = post
        self.chat = chat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.post = try container.decodeIfPresent(PostFeatures.self, forKey: .post) ?? PostFeatures()
        self.chat = try container.decodeIfPresent(ChatFeatures.self, forKey: .chat) ?? ChatFeatures()
    }

    static func decode(from dictionary: [String: Any]) throws -> AmityFeatureFlag {
        // Convert dictionary to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])

        // Decode using JSONDecoder
        let decoder = JSONDecoder()
        return try decoder.decode(AmityFeatureFlag.self, from: jsonData)
    }
}

struct PostFeatures: Codable {
    let clip: ClipFeatures

    enum CodingKeys: String, CodingKey {
        case clip
    }

    init(clip: ClipFeatures = ClipFeatures()) {
        self.clip = clip
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clip = try container.decodeIfPresent(ClipFeatures.self, forKey: .clip) ?? ClipFeatures()
    }
}

struct ClipFeatures: Codable {
    let canCreate: AccessLevel
    let canViewTab: AccessLevel
    
    enum CodingKeys: String, CodingKey {
        case canCreate = "can_create"
        case canViewTab = "can_view_tab"
    }
    
    // Initialize with default values
    init(canCreate: AccessLevel = .signedInUserOnly, canViewTab: AccessLevel = .signedInUserOnly) {
        self.canCreate = canCreate
        self.canViewTab = canViewTab
    }
    
    // Custom decoder to handle default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.canCreate = try container.decodeIfPresent(AccessLevel.self, forKey: .canCreate) ?? .signedInUserOnly
        self.canViewTab = try container.decodeIfPresent(AccessLevel.self, forKey: .canViewTab) ?? .signedInUserOnly
    }
}

enum AccessLevel: String, Codable, CaseIterable {
    case all = "all"
    case signedInUserOnly = "signed_in_user_only"
    case none = "none"
}

// MARK: - Chat features

struct ChatFeatures: Codable {
    let enabledChannelTypes: [String]
    let conversationChatUserActions: [AmityChatUserActionFlag]?

    enum CodingKeys: String, CodingKey {
        case enabledChannelTypes = "enabled_channel_types"
        case conversationChatUserActions = "conversation_chat_user_actions"
    }

    init(enabledChannelTypes: [String] = [],
         conversationChatUserActions: [AmityChatUserActionFlag]? = nil) {
        self.enabledChannelTypes = enabledChannelTypes
        self.conversationChatUserActions = conversationChatUserActions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.enabledChannelTypes =
            try container.decodeIfPresent([String].self, forKey: .enabledChannelTypes) ?? []
        self.conversationChatUserActions =
            try container.decodeIfPresent([AmityChatUserActionFlag].self, forKey: .conversationChatUserActions)
    }
}

struct AmityChatUserActionFlag: Codable {
    let name: String
    let enabled: Bool
}

enum AmityChatChannelTypeFlag: String {
    case conversation
    case community
}

/// The post types a feed is allowed to ask the backend for.
///
/// A feed that sends no `dataTypes` gets everything the network holds, so a
/// build with clip switched off still receives clip posts, renders them and
/// lets someone tap into a page that module was supposed to remove. Excluding
/// the type at the query is the only place that cannot be forgotten by a view.
///
/// Computed on each read rather than stored: the network's module settings
/// arrive after this file is first touched.
///
/// The Android UIKit carries the same list as
/// `AmitySocialBehaviorHelper.supportedPostTypes`; the two are meant to agree.
enum AmityUIKitSupportedPostTypes {

    static var current: [AmityPostDataType] {
        let on: (AmityUIKitFeature) -> Bool = {
            AmityUIKitConfigController.shared.isFeatureEnabled($0)
        }
        var types: [AmityPostDataType] = [.text, .image, .video, .file, .audio]
        if on(.poll) { types.append(.poll) }
        if on(.live) { types.append(.liveStream) }
        // Clip is part of Post, not a module of its own (§6.2).
        if on(.post) { types.append(.clip) }
        if on(.live) { types.append(.room) }
        if on(.events) { types.append(.event) }
        return types
    }

    /// The same list as the string set `getGlobalFeed(dataTypes:)` takes.
    static var currentRawValues: Set<String> {
        Set(current.map { $0.rawValue })
    }

    /// Whether this post's module is switched on.
    ///
    /// Asking at the query is not always possible — `/api/v4/me/global-feeds`
    /// takes a media-type filter, and the pinned endpoints take none — so the
    /// feed view models ask here instead, before a post becomes a list item.
    /// Refusing later, at the element, leaves the header and the action row
    /// around a body nothing draws: an empty post.
    ///
    /// Read from `structureType` first and the children second, for the reason
    /// `AmityPostModel` spells out: in a live collection `childrenPosts` can be
    /// empty on the first emission and resolve later, while the parent carries
    /// its structure type immediately.
    ///
    /// The Android UIKit carries the same rule as `AmityPost.owningFeature()`.
    static func allows(_ post: AmityPost) -> Bool {
        let on: (AmityUIKitFeature) -> Bool = {
            AmityUIKitConfigController.shared.isFeatureEnabled($0)
        }
        var types = Set(post.childrenPosts.map { $0.dataType })
        types.insert(post.dataType)
        types.insert(post.structureType)

        if types.contains("liveStream") || types.contains("room") { return on(.live) }
        if types.contains("poll") { return on(.poll) }
        if types.contains("clip") { return on(.post) }
        if types.contains("event") { return on(.events) }
        return true
    }
}
