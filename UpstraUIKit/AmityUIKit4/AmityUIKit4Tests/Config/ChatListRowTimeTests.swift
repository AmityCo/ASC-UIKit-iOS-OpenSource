//
//  ChatListRowTimeTests.swift
//  AmityUIKit4Tests
//

import XCTest
import AmitySDK
@testable import AmityUIKit4

final class ChatListRowTimeTests: XCTestCase {

    private let createdAt = Date(timeIntervalSince1970: 1_000)
    private let lastMessageAt = Date(timeIntervalSince1970: 2_000)
    private let lastActivity = Date(timeIntervalSince1970: 3_000)
    private let updatedAt = Date(timeIntervalSince1970: 4_000)

    func testLastMessageSortShowsLastMessageAt() {
        let time = AmityChatListItemView.rowTime(lastActivity: lastActivity, lastMessageAt: lastMessageAt, createdAt: createdAt, updatedAt: updatedAt, sortBy: .lastMessage)
        XCTAssertEqual(time, lastMessageAt)
    }

    func testLastMessageSortWithoutMessagesShowsCreatedAt() {
        let time = AmityChatListItemView.rowTime(lastActivity: lastActivity, lastMessageAt: nil, createdAt: createdAt, updatedAt: updatedAt, sortBy: .lastMessage)
        XCTAssertEqual(time, createdAt)
    }

    func testLastActivitySortShowsLastActivity() {
        let time = AmityChatListItemView.rowTime(lastActivity: lastActivity, lastMessageAt: lastMessageAt, createdAt: createdAt, updatedAt: updatedAt, sortBy: .lastActivity)
        XCTAssertEqual(time, lastActivity)
    }

    func testLastActivitySortWithoutLastActivityShowsUpdatedAt() {
        let time = AmityChatListItemView.rowTime(lastActivity: nil, lastMessageAt: lastMessageAt, createdAt: createdAt, updatedAt: updatedAt, sortBy: .lastActivity)
        XCTAssertEqual(time, updatedAt)
    }
}
