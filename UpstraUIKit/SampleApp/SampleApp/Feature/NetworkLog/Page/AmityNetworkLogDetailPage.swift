//
//  AmityNetworkLogDetailPage.swift
//  SampleApp
//

import SwiftUI
import AmitySDK

/// One captured activity, read completely.
///
/// Values wrap here rather than truncating — the opposite of row behaviour, because a row
/// optimises for scanning many entries and detail optimises for reading one.
/// - Note: Gated to iOS 15. The sample app targets iOS 14 to match the SDK, but this is a
///   debug-only surface and testers run current iOS, so it uses modern SwiftUI rather
///   than constraining the whole viewer to iOS 14 idioms.
@available(iOS 15.0, *)
struct AmityNetworkLogDetailPage: View {

    let activity: AmityNetworkActivity

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                // VStack, not LazyVStack. A lazy stack does not measure offscreen children,
                // so scrolling back up past the body block — a single view thousands of
                // points tall — made it re-measure and the scroll offset jump. The page has
                // a few dozen rows, so laziness bought nothing and cost scroll stability.
                VStack(alignment: .leading, spacing: 0) {
                    switch activity.type {
                    case .mqttMessage: mqttSections
                    case .mqttState, .streamState: stateSections
                    default: requestSections
                    }
                }
            }
            .background(NetworkLogTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Detail").font(NetworkLogTheme.pageTitle).foregroundColor(NetworkLogTheme.base)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if let command = AmityNetworkLogCurl.command(for: activity) {
                        Button("Copy as cURL") {
                            UIPasteboard.general.string = command
                            UIAccessibility.post(notification: .announcement, argument: "Copied as cURL")
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Sections

    @ViewBuilder
    private var requestSections: some View {
        if let request = activity.request {
            sectionHeader("Request")
            keyValue("Method", request.method)
            keyValue("URL", request.url)
            keyValue("Started", isoString(activity.startedAt))
            if let duration = activity.duration {
                keyValue("Duration", String(format: "%.0f ms", duration * 1000))
            }

            sectionHeader("Request headers")
            headerRows(request.headers)

            sectionHeader("Request body")
            bodyBlock(request.body, omissionReason: request.bodyOmissionReason)
        }

        if let response = activity.response {
            sectionHeader("Response")
            keyValue("Status", "\(response.statusCode) \(response.message ?? "")")
            if let length = response.contentLength {
                keyValue("Content-Length", AmityNetworkLogEntry.byteLabel(length))
            }

            sectionHeader("Response headers")
            headerRows(response.headers)

            sectionHeader("Response body")
            bodyBlock(response.body, omissionReason: response.bodyOmissionReason)
        } else if let error = activity.error {
            sectionHeader("Error")
            keyValue("Transport", error)
        }
    }

    @ViewBuilder
    private var mqttSections: some View {
        sectionHeader("MQTT message")
        keyValue("Topic", activity.mqtt?.topic ?? "")
        keyValue("QoS", "\(activity.mqtt?.qos ?? 0)")
        keyValue("Received", isoString(activity.startedAt))

        sectionHeader("Payload")
        if let payload = activity.mqtt?.payload, !payload.isEmpty {
            NetworkLogBodyView(
                capturedBody: AmityCapturedBody(
                    data: Data(payload.utf8),
                    decodedLength: Int64(payload.utf8.count),
                    wireLength: Int64(payload.utf8.count),
                    contentEncoding: nil,
                    truncated: false,
                    contentType: "application/json"
                ),
                sizeLabel: nil,
                captureTruncationNotice: nil
            )
        } else {
            notice("Empty payload")
        }
    }

    @ViewBuilder
    private var stateSections: some View {
        sectionHeader("State change")
        keyValue("Source", activity.state?.source ?? "")
        keyValue("From", activity.state?.from ?? "—")
        keyValue("To", activity.state?.to ?? "")
        if let detail = activity.state?.detail {
            keyValue("Detail", detail)
        }
        keyValue("At", isoString(activity.startedAt))
    }

    // MARK: - Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(NetworkLogTheme.sectionHeader)
            .foregroundColor(NetworkLogTheme.baseShade1)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NetworkLogTheme.backgroundShade1)
            .accessibilityAddTraits(.isHeader)
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key)
                .font(NetworkLogTheme.detailKeyValue)
                .foregroundColor(NetworkLogTheme.baseShade2)
                .frame(width: 112, alignment: .leading)
            Text(value)
                .font(NetworkLogTheme.detailKeyValue)
                .foregroundColor(NetworkLogTheme.base)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(NetworkLogTheme.baseShade4).frame(height: 1)
        }
    }

    @ViewBuilder
    private func headerRows(_ headers: [String: [String]]) -> some View {
        if headers.isEmpty {
            keyValue("—", "No headers")
        } else {
            // Verbatim and unredacted, including Authorization. Safe only because this ships
            // in the sample app alone.
            ForEach(headers.keys.sorted(), id: \.self) { name in
                ForEach(Array((headers[name] ?? []).enumerated()), id: \.offset) { _, value in
                    keyValue(name, value)
                }
            }
        }
    }

    @ViewBuilder
    private func bodyBlock(_ body: AmityCapturedBody?, omissionReason: AmityNetworkBodyOmissionReason?) -> some View {
        if let body {
            NetworkLogBodyView(
                capturedBody: body,
                sizeLabel: sizeLabel(for: body),
                captureTruncationNotice: captureTruncationNotice(for: body)
            )
        } else {
            notice("Body not captured (\(omissionReason?.rawValue ?? "unknown"))")
        }
    }

    /// Capture-time truncation, which is separate from the display clipping the body view
    /// applies. Rendering a clipped body as if it were complete would make malformed JSON look
    /// like a server bug.
    private func captureTruncationNotice(for body: AmityCapturedBody) -> String? {
        guard body.truncated else { return nil }
        let captured = AmityNetworkLogEntry.byteLabel(Int64(body.data.count))
        let declared = body.decodedLength.map { AmityNetworkLogEntry.byteLabel($0) } ?? "unknown"
        return "Truncated at capture — \(captured) of \(declared) kept"
    }

    /// Shows both sizes when the body was compressed. One size alone hides the ratio, which is
    /// the reason to look in the first place.
    private func sizeLabel(for body: AmityCapturedBody) -> String? {
        guard let decoded = body.decodedLength else { return nil }
        guard let wire = body.wireLength, wire != decoded else {
            return AmityNetworkLogEntry.byteLabel(decoded)
        }
        let encoding = body.contentEncoding.map { " (\($0))" } ?? ""
        return "\(AmityNetworkLogEntry.byteLabel(wire)) wire · \(AmityNetworkLogEntry.byteLabel(decoded)) decoded\(encoding)"
    }

    private func notice(_ text: String) -> some View {
        Text(text)
            .font(NetworkLogTheme.rowTimestamp)
            .foregroundColor(NetworkLogTheme.warning)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
