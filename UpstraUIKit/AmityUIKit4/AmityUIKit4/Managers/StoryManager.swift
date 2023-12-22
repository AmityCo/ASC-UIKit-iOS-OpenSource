//
//  StoryManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/23.
//

import Foundation
import AmitySDK

public class StoryManager {
    let repository: AmityStoryRepository
    
    public init() {
        repository = AmityStoryRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    @MainActor
    public func getActiveStories(in communityId: String) -> AmityCollection<AmityStory> {
        repository.getActiveStoriesByTarget(targetType: .community, targetId: communityId, sortOption: .firstCreated)
    }
    
    @MainActor
    @discardableResult
    public func createImageStory(in communityId: String, createOption: AmityImageStoryCreateOptions) async throws -> AmityStory {
        return try await repository.createImageStory(options: createOption)
    }
    
    @MainActor
    @discardableResult
    public func createVideoStory(in communityId: String, createOption: AmityVideoStoryCreateOptions) async throws -> AmityStory {
        return try await repository.createVideoStory(options: createOption)
    }
    
    @MainActor
    public func deleteStory(storyId: String) async throws {
        return try await repository.softDeleteStory(storyId: storyId)
    }
}
