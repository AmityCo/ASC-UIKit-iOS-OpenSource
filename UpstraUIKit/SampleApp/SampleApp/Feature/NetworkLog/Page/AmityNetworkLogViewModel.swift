//
//  AmityNetworkLogViewModel.swift
//  SampleApp
//

import Foundation
import Combine

enum AmityNetworkLogEmptyState {
    /// Nothing has been captured at all.
    case bufferEmpty
    /// Entries exist, but the active filters and query match none of them.
    case noMatches
}

/// Filter, search and expansion state for the viewer.
///
/// Shared by the docked panel and the full-screen page, so moving between them preserves
/// both. Entries live in the collector; keeping them apart is what lets the page be destroyed
/// and recreated without losing the capture.
final class AmityNetworkLogViewModel: ObservableObject {

    @Published var selectedFilters: Set<AmityNetworkLogFilter> = []
    @Published var searchQuery: String = ""
    @Published var expandedGroupIds: Set<String> = []

    /// Applies filters and search as a logical AND. Dropped markers are exempt from both — a
    /// gap must stay visible regardless of the active view, or the timeline quietly lies about
    /// its own completeness.
    func apply(to entries: [AmityNetworkLogEntry]) -> [AmityNetworkLogEntry] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !selectedFilters.isEmpty || !query.isEmpty else { return entries }

        return entries.filter { entry in
            guard entry.variant != .dropped else { return true }
            let matchesFilter = selectedFilters.isEmpty || selectedFilters.contains(entry.filter)
            let matchesQuery = query.isEmpty || entry.searchHaystack.contains(query)
            return matchesFilter && matchesQuery
        }
    }

    /// Per-chip counts over the whole buffer, not the filtered view.
    func counts(in entries: [AmityNetworkLogEntry]) -> [AmityNetworkLogFilter: Int] {
        var counts = Dictionary(uniqueKeysWithValues: AmityNetworkLogFilter.allCases.map { ($0, 0) })
        for entry in entries where entry.variant != .dropped {
            counts[entry.filter, default: 0] += 1
        }
        return counts
    }

    func emptyState(bufferIsEmpty: Bool, visibleIsEmpty: Bool) -> AmityNetworkLogEmptyState? {
        guard visibleIsEmpty else { return nil }
        return bufferIsEmpty ? .bufferEmpty : .noMatches
    }

    func toggle(_ filter: AmityNetworkLogFilter) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

    func toggleExpansion(of groupId: String) {
        if expandedGroupIds.contains(groupId) {
            expandedGroupIds.remove(groupId)
        } else {
            expandedGroupIds.insert(groupId)
        }
    }
}
