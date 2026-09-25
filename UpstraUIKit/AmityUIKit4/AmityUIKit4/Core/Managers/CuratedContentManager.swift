//
//  CuratedContentManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/9/26.
//

import Foundation
import AmitySDK

class CuratedContentManager {
    private let curatedContentRepository = AmityCuratedContentRepository()

    /// The `limit` ceiling `getPool` accepts. The SDK validates locally and throws before issuing
    /// the request, so a value outside `1…100` never reaches the network — it surfaces as the widget
    /// hiding on every load, which is indistinguishable from a topic that has no content.
    static let maximumPoolSize: Int = 100

    @MainActor
    func getPool(topicId: String, limit: Int = CuratedContentManager.maximumPoolSize) async throws -> AmityCuratedContentPool {
        return try await curatedContentRepository.getPool(topicId: topicId, limit: limit)
    }
}
