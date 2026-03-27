//
//  ViewedProductTracker.swift
//  AmityUIKit4
//

import Foundation

class ViewedProductTracker: ObservableObject {
    private var viewedKeys = Set<String>()

    /// Returns `true` if the key has already been recorded.
    func hasViewed(_ key: String) -> Bool {
        viewedKeys.contains(key)
    }

    /// Records the key and returns `true` if it was newly inserted (i.e. not seen before).
    @discardableResult
    func markViewed(_ key: String) -> Bool {
        viewedKeys.insert(key).inserted
    }
}
