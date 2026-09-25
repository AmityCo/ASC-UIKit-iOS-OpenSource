//
//  AmityNetworkLogEntryTests.swift
//  SampleAppTests
//

import XCTest
import AmitySDK
@testable import SampleApp

final class AmityNetworkLogEntryTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func httpActivity(
        type: AmityNetworkActivityType = .api,
        url: String = "https://api.eu.amity.co/api/v4/posts/abc123/comments",
        method: String = "GET",
        status: Int? = 200,
        error: String? = nil,
        isInFlight: Bool = false
    ) -> AmityNetworkActivity {
        AmityNetworkActivity(
            id: "id-1",
            type: type,
            startedAt: start,
            endedAt: isInFlight ? nil : start.addingTimeInterval(0.123),
            request: AmityNetworkRequest(method: method, url: url, headers: [:], body: nil, bodyOmissionReason: nil),
            response: status.map {
                AmityNetworkResponse(statusCode: $0, message: nil, headers: [:], body: nil, bodyOmissionReason: nil, contentLength: nil)
            },
            error: error
        )
    }

    // MARK: - Variant selection

    func testRequestBearingTypesProduceTheRequestVariant() {
        for type in [AmityNetworkActivityType.api, .upload, .download, .mediaSegment, .image] {
            let entry = AmityNetworkLogEntry(activity: httpActivity(type: type))
            XCTAssertEqual(entry.variant, .request, "\(type) should render as a request row")
        }
    }

    func testMqttMessageProducesTheMessageVariant() {
        let activity = AmityNetworkActivity(
            id: "m1", type: .mqttMessage, startedAt: start, endedAt: start,
            mqtt: AmityMqttActivity(topic: "channel.abc.message", payload: "{\"a\":1}", qos: 1)
        )
        let entry = AmityNetworkLogEntry(activity: activity)
        XCTAssertEqual(entry.variant, .message)
        XCTAssertEqual(entry.primaryLabel, "channel.abc.message")
        XCTAssertNil(entry.statusLabel, "an inbound MQTT message has no status")
    }

    func testStateTypesProduceTheStateVariantWithATransitionLabel() {
        let activity = AmityNetworkActivity(
            id: "s1", type: .mqttState, startedAt: start,
            state: AmityNetworkStateChange(source: "mqtt", from: "connecting", to: "connected", detail: nil)
        )
        let entry = AmityNetworkLogEntry(activity: activity)
        XCTAssertEqual(entry.variant, .state)
        XCTAssertEqual(entry.secondaryLabel, "connecting → connected")
    }

    func testStateVariantOmitsTheArrowWhenFromIsNil() {
        let activity = AmityNetworkActivity(
            id: "s2", type: .mqttState, startedAt: start,
            state: AmityNetworkStateChange(source: "mqtt", from: nil, to: "subscribed", detail: nil)
        )
        XCTAssertEqual(AmityNetworkLogEntry(activity: activity).secondaryLabel, "subscribed")
    }

    // MARK: - Request row content

    func testRequestRowLeadsWithPathNotHost() {
        let entry = AmityNetworkLogEntry(activity: httpActivity())
        XCTAssertEqual(entry.primaryLabel, "/api/v4/posts/abc123/comments")
        XCTAssertEqual(entry.secondaryLabel, "GET")
    }

    func testTimestampLabelIsWallClockWithMilliseconds() {
        let entry = AmityNetworkLogEntry(activity: httpActivity())
        XCTAssertEqual(entry.timestampLabel.count, 12, "HH:mm:ss.SSS is 12 characters")
        XCTAssertEqual(entry.timestampLabel.filter { $0 == ":" }.count, 2)
    }

    // MARK: - Status coding

    func testStatusClassIsDerivedFromTheStatusCodeClass() {
        XCTAssertEqual(AmityNetworkLogEntry(activity: httpActivity(status: 204)).statusClass, .success)
        XCTAssertEqual(AmityNetworkLogEntry(activity: httpActivity(status: 301)).statusClass, .neutral)
        XCTAssertEqual(AmityNetworkLogEntry(activity: httpActivity(status: 404)).statusClass, .warning)
        XCTAssertEqual(AmityNetworkLogEntry(activity: httpActivity(status: 503)).statusClass, .error)
    }

    func testTransportFailureRendersTheWordFailedNotAStatusCode() {
        let entry = AmityNetworkLogEntry(activity: httpActivity(status: nil, error: "timed out"))
        XCTAssertEqual(entry.statusClass, .error)
        XCTAssertEqual(entry.statusLabel, "failed", "colour is never the sole carrier of status")
    }

    func testInFlightRequestRendersPendingNotAStatusCode() {
        let entry = AmityNetworkLogEntry(activity: httpActivity(type: .image, status: nil, isInFlight: true))
        XCTAssertEqual(entry.statusClass, .inFlight)
        XCTAssertEqual(entry.statusLabel, "pending")
    }

    // MARK: - Filter mapping

    func testFilterMappingCollapsesEightTypesIntoFiveChips() {
        XCTAssertEqual(AmityNetworkLogFilter(type: .api), .rest)
        XCTAssertEqual(AmityNetworkLogFilter(type: .upload), .rest)
        XCTAssertEqual(AmityNetworkLogFilter(type: .download), .rest)
        XCTAssertEqual(AmityNetworkLogFilter(type: .mqttMessage), .mqtt)
        XCTAssertEqual(AmityNetworkLogFilter(type: .mqttState), .mqtt)
        XCTAssertEqual(AmityNetworkLogFilter(type: .mediaSegment), .hls)
        XCTAssertEqual(AmityNetworkLogFilter(type: .image), .images)
        XCTAssertEqual(AmityNetworkLogFilter(type: .streamState), .events)
    }

    // MARK: - Search haystack

    func testSearchHaystackIsPrecomputedLowercasedAndCoversTheUrl() {
        let entry = AmityNetworkLogEntry(activity: httpActivity(url: "https://api.eu.amity.co/api/v4/Posts"))
        XCTAssertTrue(entry.searchHaystack.contains("/api/v4/posts"))
        XCTAssertEqual(entry.searchHaystack, entry.searchHaystack.lowercased())
    }

    func testBinaryResponseBodiesAreExcludedFromTheSearchHaystack() {
        let binary = AmityCapturedBody(
            data: Data([0xFF, 0xD8, 0xFF]), decodedLength: 3, wireLength: 3,
            contentEncoding: nil, truncated: false, contentType: "image/jpeg"
        )
        let activity = AmityNetworkActivity(
            id: "b1", type: .api, startedAt: start, endedAt: start,
            request: AmityNetworkRequest(method: "GET", url: "https://cdn.amity.co/a.jpg", headers: [:], body: nil, bodyOmissionReason: nil),
            response: AmityNetworkResponse(statusCode: 200, message: nil, headers: [:], body: binary, bodyOmissionReason: nil, contentLength: 3)
        )
        let entry = AmityNetworkLogEntry(activity: activity)
        XCTAssertEqual(entry.searchHaystack.trimmingCharacters(in: .whitespaces), "https://cdn.amity.co/a.jpg")
    }
}
