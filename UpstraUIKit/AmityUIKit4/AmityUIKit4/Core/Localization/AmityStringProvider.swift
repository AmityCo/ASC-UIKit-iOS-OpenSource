//
//  AmityStringProvider.swift
//  AmityUIKit4
//

import Foundation
import Combine

/// Provides localized strings through a 5-level resolution chain:
/// 1. Config text (remote override)
/// 2. Programmatic override
/// 3. Locale bundle
/// 4. Library default (.strings file)
/// 5. Key name fallback
@MainActor
public class AmityStringProvider: ObservableObject {

    @Published private(set) var version: Int = 0

    private var overrides: [String: String] = [:]
    private var localeIdentifier: String?
    private var localeBundle: [String: String]?
    private var localeBundleCache: [String: [String: String]] = [:]

    private let stringsTableName: String
    private let bundle: Bundle

    // Injectable library defaults for testing (bypasses NSLocalizedString)
    private let injectedDefaults: [String: String]?

    /// Production initializer — reads library defaults from .strings file
    public init(stringsTableName: String = "AmityLocalizable", bundle: Bundle? = nil) {
        self.stringsTableName = stringsTableName
        self.bundle = bundle ?? AmityUIKit4Manager.bundle
        self.injectedDefaults = nil
    }

    /// Test initializer — uses provided dictionary as library defaults
    init(libraryDefaults: [String: String]) {
        self.stringsTableName = ""
        self.bundle = Bundle.main
        self.injectedDefaults = libraryDefaults
    }

    // MARK: - Resolution

    /// Resolve a localized string through the 5-level priority chain.
    /// Pass configText from AmityViewConfigController.getText(elementId:) for config-aware resolution.
    /// Format args are intentionally NOT applied when key fallback is returned (raw key may contain
    /// literal `%@` which would crash `String(format:)` with wrong arg count).
    public func resolve(key: String, configText: String? = nil, args: CVarArg...) -> String {
        let raw = resolveRaw(key: key, configText: configText)
        if args.isEmpty { return raw }
        if raw == key { return raw }
        return String(format: raw, arguments: args)
    }

    /// Internal resolution without format args
    func resolveRaw(key: String, configText: String? = nil) -> String {
        // Level 1: Config text (empty string = absent)
        if let configText = configText, !configText.isEmpty {
            return configText
        }

        // Level 2: Programmatic override (empty string = valid)
        if let override = overrides[key] {
            return override
        }

        // Level 3: Locale bundle (empty string = valid)
        if localeIdentifier != nil, let value = localeBundle?[key] {
            return value
        }

        // Level 4: Library default
        if let value = lookupLibraryDefault(key: key) {
            return value
        }

        // Level 5: Key name fallback
        return key
    }

    private func lookupLibraryDefault(key: String) -> String? {
        if let injectedDefaults = injectedDefaults {
            return injectedDefaults[key]
        }

        // Check consumer app bundle (Bundle.main) first, then framework bundle.
        // This allows consumer apps to provide their own translations via lproj
        // directories without modifying the framework.
        let bundles = bundle == Bundle.main ? [bundle] : [Bundle.main, bundle]
        for lang in Locale.preferredLanguages {
            let code = String(lang.prefix(2))
            if code == "en" { break }
            for b in bundles {
                if let lprojPath = b.path(forResource: code, ofType: "lproj"),
                   let lprojBundle = Bundle(path: lprojPath) {
                    let v = lprojBundle.localizedString(forKey: key, value: "", table: stringsTableName)
                    if !v.isEmpty && v != key { return v }
                }
            }
        }

        for b in bundles {
            let value = NSLocalizedString(key, tableName: stringsTableName, bundle: b, value: "", comment: "")
            if !value.isEmpty && value != key { return value }
        }
        return nil
    }

    // MARK: - Developer API

    /// Register a locale bundle. Replaces the entire bundle for this locale.
    /// Activates the locale immediately.
    public func setLocale(_ identifier: String, bundle: [String: String]) {
        localeBundleCache[identifier] = bundle
        localeIdentifier = identifier
        localeBundle = bundle
        version += 1
    }

    /// Re-activate a previously cached locale bundle.
    public func activateLocale(_ identifier: String) {
        guard let cached = localeBundleCache[identifier] else { return }
        localeIdentifier = identifier
        localeBundle = cached
        version += 1
    }

    /// Deactivate the current locale. Does NOT delete the cached bundle.
    public func deactivateLocale() {
        localeIdentifier = nil
        localeBundle = nil
        version += 1
    }

    /// Set programmatic overrides. Merges with existing overrides.
    public func setOverrides(_ newOverrides: [String: String]) {
        overrides.merge(newOverrides) { _, new in new }
        version += 1
    }

    /// Clear all programmatic overrides.
    public func clearOverrides() {
        overrides.removeAll()
        version += 1
    }

    // MARK: - Reaction Localization

    /// Resolve a reaction display name through the localization chain.
    /// Falls back to title-casing the raw name if no translation is found.
    public func resolveReactionDisplayName(_ reactionName: String) -> String {
        let key = "amity_social_reaction_\(reactionName)"
        let resolved = resolveRaw(key: key)
        if resolved == key {
            guard !reactionName.isEmpty else { return reactionName }
            return reactionName.prefix(1).uppercased() + reactionName.dropFirst()
        }
        return resolved
    }

    public func resolveChatReactionDisplayName(_ reactionName: String) -> String {
        let key = "amity_chat_reaction_label_\(reactionName)"
        let resolved = resolveRaw(key: key)
        if resolved == key {
            guard !reactionName.isEmpty else { return reactionName }
            return reactionName.prefix(1).uppercased() + reactionName.dropFirst()
        }
        return resolved
    }
}

// MARK: - Module Singletons

extension AmityStringProvider {
    public static let social = AmityStringProvider()
    public static let common = AmityStringProvider()
    public static let chat = AmityStringProvider()
}
