//
//  ChannelListSortByConfigTests.swift
//  AmityUIKit4Tests
//

import XCTest
import AmitySDK
@testable import AmityUIKit4

final class ChannelListSortByConfigTests: XCTestCase {

    // MARK: - Decoding feature_flags.chat.channel_list_sort_by

    func testDecodesChannelListSortBy() throws {
        let flags = try AmityFeatureFlag.decode(from: ["chat": ["channel_list_sort_by": "lastMessage"]])
        XCTAssertEqual(flags.chat.channelListSortBy, "lastMessage")
    }

    func testMissingKeyDecodesAsNil() throws {
        let flags = try AmityFeatureFlag.decode(from: ["chat": ["enabled_channel_types": ["conversation"]]])
        XCTAssertNil(flags.chat.channelListSortBy)
        XCTAssertEqual(flags.chat.enabledChannelTypes, ["conversation"])
    }

    func testNonStringValueDecodesAsNilWithoutBreakingOtherFlags() throws {
        let flags = try AmityFeatureFlag.decode(from: ["chat": ["channel_list_sort_by": 1, "enabled_channel_types": ["community"]]])
        XCTAssertNil(flags.chat.channelListSortBy)
        XCTAssertEqual(flags.chat.enabledChannelTypes, ["community"])
    }

    func testBundledConfigDefaultsToLastActivity() throws {
        let path = try XCTUnwrap(Bundle(for: AmityUIKitConfigController.self).path(forResource: "AmityUIKitConfig", ofType: "json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as? [String: Any])
        let flags = try AmityFeatureFlag.decode(from: json["feature_flags"] as? [String: Any] ?? [:])
        XCTAssertEqual(flags.chat.channelListSortBy, "lastActivity")
        XCTAssertEqual(AmityUIKitConfigController.channelListSortBy(from: flags.chat.channelListSortBy), .lastActivity)
    }

    // MARK: - Mapping to AmityChannelSortBy

    func testLastMessageMapsToLastMessage() {
        XCTAssertEqual(AmityUIKitConfigController.channelListSortBy(from: "lastMessage"), .lastMessage)
    }

    func testLastActivityMapsToLastActivity() {
        XCTAssertEqual(AmityUIKitConfigController.channelListSortBy(from: "lastActivity"), .lastActivity)
    }

    func testMissingValueMapsToLastActivity() {
        XCTAssertEqual(AmityUIKitConfigController.channelListSortBy(from: nil), .lastActivity)
    }

    func testUnknownValuesMapToLastActivity() {
        for raw in ["", "LastMessage", "last_message", "lastCreated", "firstCreated", "displayName", "relevance"] {
            XCTAssertEqual(AmityUIKitConfigController.channelListSortBy(from: raw), .lastActivity, raw)
        }
    }
}
