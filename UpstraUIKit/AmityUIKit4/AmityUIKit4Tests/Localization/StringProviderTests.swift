//
//  StringProviderTests.swift
//  AmityUIKit4Tests
//

import XCTest
@testable import AmityUIKit4

@MainActor
final class StringProviderTests: XCTestCase {

    // MARK: - 7.1 Resolution Priority Order

    func testOverrideWinsOverLocale() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        provider.setOverrides(["key": "override_value"])
        XCTAssertEqual(provider.resolve(key: "key"), "override_value")
    }

    func testLocaleWinsOverLibraryDefault() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default_value"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        XCTAssertEqual(provider.resolve(key: "key"), "locale_value")
    }

    func testLibraryDefaultUsedWhenNothingElseSet() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default_value"])
        XCTAssertEqual(provider.resolve(key: "key"), "default_value")
    }

    func testKeyFallbackWhenNothingFound() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        XCTAssertEqual(provider.resolve(key: "unknown_key"), "unknown_key")
    }

    func testConfigTextWinsOverEverything() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        provider.setOverrides(["key": "override_value"])
        XCTAssertEqual(provider.resolve(key: "key", configText: "config_value"), "config_value")
    }

    // MARK: - 7.2 Override Behavior

    func testMultipleSetOverridesMerge() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        provider.setOverrides(["k1": "A"])
        provider.setOverrides(["k2": "B"])
        XCTAssertEqual(provider.resolve(key: "k1"), "A")
        XCTAssertEqual(provider.resolve(key: "k2"), "B")
    }

    func testLaterOverrideValueWins() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        provider.setOverrides(["key": "A"])
        provider.setOverrides(["key": "B"])
        XCTAssertEqual(provider.resolve(key: "key"), "B")
    }

    func testEmptyStringOverrideIsValid() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setOverrides(["key": ""])
        XCTAssertEqual(provider.resolve(key: "key"), "")
    }

    func testClearOverridesFallsThrough() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        provider.setOverrides(["key": "override_value"])
        provider.clearOverrides()
        XCTAssertEqual(provider.resolve(key: "key"), "locale_value")
    }

    // MARK: - 7.3 Locale Bundle Behavior

    func testSetLocaleReplacesEntireBundle() {
        let provider = AmityStringProvider(libraryDefaults: ["k2": "default_k2"])
        provider.setLocale("ja", bundle: ["k1": "A", "k2": "B"])
        provider.setLocale("ja", bundle: ["k1": "C"])
        XCTAssertEqual(provider.resolve(key: "k1"), "C")
        XCTAssertEqual(provider.resolve(key: "k2"), "default_k2",
                       "k2 should fall through to library default after bundle replacement")
    }

    func testPartialBundleWorks() {
        let provider = AmityStringProvider(libraryDefaults: ["k1": "default_k1", "k2": "default_k2"])
        provider.setLocale("ja", bundle: ["k1": "locale_k1"])
        XCTAssertEqual(provider.resolve(key: "k1"), "locale_k1")
        XCTAssertEqual(provider.resolve(key: "k2"), "default_k2")
    }

    func testDeactivateLocaleFallsThrough() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default_value"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        provider.deactivateLocale()
        XCTAssertEqual(provider.resolve(key: "key"), "default_value")
    }

    // MARK: - 7.4 Config Removal Fallback

    func testConfigTextPresent() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        XCTAssertEqual(provider.resolve(key: "key", configText: "config_value"), "config_value")
    }

    func testConfigTextRemovedFallsThrough() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        XCTAssertEqual(provider.resolve(key: "key", configText: nil), "locale_value")
    }

    func testConfigTextEmptyStringTreatedAsAbsent() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "locale_value"])
        XCTAssertEqual(provider.resolve(key: "key", configText: ""), "locale_value")
    }

    // MARK: - 7.5 Format String Arguments

    func testFormatArgsWithOverride() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        provider.setOverrides(["key": "Hello, %@! You have %d items."])
        XCTAssertEqual(provider.resolve(key: "key", args: "Alice", 5),
                       "Hello, Alice! You have 5 items.")
    }

    func testFormatArgsWithLocale() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        provider.setLocale("ja", bundle: ["key": "こんにちは、%@！%d件あります。"])
        XCTAssertEqual(provider.resolve(key: "key", args: "Alice", 5),
                       "こんにちは、Alice！5件あります。")
    }

    func testFormatArgsWithKeyFallback() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        XCTAssertEqual(provider.resolve(key: "unknown_key", args: "Alice", 5), "unknown_key")
    }

    // MARK: - 7.6 Module Independence

    func testSocialOverrideDoesNotAffectChat() {
        let social = AmityStringProvider(libraryDefaults: ["key": "default"])
        let chat = AmityStringProvider(libraryDefaults: ["key": "default"])
        social.setOverrides(["key": "social_override"])
        XCTAssertEqual(social.resolve(key: "key"), "social_override")
        XCTAssertEqual(chat.resolve(key: "key"), "default",
                       "Chat should not be affected by social override")
    }

    func testSocialLocaleDoesNotAffectCommon() {
        let social = AmityStringProvider(libraryDefaults: ["key": "default"])
        let common = AmityStringProvider(libraryDefaults: ["key": "default"])
        social.setLocale("ja", bundle: ["key": "japanese"])
        XCTAssertEqual(social.resolve(key: "key"), "japanese")
        XCTAssertEqual(common.resolve(key: "key"), "default",
                       "Common should not be affected by social locale")
    }

    // MARK: - Additional: Re-activate Locale

    func testReactivateLocale() {
        let provider = AmityStringProvider(libraryDefaults: ["key": "default"])
        provider.setLocale("ja", bundle: ["key": "japanese"])
        provider.deactivateLocale()
        XCTAssertEqual(provider.resolve(key: "key"), "default")
        provider.activateLocale("ja")
        XCTAssertEqual(provider.resolve(key: "key"), "japanese")
    }

    // MARK: - Version Increment (re-rendering trigger)

    func testSetLocaleIncrementsVersion() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        let initialVersion = provider.version
        provider.setLocale("ja", bundle: ["key": "value"])
        XCTAssertGreaterThan(provider.version, initialVersion)
    }

    func testSetOverridesIncrementsVersion() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        let initialVersion = provider.version
        provider.setOverrides(["key": "value"])
        XCTAssertGreaterThan(provider.version, initialVersion)
    }
}
