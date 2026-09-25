//
//  AmityNetworkLogCurl.swift
//  SampleApp
//

import Foundation
import AmitySDK

/// Renders a request-bearing activity as a runnable `curl` command.
enum AmityNetworkLogCurl {

    /// Returns `nil` for MQTT and state activities, which have no HTTP representation.
    static func command(for activity: AmityNetworkActivity) -> String? {
        guard activity.type.isRequestBearing, let request = activity.request else { return nil }

        var parts = ["curl -X \(request.method)", quoted(request.url)]

        for name in request.headers.keys.sorted() {
            for value in request.headers[name] ?? [] {
                parts.append("-H \(quoted("\(name): \(value)"))")
            }
        }

        var trailingComments: [String] = []

        if let body = request.body, let text = String(data: body.data, encoding: .utf8) {
            parts.append("--data-raw \(quoted(text))")
            if body.truncated {
                // A clipped body sent without comment produces a command that looks right and
                // sends the wrong thing.
                let declared = body.decodedLength.map(String.init) ?? "unknown"
                trailingComments.append("# body truncated — \(body.data.count) of \(declared) bytes captured")
            }
        } else if let reason = request.bodyOmissionReason, reason != .empty {
            trailingComments.append("# body not captured (\(reason.rawValue))")
        }

        let command = parts.joined(separator: " ")
        guard !trailingComments.isEmpty else { return command }
        return ([command] + trailingComments).joined(separator: "\n")
    }

    /// Wraps a value in single quotes, escaping any single quote by closing, escaping and
    /// reopening — the only quoting safe for arbitrary bytes in POSIX shells.
    private static func quoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
