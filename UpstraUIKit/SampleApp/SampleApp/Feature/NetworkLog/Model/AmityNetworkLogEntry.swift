//
//  AmityNetworkLogEntry.swift
//  SampleApp
//

import Foundation
import AmitySDK

enum AmityNetworkLogRowVariant {
    case request, message, state, group, dropped
}

enum AmityNetworkLogStatusClass {
    case success, neutral, warning, error, inFlight, none
}

/// The five filter chips. Eight activity types collapse into five; the mapping is owned here,
/// not by the SDK.
enum AmityNetworkLogFilter: String, CaseIterable, Hashable {
    case rest, mqtt, hls, images, events

    init(type: AmityNetworkActivityType) {
        switch type {
        case .api, .upload, .download: self = .rest
        case .mqttMessage, .mqttState: self = .mqtt
        case .mediaSegment:            self = .hls
        case .image:                   self = .images
        case .streamState:             self = .events
        }
    }

    var title: String {
        switch self {
        case .rest:   return "REST"
        case .mqtt:   return "MQTT"
        case .hls:    return "HLS"
        case .images: return "Images"
        case .events: return "Events"
        }
    }
}

/// A row, fully formatted.
///
/// Built off the main thread by the collector so that composition does no string work — at
/// livestream volumes, formatting during layout is not affordable.
struct AmityNetworkLogEntry: Identifiable, Equatable {

    let id: String
    let variant: AmityNetworkLogRowVariant
    let type: AmityNetworkActivityType
    let filter: AmityNetworkLogFilter
    let timestampLabel: String
    /// Path, MQTT topic, group label, or dropped-marker text.
    let primaryLabel: String
    /// HTTP method, state transition, or QoS.
    let secondaryLabel: String?
    let statusLabel: String?
    let statusClass: AmityNetworkLogStatusClass
    let durationLabel: String?
    let childCount: Int?
    let failureCount: Int?
    /// Identifies the underlying SDK record so the detail view can look it up.
    let activityId: String?
    /// Lowercased URL, topic and body text, precomputed so search never formats on the fly.
    let searchHaystack: String

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    init(activity: AmityNetworkActivity) {
        self.id = activity.id
        self.type = activity.type
        self.filter = AmityNetworkLogFilter(type: activity.type)
        self.activityId = activity.id
        self.timestampLabel = Self.timestampFormatter.string(from: activity.startedAt)
        self.childCount = nil
        self.failureCount = nil

        switch activity.type {
        case .mqttMessage:
            self.variant = .message
            self.primaryLabel = activity.mqtt?.topic ?? "(no topic)"
            let byteCount = activity.mqtt?.payload.utf8.count ?? 0
            self.secondaryLabel = "qos \(activity.mqtt?.qos ?? 0)"
            // An inbound MQTT message has no status.
            self.statusLabel = nil
            self.statusClass = .none
            self.durationLabel = Self.byteLabel(Int64(byteCount))
            self.searchHaystack = [activity.mqtt?.topic, activity.mqtt?.payload]
                .compactMap { $0 }.joined(separator: " ").lowercased()

        case .mqttState, .streamState:
            self.variant = .state
            self.primaryLabel = activity.state?.source ?? activity.type.rawValue
            if let state = activity.state {
                self.secondaryLabel = state.from.map { "\($0) → \(state.to)" } ?? state.to
            } else {
                self.secondaryLabel = nil
            }
            // A state change is instantaneous: no status, no duration.
            self.statusLabel = nil
            self.statusClass = .none
            self.durationLabel = nil
            self.searchHaystack = [activity.state?.source, activity.state?.from, activity.state?.to, activity.state?.detail]
                .compactMap { $0 }.joined(separator: " ").lowercased()

        case .api, .upload, .download, .mediaSegment, .image:
            self.variant = .request
            let url = activity.request?.url ?? ""
            self.primaryLabel = Self.pathComponent(of: url)
            self.secondaryLabel = activity.request?.method
            self.durationLabel = activity.duration.map { String(format: "%.0fms", $0 * 1000) }

            if activity.error != nil {
                self.statusLabel = "failed"
                self.statusClass = .error
            } else if let status = activity.response?.statusCode {
                self.statusLabel = String(status)
                self.statusClass = Self.statusClass(for: status)
            } else if activity.endedAt == nil {
                self.statusLabel = "pending"
                self.statusClass = .inFlight
            } else {
                self.statusLabel = nil
                self.statusClass = .none
            }

            var haystack = url
            // Binary bodies are excluded from body matching; the URL still matches.
            if let body = activity.response?.body, Self.isTextual(body.contentType) {
                haystack += " " + (String(data: body.data, encoding: .utf8) ?? "")
            }
            if let body = activity.request?.body, Self.isTextual(body.contentType) {
                haystack += " " + (String(data: body.data, encoding: .utf8) ?? "")
            }
            self.searchHaystack = haystack.lowercased()
        }
    }

    /// Synthetic entries — group rows and dropped markers — are built by the collector rather
    /// than from a single record.
    init(
        id: String,
        variant: AmityNetworkLogRowVariant,
        type: AmityNetworkActivityType,
        timestampLabel: String,
        primaryLabel: String,
        secondaryLabel: String?,
        statusLabel: String?,
        statusClass: AmityNetworkLogStatusClass,
        durationLabel: String? = nil,
        childCount: Int? = nil,
        failureCount: Int? = nil,
        activityId: String? = nil,
        searchHaystack: String = ""
    ) {
        self.id = id
        self.variant = variant
        self.type = type
        self.filter = AmityNetworkLogFilter(type: type)
        self.timestampLabel = timestampLabel
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.statusLabel = statusLabel
        self.statusClass = statusClass
        self.durationLabel = durationLabel
        self.childCount = childCount
        self.failureCount = failureCount
        self.activityId = activityId
        self.searchHaystack = searchHaystack
    }

    // MARK: - Formatting helpers

    /// Rows lead with the path. Every row in a session shares a host, so leading with the host
    /// spends the width that actually distinguishes one row from another.
    static func pathComponent(of url: String) -> String {
        guard let components = URLComponents(string: url) else { return url }
        let path = components.path.isEmpty ? "/" : components.path
        guard let query = components.query else { return path }
        return path + "?" + query
    }

    static func statusClass(for status: Int) -> AmityNetworkLogStatusClass {
        switch status {
        case 200..<300: return .success
        case 300..<400: return .neutral
        case 400..<500: return .warning
        default:        return .error
        }
    }

    static func byteLabel(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f kB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    static func isTextual(_ contentType: String?) -> Bool {
        guard let contentType = contentType?.lowercased() else { return false }
        return contentType.hasPrefix("text/")
            || contentType.contains("json")
            || contentType.contains("xml")
            || contentType.contains("javascript")
            || contentType.contains("x-www-form-urlencoded")
    }
}
