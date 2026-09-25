//
//  NetworkLogUITestSeed.swift
//  SampleApp
//

import Foundation
import AmitySDK

/// Fixture traffic for UI tests, so the viewer can be exercised without a live network.
///
/// Off unless the app is launched with `-seedNetworkLog`, which only the UI test bundle passes.
/// It exists because the cases that broke in practice — a body far too long to lay out, and
/// scrolling back up past it — cannot be reproduced from whatever traffic a login happens to
/// make, and are invisible to unit tests.
enum NetworkLogUITestSeed {

    static let launchArgument = "-seedNetworkLog"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func seedIfRequested(into collector: AmityNetworkLogCollector) {
        guard isEnabled else { return }

        let items = Array(repeating: #""aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa""#, count: 12_000).joined(separator: ",")
        let payload = #"{"items":[\#(items)],"zzzMarker":"END_OF_BODY"}"#
        let data = Data(payload.utf8)
        let now = Date()

        collector.record(AmityNetworkActivity(
            id: "uitest-large-body",
            type: .api,
            startedAt: now,
            endedAt: now.addingTimeInterval(0.2),
            request: AmityNetworkRequest(
                method: "GET",
                url: "https://api.staging.amity.co/api/v4/uitest/large",
                headers: ["Accept": ["application/json"]],
                body: nil,
                bodyOmissionReason: .empty),
            response: AmityNetworkResponse(
                statusCode: 200,
                message: nil,
                headers: ["Content-Type": ["application/json"]],
                body: AmityCapturedBody(
                    data: data,
                    decodedLength: Int64(data.count),
                    wireLength: Int64(data.count / 8),
                    contentEncoding: "gzip",
                    truncated: false,
                    contentType: "application/json"),
                bodyOmissionReason: nil,
                contentLength: Int64(data.count))))
    }
}
