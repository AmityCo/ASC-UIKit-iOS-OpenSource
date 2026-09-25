//
//  AmityNetworkLogCollector.swift
//  SampleApp
//

import Foundation
import Combine
import AmitySDK
import AmityUIKit4

/// Owns the captured session: one ordered timeline, bounded, thread-safe, and pre-formatted.
///
/// Writes arrive on SDK delivery queues and the image downloader's queue; reads happen on the
/// main thread. All mutation is funnelled onto one serial queue and the snapshot is
/// republished to main, so no lock is ever held across a UI read.
final class AmityNetworkLogCollector: ObservableObject {

    /// Row models, oldest first. Main-thread only.
    @Published private(set) var entries: [AmityNetworkLogEntry] = []
    /// Records lost this session, to recorder backpressure or buffer eviction.
    @Published private(set) var droppedCount: Int = 0

    private let queue = DispatchQueue(label: "co.amity.sample.network-log-collector")

    /// Two budgets, deliberately. Sharing one ring lets a livestream or a feed scroll evict
    /// every API call within minutes, which is exactly the row a tester came to look at.
    private var requestRing: AmityNetworkLogRingBuffer<Node>
    private var highVolumeRing: AmityNetworkLogRingBuffer<Node>

    private var openGroup: OpenGroup?
    private var token: AmityNetworkActivityToken?
    private var droppedTotal = 0

    /// Records and group membership, read by the UI and written by the collector queue.
    ///
    /// Guarded by a lock rather than the serial queue: the UI reads these while rendering, and
    /// a `queue.sync` from the main thread would wait behind whatever backlog the queue is
    /// working through — which during a livestream is exactly when the UI must stay responsive.
    private let readLock = NSLock()
    private var activities: [String: AmityNetworkActivity] = [:]
    private var groupChildIds: [String: [String]] = [:]

    /// Publishing is coalesced: rebuilding the row list is proportional to buffer size, and
    /// doing that per record would burn the main thread during a burst.
    private var isPublishScheduled = false
    private static let publishInterval: DispatchTimeInterval = .milliseconds(100)

    /// A timeline position: a single activity, a group of collapsed ones, or a gap.
    private enum Node {
        case single(id: String, at: Date)
        case group(id: String, at: Date, type: AmityNetworkActivityType, childIds: [String], failures: Int)
        case dropped(id: String, at: Date, count: Int)

        var at: Date {
            switch self {
            case .single(_, let at), .group(_, let at, _, _, _), .dropped(_, let at, _): return at
            }
        }
    }

    private struct OpenGroup {
        let id: String
        let type: AmityNetworkActivityType
        let startedAt: Date
        var childIds: [String]
        var failures: Int
    }

    init(requestCapacity: Int = 2_000, highVolumeCapacity: Int = 1_000) {
        self.requestRing = AmityNetworkLogRingBuffer(capacity: requestCapacity)
        self.highVolumeRing = AmityNetworkLogRingBuffer(capacity: highVolumeCapacity)
    }

    deinit { token?.cancel() }

    // MARK: - Lifecycle

    /// Subscribes to both sources.
    ///
    /// Call during application init, not when the overlay is first shown: the stream has no
    /// replay, so a late subscription silently loses the whole login burst.
    func start(client: AmityClient) {
        guard token == nil else { return }
        token = client.observeNetworkActivities { [weak self] activity in
            self?.record(activity)
        }
        // UIKit-captured activities are merged into the same timeline.
        AmityUIKitNetworkCapture.shared.start { [weak self] activity in
            self?.record(activity)
        }
    }

    /// Detaches both subscriptions, which flips the SDK recorder inert, and empties the buffer.
    func stop() {
        token?.cancel()
        token = nil
        AmityUIKitNetworkCapture.shared.stop()
        clear()
    }

    // MARK: - Ingestion

    /// Public because the UIKit seams feed it directly rather than going through the SDK stream.
    func record(_ activity: AmityNetworkActivity) {
        queue.async { [weak self] in
            guard let self else { return }
            self.ingest(activity)
            self.publish()
        }
    }

    func clear() {
        queue.async { [weak self] in
            guard let self else { return }
            self.requestRing.removeAll()
            self.highVolumeRing.removeAll()
            self.readLock.lock()
            self.activities.removeAll()
            self.groupChildIds.removeAll()
            self.readLock.unlock()
            self.openGroup = nil
            self.droppedTotal = 0
            self.publish(immediately: true)
        }
    }

    /// Test hook: fires once every queued mutation has been applied and published.
    /// Test hook: fires once every queued mutation has been applied *and* the coalesced
    /// publish has reached the main thread.
    func performWhenSettled(_ work: @escaping () -> Void) {
        queue.async { [weak self] in
            self?.publish(immediately: true)
            DispatchQueue.main.async(execute: work)
        }
    }

    /// The raw records behind a group row, in order.
    func children(ofGroup groupId: String) -> [AmityNetworkLogEntry] {
        readLock.lock()
        defer { readLock.unlock() }
        return (groupChildIds[groupId] ?? [])
            .compactMap { activities[$0] }
            .map { AmityNetworkLogEntry(activity: $0) }
    }

    /// The full record behind a row, for the detail view.
    func activity(id: String) -> AmityNetworkActivity? {
        readLock.lock()
        defer { readLock.unlock() }
        return activities[id]
    }

    /// Not called during rendering, so the serial queue is fine here.
    func snapshot() -> [AmityNetworkActivity] {
        queue.sync {
            (requestRing.elements + highVolumeRing.elements)
                .sorted { $0.at < $1.at }
                .flatMap { node -> [AmityNetworkActivity] in
                    switch node {
                    case .single(let id, _):
                        return [storedActivity(id)].compactMap { $0 }
                    case .group(_, _, _, let childIds, _):
                        return childIds.compactMap { storedActivity($0) }
                    case .dropped:
                        return []
                    }
                }
        }
    }

    // MARK: - Queue-confined internals

    private func ingest(_ activity: AmityNetworkActivity) {
        // A completed record supersedes the in-flight one carrying the same id, keeping its
        // position rather than appending a duplicate row.
        if storedActivity(activity.id) != nil {
            store(activity)
            refreshOpenGroupFailures(containing: activity.id)
            return
        }

        if activity.droppedBefore > 0 {
            droppedTotal += activity.droppedBefore
            closeOpenGroup()
            requestRing.append(.dropped(
                id: "dropped-\(UUID().uuidString)",
                at: activity.startedAt,
                count: activity.droppedBefore
            ))
        }

        store(activity)

        guard isGroupable(activity.type) else {
            // API, upload and download rows are the low-volume ones a tester is usually
            // looking for — collapsing them would hide the signal.
            closeOpenGroup()
            requestRing.append(.single(id: activity.id, at: activity.startedAt))
            return
        }

        appendToGroup(activity)
    }

    private func store(_ activity: AmityNetworkActivity) {
        readLock.lock()
        activities[activity.id] = activity
        readLock.unlock()
    }

    private func storedActivity(_ id: String) -> AmityNetworkActivity? {
        readLock.lock()
        defer { readLock.unlock() }
        return activities[id]
    }

    private func isGroupable(_ type: AmityNetworkActivityType) -> Bool {
        type == .image || type == .mediaSegment
    }

    private func appendToGroup(_ activity: AmityNetworkActivity) {
        if var group = openGroup, group.type == activity.type {
            group.childIds.append(activity.id)
            if isFailure(activity) { group.failures += 1 }
            openGroup = group
            rewriteOpenGroupNode()
            return
        }

        closeOpenGroup()
        let group = OpenGroup(
            id: "group-\(UUID().uuidString)",
            type: activity.type,
            startedAt: activity.startedAt,
            childIds: [activity.id],
            failures: isFailure(activity) ? 1 : 0
        )
        openGroup = group
        readLock.lock()
        groupChildIds[group.id] = group.childIds
        readLock.unlock()
        highVolumeRing.append(.group(
            id: group.id, at: group.startedAt, type: group.type,
            childIds: group.childIds, failures: group.failures
        ))
    }

    private func rewriteOpenGroupNode() {
        guard let group = openGroup else { return }
        readLock.lock()
        groupChildIds[group.id] = group.childIds
        readLock.unlock()
        highVolumeRing.replaceFirst(where: {
            if case .group(let id, _, _, _, _) = $0 { return id == group.id }
            return false
        }, with: .group(
            id: group.id, at: group.startedAt, type: group.type,
            childIds: group.childIds, failures: group.failures
        ))
    }

    /// An in-flight child completing can turn a group's failure count non-zero after the fact.
    private func refreshOpenGroupFailures(containing activityId: String) {
        guard var group = openGroup, group.childIds.contains(activityId) else { return }
        group.failures = group.childIds
            .compactMap { storedActivity($0) }
            .filter { isFailure($0) }
            .count
        openGroup = group
        rewriteOpenGroupNode()
    }

    /// A group closes when a different kind of activity intervenes; later activity of the same
    /// kind opens a new group rather than reopening this one.
    private func closeOpenGroup() {
        openGroup = nil
    }

    private func isFailure(_ activity: AmityNetworkActivity) -> Bool {
        if activity.error != nil { return true }
        guard let status = activity.response?.statusCode else { return false }
        return status >= 400
    }

    /// Row models are built here, on the collector queue, so composition does no formatting.
    private func publish(immediately: Bool = false) {
        guard immediately else {
            guard !isPublishScheduled else { return }
            isPublishScheduled = true
            queue.asyncAfter(deadline: .now() + Self.publishInterval) { [weak self] in
                guard let self else { return }
                self.isPublishScheduled = false
                self.publish(immediately: true)
            }
            return
        }

        let ordered = (requestRing.elements + highVolumeRing.elements).sorted { $0.at < $1.at }
        let evicted = requestRing.evictedCount + highVolumeRing.evictedCount
        let dropped = droppedTotal

        let rows: [AmityNetworkLogEntry] = ordered.compactMap { node in
            switch node {
            case .single(let id, _):
                return storedActivity(id).map { AmityNetworkLogEntry(activity: $0) }

            case .group(let id, let at, let type, let childIds, let failures):
                return AmityNetworkLogEntry(
                    id: id,
                    variant: .group,
                    type: type,
                    timestampLabel: Self.timestampFormatter.string(from: at),
                    primaryLabel: type == .image ? "Image loads" : "Media segments",
                    secondaryLabel: "\(childIds.count) requests",
                    statusLabel: failures == 0 ? "0 failed" : "\(failures) failed",
                    statusClass: failures == 0 ? .success : .error,
                    childCount: childIds.count,
                    failureCount: failures,
                    searchHaystack: childIds
                        .compactMap { storedActivity($0)?.request?.url }
                        .joined(separator: " ")
                        .lowercased()
                )

            case .dropped(let id, let at, let count):
                return AmityNetworkLogEntry(
                    id: id,
                    variant: .dropped,
                    type: .api,
                    timestampLabel: Self.timestampFormatter.string(from: at),
                    primaryLabel: "⚠ \(count) entries dropped",
                    secondaryLabel: nil,
                    statusLabel: nil,
                    statusClass: .warning
                )
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.entries = rows
            self?.droppedCount = dropped + evicted
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
