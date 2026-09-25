//
//  AmityNetworkLogCurlTests.swift
//  SampleAppTests
//

import XCTest
import AmitySDK
@testable import SampleApp

final class AmityNetworkLogCurlTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func activity(
        type: AmityNetworkActivityType = .api,
        method: String = "GET",
        url: String = "https://api.amity.co/api/v4/posts",
        headers: [String: [String]] = [:],
        body: AmityCapturedBody? = nil,
        omission: AmityNetworkBodyOmissionReason? = nil
    ) -> AmityNetworkActivity {
        AmityNetworkActivity(
            id: "c1", type: type, startedAt: start, endedAt: start,
            request: AmityNetworkRequest(method: method, url: url, headers: headers, body: body, bodyOmissionReason: omission)
        )
    }

    func testMinimalGetProducesARunnableCommand() {
        XCTAssertEqual(
            AmityNetworkLogCurl.command(for: activity()),
            "curl -X GET 'https://api.amity.co/api/v4/posts'"
        )
    }

    func testHeadersAreEmittedOncePerValue() throws {
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(
            headers: ["Accept": ["application/json"], "X-Trace": ["a", "b"]]
        )))
        XCTAssertTrue(command.contains("-H 'Accept: application/json'"))
        XCTAssertTrue(command.contains("-H 'X-Trace: a'"))
        XCTAssertTrue(command.contains("-H 'X-Trace: b'"))
    }

    func testAuthorizationHeaderIsNotRedacted() throws {
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(
            headers: ["Authorization": ["Bearer secret-token"]]
        )))
        XCTAssertTrue(command.contains("-H 'Authorization: Bearer secret-token'"))
    }

    func testSingleQuotesInValuesAreShellEscaped() throws {
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(
            url: "https://api.amity.co/search?q=it's"
        )))
        XCTAssertTrue(command.contains("'\\''"), "an unescaped quote would break the command")
    }

    func testCapturedBodyIsIncludedAsDataRaw() throws {
        let body = AmityCapturedBody(
            data: Data("{\"text\":\"hi\"}".utf8),
            decodedLength: 13, wireLength: 13, contentEncoding: nil,
            truncated: false, contentType: "application/json"
        )
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(method: "POST", body: body)))
        XCTAssertTrue(command.contains("--data-raw '{\"text\":\"hi\"}'"))
    }

    func testUncapturedBodyProducesAnInlineCommentRatherThanASilentEmptyBody() throws {
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(method: "POST", omission: .multipart)))
        XCTAssertFalse(command.contains("--data-raw"))
        XCTAssertTrue(command.contains("# body not captured (multipart)"))
    }

    func testTruncatedBodyIsLabelledSoTheCommandIsNotSilentlyWrong() throws {
        let body = AmityCapturedBody(
            data: Data("{\"text\":\"h".utf8),
            decodedLength: 4096, wireLength: 4096, contentEncoding: nil,
            truncated: true, contentType: "application/json"
        )
        let command = try XCTUnwrap(AmityNetworkLogCurl.command(for: activity(method: "POST", body: body)))
        XCTAssertTrue(command.contains("# body truncated"))
    }

    func testMqttAndStateActivitiesHaveNoCurlRepresentation() {
        let mqtt = AmityNetworkActivity(
            id: "m", type: .mqttMessage, startedAt: start, endedAt: start,
            mqtt: AmityMqttActivity(topic: "t", payload: "p", qos: 1)
        )
        let state = AmityNetworkActivity(
            id: "s", type: .mqttState, startedAt: start,
            state: AmityNetworkStateChange(source: "mqtt", from: nil, to: "connected", detail: nil)
        )
        XCTAssertNil(AmityNetworkLogCurl.command(for: mqtt))
        XCTAssertNil(AmityNetworkLogCurl.command(for: state))
    }
}
