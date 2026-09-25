//
//  AmityNetworkLogViewModelTests.swift
//  SampleAppTests
//

import XCTest
import AmitySDK
@testable import SampleApp

final class AmityNetworkLogViewModelTests: XCTestCase {

    private func entry(
        id: String,
        type: AmityNetworkActivityType,
        variant: AmityNetworkLogRowVariant = .request,
        haystack: String = ""
    ) -> AmityNetworkLogEntry {
        AmityNetworkLogEntry(
            id: id, variant: variant, type: type,
            timestampLabel: "00:00:00.000", primaryLabel: id, secondaryLabel: nil,
            statusLabel: "200", statusClass: .success, searchHaystack: haystack
        )
    }

    private lazy var sample: [AmityNetworkLogEntry] = [
        entry(id: "api", type: .api, haystack: "/api/v4/posts"),
        entry(id: "upload", type: .upload, haystack: "/upload/images"),
        entry(id: "mqtt", type: .mqttMessage, haystack: "channel.abc.message hello"),
        entry(id: "image", type: .image, variant: .group, haystack: "cdn/a.jpg"),
        entry(id: "gap", type: .api, variant: .dropped, haystack: ""),
    ]

    func testNoSelectedFilterIsEquivalentToAll() {
        XCTAssertEqual(AmityNetworkLogViewModel().apply(to: sample).count, sample.count)
    }

    func testSelectingRestKeepsApiAndUploadAndDropsMqtt() {
        let model = AmityNetworkLogViewModel()
        model.selectedFilters = [.rest]
        let ids = model.apply(to: sample).map(\.id)
        XCTAssertTrue(ids.contains("api"))
        XCTAssertTrue(ids.contains("upload"))
        XCTAssertFalse(ids.contains("mqtt"))
    }

    func testFiltersAreMultiSelect() {
        let model = AmityNetworkLogViewModel()
        model.selectedFilters = [.rest, .mqtt]
        let ids = model.apply(to: sample).map(\.id)
        XCTAssertTrue(ids.contains("api"))
        XCTAssertTrue(ids.contains("mqtt"))
        XCTAssertFalse(ids.contains("image"))
    }

    func testDroppedMarkersSurviveEveryFilter() {
        let model = AmityNetworkLogViewModel()
        model.selectedFilters = [.mqtt]
        XCTAssertTrue(model.apply(to: sample).map(\.id).contains("gap"))
    }

    func testSearchMatchesCaseInsensitiveSubstringsOfTheHaystack() {
        let model = AmityNetworkLogViewModel()
        model.searchQuery = "POSTS"
        XCTAssertEqual(model.apply(to: sample).filter { $0.variant != .dropped }.map(\.id), ["api"])
    }

    func testSearchMatchesMqttTopicAndPayload() {
        let model = AmityNetworkLogViewModel()
        model.searchQuery = "hello"
        XCTAssertEqual(model.apply(to: sample).filter { $0.variant != .dropped }.map(\.id), ["mqtt"])
    }

    func testDroppedMarkersSurviveSearchToo() {
        let model = AmityNetworkLogViewModel()
        model.searchQuery = "zzz-no-match"
        XCTAssertEqual(model.apply(to: sample).map(\.id), ["gap"])
    }

    func testSearchAndFiltersComposeAsLogicalAnd() {
        let model = AmityNetworkLogViewModel()
        model.selectedFilters = [.mqtt]
        model.searchQuery = "posts"
        XCTAssertTrue(model.apply(to: sample).filter { $0.variant != .dropped }.isEmpty)
    }

    func testPerFilterCountsAreComputedOverTheWholeBufferNotTheFilteredView() {
        let model = AmityNetworkLogViewModel()
        model.selectedFilters = [.mqtt]
        let counts = model.counts(in: sample)
        XCTAssertEqual(counts[.rest], 2)
        XCTAssertEqual(counts[.mqtt], 1)
        XCTAssertEqual(counts[.images], 1)
        XCTAssertEqual(counts[.events], 0)
    }

    func testEmptyBufferAndNoMatchesAreDistinguishableStates() {
        let model = AmityNetworkLogViewModel()
        XCTAssertEqual(model.emptyState(bufferIsEmpty: true, visibleIsEmpty: true), .bufferEmpty)
        model.searchQuery = "zzz"
        XCTAssertEqual(model.emptyState(bufferIsEmpty: false, visibleIsEmpty: true), .noMatches)
        XCTAssertNil(model.emptyState(bufferIsEmpty: false, visibleIsEmpty: false))
    }
}
