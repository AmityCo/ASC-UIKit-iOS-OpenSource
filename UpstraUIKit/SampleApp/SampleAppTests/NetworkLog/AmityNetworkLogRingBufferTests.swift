//
//  AmityNetworkLogRingBufferTests.swift
//  SampleAppTests
//

import XCTest
@testable import SampleApp

final class AmityNetworkLogRingBufferTests: XCTestCase {

    func testAppendingUnderCapacityKeepsInsertionOrder() {
        var buffer = AmityNetworkLogRingBuffer<Int>(capacity: 5)
        [1, 2, 3].forEach { buffer.append($0) }
        XCTAssertEqual(buffer.elements, [1, 2, 3])
    }

    func testExceedingCapacityEvictsTheOldestFirst() {
        var buffer = AmityNetworkLogRingBuffer<Int>(capacity: 3)
        [1, 2, 3, 4, 5].forEach { buffer.append($0) }
        XCTAssertEqual(buffer.elements, [3, 4, 5])
        XCTAssertEqual(buffer.count, 3)
    }

    func testEvictedCountTracksHowManyEntriesWereLostToCapacity() {
        var buffer = AmityNetworkLogRingBuffer<Int>(capacity: 2)
        [1, 2, 3, 4].forEach { buffer.append($0) }
        XCTAssertEqual(buffer.evictedCount, 2)
    }

    func testRemoveAllEmptiesTheBufferAndResetsEvictionAccounting() {
        var buffer = AmityNetworkLogRingBuffer<Int>(capacity: 2)
        [1, 2, 3].forEach { buffer.append($0) }
        buffer.removeAll()
        XCTAssertTrue(buffer.elements.isEmpty)
        XCTAssertEqual(buffer.evictedCount, 0)
    }

    func testReplacingAnExistingElementKeepsItsPosition() {
        var buffer = AmityNetworkLogRingBuffer<String>(capacity: 4)
        ["a", "b", "c"].forEach { buffer.append($0) }
        XCTAssertTrue(buffer.replaceFirst(where: { $0 == "b" }, with: "B"))
        XCTAssertEqual(buffer.elements, ["a", "B", "c"])
    }

    func testReplacingAMissingElementReportsFailureAndChangesNothing() {
        var buffer = AmityNetworkLogRingBuffer<String>(capacity: 4)
        buffer.append("a")
        XCTAssertFalse(buffer.replaceFirst(where: { $0 == "z" }, with: "Z"))
        XCTAssertEqual(buffer.elements, ["a"])
    }

    func testCapacityOfZeroIsClampedToOneSoAppendNeverTraps() {
        var buffer = AmityNetworkLogRingBuffer<Int>(capacity: 0)
        buffer.append(1)
        XCTAssertEqual(buffer.elements, [1])
    }
}
