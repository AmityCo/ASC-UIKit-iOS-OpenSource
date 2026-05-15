//
//  ReactionLocalizationTests.swift
//  AmityUIKit4Tests
//

import XCTest
@testable import AmityUIKit4

@MainActor
final class ReactionLocalizationTests: XCTestCase {

    func testBuiltInReactionResolvesFromLibraryDefault() {
        let provider = AmityStringProvider(libraryDefaults: [
            "amity_social_reaction_like": "Like"
        ])
        XCTAssertEqual(provider.resolveReactionDisplayName("like"), "Like")
    }

    func testCustomReactionWithTranslation() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        provider.setLocale("ja", bundle: [
            "amity_common_reaction_custom": "カスタム"
        ])
        XCTAssertEqual(provider.resolveReactionDisplayName("custom"), "カスタム")
    }

    func testCustomReactionWithoutTranslationFallsBackToTitleCase() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        XCTAssertEqual(provider.resolveReactionDisplayName("custom"), "Custom")
    }

    func testEmptyReactionNameReturnsEmpty() {
        let provider = AmityStringProvider(libraryDefaults: [:])
        XCTAssertEqual(provider.resolveReactionDisplayName(""), "")
    }

    func testReactionOverrideWinsOverLibraryDefault() {
        let provider = AmityStringProvider(libraryDefaults: [
            "amity_social_reaction_like": "Like"
        ])
        provider.setOverrides(["amity_social_reaction_like": "いいね"])
        XCTAssertEqual(provider.resolveReactionDisplayName("like"), "いいね")
    }

    func testReactionLocaleWinsOverLibraryDefault() {
        let provider = AmityStringProvider(libraryDefaults: [
            "amity_social_reaction_like": "Like"
        ])
        provider.setLocale("ja", bundle: ["amity_social_reaction_like": "いいね"])
        XCTAssertEqual(provider.resolveReactionDisplayName("like"), "いいね")
    }
}
