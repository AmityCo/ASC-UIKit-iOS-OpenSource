//
//  AmityNetworkLogRingBuffer.swift
//  SampleApp
//

import Foundation

/// Fixed-capacity buffer that evicts the oldest entry first.
///
/// A plain array with a drop-from-front rather than a true circular buffer: at these
/// capacities the copy is immaterial, and keeping `elements` already in order avoids an
/// index unwrap on every read — which the UI does far more often than writers append.
struct AmityNetworkLogRingBuffer<Element> {

    private(set) var elements: [Element] = []
    private(set) var evictedCount: Int = 0

    let capacity: Int

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    var count: Int { elements.count }
    var isEmpty: Bool { elements.isEmpty }

    mutating func append(_ element: Element) {
        elements.append(element)
        guard elements.count > capacity else { return }
        let overflow = elements.count - capacity
        elements.removeFirst(overflow)
        evictedCount += overflow
    }

    /// Replaces an element in place, keeping its position — used to swap an in-flight record
    /// for the completed one carrying the same id.
    @discardableResult
    mutating func replaceFirst(where predicate: (Element) -> Bool, with element: Element) -> Bool {
        guard let index = elements.firstIndex(where: predicate) else { return false }
        elements[index] = element
        return true
    }

    mutating func removeAll() {
        elements.removeAll()
        evictedCount = 0
    }
}
