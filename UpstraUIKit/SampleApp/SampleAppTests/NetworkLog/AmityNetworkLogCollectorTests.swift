//
//  AmityNetworkLogCollectorTests.swift
//  SampleAppTests
//

import XCTest
import AmitySDK
@testable import SampleApp

final class AmityNetworkLogCollectorTests: XCTestCase {

    private var collector: AmityNetworkLogCollector!
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        collector = AmityNetworkLogCollector(requestCapacity: 10, highVolumeCapacity: 6)
    }

    override func tearDown() {
        collector = nil
        super.tearDown()
    }

    private func http(
        _ id: String,
        type: AmityNetworkActivityType = .api,
        status: Int? = 200,
        url: String = "https://api.amity.co/api/v4/posts",
        offset: TimeInterval = 0,
        isInFlight: Bool = false,
        droppedBefore: Int = 0
    ) -> AmityNetworkActivity {
        let began = start.addingTimeInterval(offset)
        return AmityNetworkActivity(
            id: id, type: type, startedAt: began,
            endedAt: isInFlight ? nil : began.addingTimeInterval(0.01),
            request: AmityNetworkRequest(method: "GET", url: url, headers: [:], body: nil, bodyOmissionReason: nil),
            response: status.map {
                AmityNetworkResponse(statusCode: $0, message: nil, headers: [:], body: nil, bodyOmissionReason: nil, contentLength: nil)
            },
            droppedBefore: droppedBefore
        )
    }

    private func drainEntries(from collector: AmityNetworkLogCollector? = nil) -> [AmityNetworkLogEntry] {
        let target = collector ?? self.collector!
        let settled = expectation(description: "collector settled")
        target.performWhenSettled { settled.fulfill() }
        wait(for: [settled], timeout: 10.0)
        return target.entries
    }

    // MARK: - Ordering and identity

    func testEntriesAreOrderedByCaptureTimeOldestFirst() {
        collector.record(http("a", offset: 0))
        collector.record(http("b", offset: 1))
        XCTAssertEqual(drainEntries().map(\.id), ["a", "b"])
    }

    func testACompletedRecordReplacesItsInFlightRowInPlace() {
        // Uses .api rather than .image because groupable types collapse and would not
        // surface as their own row.
        collector.record(http("pending", status: nil, offset: 0, isInFlight: true))
        collector.record(http("other", offset: 1))
        collector.record(http("pending", status: 200, offset: 0))

        let entries = drainEntries()
        XCTAssertEqual(entries.map(\.id), ["pending", "other"], "the completed record keeps its position")
        XCTAssertEqual(entries.first?.statusLabel, "200")
    }

    func testAnInFlightRequestRendersAsPendingUntilItCompletes() {
        collector.record(http("pending", status: nil, isInFlight: true))
        XCTAssertEqual(drainEntries().first?.statusClass, .inFlight)
    }

    // MARK: - Grouping

    func testApiUploadAndDownloadRowsAreNeverGrouped() {
        for index in 0..<5 { collector.record(http("api\(index)", type: .api, offset: Double(index))) }
        let entries = drainEntries()
        XCTAssertEqual(entries.count, 5)
        XCTAssertTrue(entries.allSatisfy { $0.variant == .request })
    }

    func testConsecutiveImageLoadsCollapseIntoOneGroupRow() {
        for index in 0..<4 {
            collector.record(http("img\(index)", type: .image, url: "https://cdn.amity.co/\(index).jpg", offset: Double(index)))
        }
        let entries = drainEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.variant, .group)
        XCTAssertEqual(entries.first?.childCount, 4)
    }

    func testAGroupTracksItsFailureCountSoAProblemIsVisibleWithoutExpanding() {
        collector.record(http("img0", type: .image, offset: 0))
        collector.record(http("img1", type: .image, status: 404, offset: 1))
        collector.record(http("img2", type: .image, status: 500, offset: 2))

        let group = drainEntries().first
        XCTAssertEqual(group?.childCount, 3)
        XCTAssertEqual(group?.failureCount, 2, "4xx and 5xx both count as failures")
    }

    func testAnInterveningApiCallClosesTheGroupAndTheNextImageOpensANewOne() {
        collector.record(http("img0", type: .image, offset: 0))
        collector.record(http("api0", type: .api, offset: 1))
        collector.record(http("img1", type: .image, offset: 2))

        let entries = drainEntries()
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.map(\.variant), [.group, .request, .group])
    }

    func testExpandingAGroupYieldsItsChildrenInOrder() throws {
        for index in 0..<3 {
            collector.record(http("img\(index)", type: .image, url: "https://cdn.amity.co/\(index).jpg", offset: Double(index)))
        }
        let group = try XCTUnwrap(drainEntries().first)
        XCTAssertEqual(collector.children(ofGroup: group.id).map(\.id), ["img0", "img1", "img2"])
    }

    // MARK: - Dropped markers

    func testANonZeroDroppedCountInsertsAMarkerAtTheGapPosition() {
        collector.record(http("a", offset: 0))
        collector.record(http("b", offset: 1, droppedBefore: 7))

        let entries = drainEntries()
        XCTAssertEqual(entries.map(\.variant), [.request, .dropped, .request])
        XCTAssertTrue(entries[1].primaryLabel.contains("7"))
    }

    // MARK: - Bounded retention

    func testHighVolumeEntriesDoNotEvictRequestEntries() {
        collector.record(http("api0", type: .api, offset: 0))
        for index in 0..<20 {
            collector.record(http("img\(index)", type: .image, offset: Double(index + 1)))
        }
        XCTAssertTrue(drainEntries().contains { $0.id == "api0" }, "the API row must survive an image flood")
    }

    func testRequestRingEvictsOldestOnceCapacityIsExceeded() {
        for index in 0..<14 { collector.record(http("api\(index)", type: .api, offset: Double(index))) }
        let ids = drainEntries().map(\.id)
        XCTAssertEqual(ids.count, 10, "capacity is 10")
        XCTAssertFalse(ids.contains("api0"), "the oldest entry is evicted first")
        XCTAssertTrue(ids.contains("api13"))
    }

    // MARK: - Clear

    func testClearEmptiesTheBufferAndResetsGrouping() {
        collector.record(http("img0", type: .image, offset: 0))
        _ = drainEntries()
        collector.clear()
        XCTAssertTrue(drainEntries().isEmpty)

        collector.record(http("img1", type: .image, offset: 1))
        XCTAssertEqual(drainEntries().first?.childCount, 1, "grouping restarts after a clear")
    }

    // MARK: - Thread safety

    func testConcurrentWritesFromManyQueuesDoNotCrashOrLoseRecords() {
        let done = expectation(description: "writers finished")
        done.expectedFulfillmentCount = 6
        let wide = AmityNetworkLogCollector(requestCapacity: 5_000, highVolumeCapacity: 5_000)

        for worker in 0..<6 {
            DispatchQueue.global().async {
                for index in 0..<100 {
                    wide.record(self.http("w\(worker)-\(index)", offset: Double(index)))
                }
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 60.0)
        XCTAssertEqual(drainEntries(from: wide).count, 600)
    }
}
