//
//  AmityStoryTargetModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/12/23.
//

import UIKit
import AmitySDK
import Combine

public class AmityStoryTargetModel: ObservableObject, Identifiable, Equatable {
    
    public static func == (lhs: AmityStoryTargetModel, rhs: AmityStoryTargetModel) -> Bool {
        return lhs.targetId == rhs.targetId
    }
    
    public var id: String {
        return targetId
    }
    
    var storyTarget: AmityStoryTarget?
    let targetId: String
    let targetName: String
    let isVerifiedTarget: Bool
    let avatar: URL?
    var isGlobalFeedTarget: Bool
    let isPublicTarget: Bool
    
    @Published var stories: [AmityStoryModel] = []
    @Published var storyCount: Int = 0
    @Published var hasUnseenStory: Bool = false
    @Published var hasFailedStory: Bool = false
    @Published var hasSyncingStory: Bool = false
    @Published var storyLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var unseenStoryIndex: Int = 0
    
    private var storyCollection: AmityCollection<AmityStory>?
    private var storyCollectionCancellable: AnyCancellable?
    private var storyTargetStateCancellable: AnyCancellable?
    
    
    private let storyManager = StoryManager()
    
    // Use this initializer for GlobalFeed.
    // StoryCoreView need to load story before this target is rendered.
    public convenience init(storyTarget: AmityStoryTarget, targetId: String, targetName: String, isVerifiedTarget: Bool, isPublicTarget: Bool, avatar: URL?) {
        self.init(targetId: targetId, targetName: targetName, isVerifiedTarget: isVerifiedTarget, isPublicTarget: isPublicTarget, avatar: avatar)
        
        self.storyTarget = storyTarget
        self.isGlobalFeedTarget = true
        self.hasUnseenStory = storyTarget.hasUnseen
        self.hasFailedStory = storyTarget.failedStoriesCount != 0
        self.hasSyncingStory = storyTarget.syncingStoriesCount != 0
    }
    
    // Use this initializer for CommunityFeed.
    // Since it needs to prefetch active stories in target to check storyCount before AmityViewStoryPage is opened.
    // StoryCoreView does not need to load story again for this target since it already preloaded.
    public init(targetId: String, targetName: String, isVerifiedTarget: Bool, isPublicTarget: Bool, avatar: URL?) {
        self.targetId = targetId
        self.targetName = targetName
        self.isVerifiedTarget = isVerifiedTarget
        self.isPublicTarget = isPublicTarget
        self.avatar = avatar
        self.isGlobalFeedTarget = false
    }
    
    
    func fetchStory() {
        guard storyCollection == nil else { return }
        storyCollection = storyManager.getActiveStories(in: targetId)
        storyCollectionCancellable = nil
        
        storyCollectionCancellable = storyCollection?.$snapshots
            .sink(receiveValue: { [weak self] stories in
                guard let self else { return }
                
                if let hasUnseen = stories.first?.storyTarget?.hasUnseen {
                    self.hasUnseenStory = hasUnseen
                }
                
                if let failedStoryCount = stories.first?.storyTarget?.failedStoriesCount {
                    self.hasFailedStory = failedStoryCount != 0
                }
                
                if let syncingStoryCount = stories.first?.storyTarget?.syncingStoriesCount {
                    self.hasSyncingStory = syncingStoryCount != 0
                }
                
                // Search the first index of unseen story if present
                if self.hasUnseenStory {
                    if let unseenIndice = stories.firstIndex(where: { $0.isSeen == false }) {
                        self.unseenStoryIndex = unseenIndice
                    }
                }
                
                if self.storyCount != stories.count {
                    self.storyCount = stories.count
                }
                
                let newSnapshot = self.mapToModel(stories)
                self.stories = newSnapshot.stories
                VideoPlayer.preload(urls: newSnapshot.videoURLs)
                
                if stories.count == 0 {
                    self.hasUnseenStory = false
                    self.hasFailedStory = false
                    self.hasSyncingStory = false
                }
            })

    }
    
    func mapToModel(_ stories: [AmityStory]) -> (stories: [AmityStoryModel], videoURLs: [URL]) {
        var videoURLs: [URL] = []
        
        let storyModels = stories.map { story in
            if let videoURLStr = story.getVideoInfo()?.getVideo(resolution: .res_720p), let videoURL = URL(string: videoURLStr) {
                videoURLs.append(videoURL)
            }
            
            return AmityStoryModel(story: story)
        }
        
        return (storyModels, videoURLs)
    }
    
}
