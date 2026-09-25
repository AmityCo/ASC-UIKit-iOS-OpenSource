//
//  AmityNetworkLogPage.swift
//  SampleApp
//

import SwiftUI

/// The full-screen state of the network log — where the tester stops driving the app and
/// starts investigating what it did.
///
/// - Note: There is deliberately no export action. The export container and whether exported
///   files need redaction are both unresolved, and an export carrying bearer tokens into a
///   ticket attachment is a wider exposure than the on-device viewer.
/// - Note: Gated to iOS 15. The sample app targets iOS 14 to match the SDK, but this is a
///   debug-only surface and testers run current iOS, so it uses modern SwiftUI rather
///   than constraining the whole viewer to iOS 14 idioms.
@available(iOS 15.0, *)
struct AmityNetworkLogPage: View {

    @ObservedObject var collector: AmityNetworkLogCollector
    @ObservedObject var model: AmityNetworkLogViewModel

    var onDismiss: () -> Void
    /// `true` at the full-height detent. Supplied by the presenter, which also owns the sheet.
    var isExpanded: Bool
    var onToggleSize: () -> Void

    @State private var detailActivityId: String?
    @State private var isConfirmingClear = false
    @State private var toast: String?

    private static let groupRenderCap = 50

    private var visibleEntries: [AmityNetworkLogEntry] { model.apply(to: collector.entries) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            searchField
            AmityNetworkLogFilterStrip(model: model, counts: model.counts(in: collector.entries))
            Divider().overlay(NetworkLogTheme.baseShade4)
            content
        }
        .background(NetworkLogTheme.background.ignoresSafeArea())
        .overlay(alignment: .bottom) { toastBanner }
        .confirmationDialog(
            "Clear captured log?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) { collector.clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All captured entries will be discarded. This cannot be undone.")
        }
        .sheet(item: Binding(
            get: { detailActivityId.map(NetworkLogIdentifier.init) },
            set: { detailActivityId = $0?.value }
        )) { identifier in
            if let activity = collector.activity(id: identifier.value) {
                AmityNetworkLogDetailPage(activity: activity)
                    // A sheet's drag-to-dismiss competes with the scroll view inside it: at
                    // the top of a long body, swiping down to scroll up dragged the sheet away
                    // instead of scrolling. Detail is dismissed with Done.
                    .interactiveDismissDisabled(true)
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(NetworkLogTheme.primary)
            }
            .accessibilityLabel("Close")

            Text("Network Log")
                .font(NetworkLogTheme.pageTitle)
                .foregroundColor(NetworkLogTheme.base)

            Text("\(collector.entries.count)")
                .font(NetworkLogTheme.panelCount)
                .foregroundColor(NetworkLogTheme.baseShade2)

            Spacer()

            Button { isConfirmingClear = true } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(NetworkLogTheme.baseShade1)
            }
            .accessibilityLabel("Clear")

            Button(action: onToggleSize) {
                Image(systemName: isExpanded
                      ? "arrow.down.right.and.arrow.up.left"
                      : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 18))
                    .foregroundColor(NetworkLogTheme.baseShade1)
            }
            .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
        }
        .padding(.horizontal, 14)
        // Extra room at the top: the sheet's grabber sits directly above this row, and 10pt
        // left the controls crowded against it.
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(NetworkLogTheme.baseShade2)
            TextField("Search URL, topic or body", text: $model.searchQuery)
                .font(NetworkLogTheme.searchField)
                .foregroundColor(NetworkLogTheme.base)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !model.searchQuery.isEmpty {
                Button { model.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(NetworkLogTheme.baseShade2)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 9).fill(NetworkLogTheme.backgroundShade1))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        let entries = visibleEntries
        if let state = model.emptyState(bufferIsEmpty: collector.entries.isEmpty, visibleIsEmpty: entries.isEmpty) {
            emptyState(state)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            rows(for: entry)
                        }
                    }
                }
                .onChange(of: entries.count) { _ in
                    guard let last = entries.last else { return }
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func rows(for entry: AmityNetworkLogEntry) -> some View {
        AmityNetworkLogRow(
            entry: entry,
            isExpanded: model.expandedGroupIds.contains(entry.id),
            onTap: { tapped(entry) },
            onLongPress: { copy(entry) }
        )
        .id(entry.id)

        if entry.variant == .group, model.expandedGroupIds.contains(entry.id) {
            let children = collector.children(ofGroup: entry.id)
            ForEach(Array(children.prefix(Self.groupRenderCap))) { child in
                AmityNetworkLogRow(entry: child, indentLevel: 1, onTap: { tapped(child) }, onLongPress: { copy(child) })
                    .id(child.id)
            }
            if children.count > Self.groupRenderCap {
                // Say how many are left rather than stopping silently.
                Text("\(children.count - Self.groupRenderCap) more")
                    .font(NetworkLogTheme.rowTimestamp)
                    .foregroundColor(NetworkLogTheme.primary)
                    .padding(.leading, NetworkLogTheme.rowIndentedLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: NetworkLogTheme.rowHeight)
            }
        }
    }

    private func emptyState(_ state: AmityNetworkLogEmptyState) -> some View {
        VStack {
            Spacer()
            Text(state == .bufferEmpty
                 ? "No network activity captured yet."
                 : "No entries match the current filters.")
                .font(NetworkLogTheme.emptyState)
                .foregroundColor(NetworkLogTheme.baseShade2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var toastBanner: some View {
        if let toast {
            Text(toast)
                .font(NetworkLogTheme.chipLabel)
                .foregroundColor(NetworkLogTheme.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(NetworkLogTheme.base))
                .padding(.bottom, 28)
        }
    }

    // MARK: - Interaction

    private func tapped(_ entry: AmityNetworkLogEntry) {
        if entry.variant == .group {
            model.toggleExpansion(of: entry.id)
        } else if let activityId = entry.activityId {
            detailActivityId = activityId
        }
    }

    private func copy(_ entry: AmityNetworkLogEntry) {
        guard let activityId = entry.activityId, let activity = collector.activity(id: activityId) else { return }
        switch entry.variant {
        case .request:
            guard let command = AmityNetworkLogCurl.command(for: activity) else { return }
            UIPasteboard.general.string = command
            show("Copied as cURL")
        case .message:
            UIPasteboard.general.string = activity.mqtt?.payload
            show("Copied payload")
        case .state:
            guard let state = activity.state else { return }
            UIPasteboard.general.string = [state.source, state.from, state.to, state.detail]
                .compactMap { $0 }.joined(separator: " ")
            show("Copied transition")
        case .group, .dropped:
            break
        }
    }

    private func show(_ message: String) {
        toast = message
        UIAccessibility.post(notification: .announcement, argument: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toast == message { toast = nil }
        }
    }
}

/// `sheet(item:)` needs an `Identifiable`; a bare `String` is not one.
struct NetworkLogIdentifier: Identifiable {
    let value: String
    var id: String { value }
    init(_ value: String) { self.value = value }
}
