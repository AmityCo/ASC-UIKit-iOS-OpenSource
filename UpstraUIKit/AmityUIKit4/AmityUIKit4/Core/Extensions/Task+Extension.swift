//
//  Task+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/27/25.
//

import Foundation
import Combine


extension Task where Success == Void, Failure == Error {
    /// Creates a new Task that runs on MainActor
    @discardableResult
    static func runOnMainActor(
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable @MainActor () async throws -> Void
    ) -> Task<Void, Error> {
        Task(priority: priority) { @MainActor in
            try await operation()
        }
    }
}

