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
    let isPublicTarget: Bool
    
    @Published var items: [PaginatedItem<AmityStoryModel>] = []
    @Published var itemCount: Int = 0
    @Published var storyLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var hasUnseenStory: Bool = false
    @Published var hasFailedStory: Bool = false
    @Published var hasSyncingStory: Bool = false
    @Published var unseenStoryIndex: Int = 0
    
    private var storyCollection: AmityCollection<AmityStory>?
    private var cancellable: Set<AnyCancellable> = Set()
    private var paginator: UIKitPaginator<AmityStory>?
    private var paginatorCancellable: AnyCancellable?
    
    private let storyManager = StoryManager()
    

    public init(_ storyTarget: AmityStoryTarget) {
        self.storyTarget = storyTarget
        self.targetId = storyTarget.targetId
        self.targetName = storyTarget.community?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.isVerifiedTarget = storyTarget.community?.isOfficial ?? false
        self.isPublicTarget = storyTarget.community?.isPublic ?? true
        self.avatar = URL(string: storyTarget.community?.avatar?.fileURL ?? "")
        self.hasUnseenStory = storyTarget.hasUnseen
        self.hasFailedStory = storyTarget.failedStoriesCount != 0
        self.hasSyncingStory = storyTarget.syncingStoriesCount != 0
    }
    
    func updateModel(_ storyTarget: AmityStoryTarget) {
        self.storyTarget = storyTarget
        self.hasUnseenStory = storyTarget.hasUnseen
        self.hasFailedStory = storyTarget.failedStoriesCount != 0
        self.hasSyncingStory = storyTarget.syncingStoriesCount != 0
    }
    
    func fetchStory(totalSeenStoryCount: Int = 0) {
        storyCollection = storyManager.getActiveStories(in: targetId)
        
        prepareDatasource(totalSeenStoryCount)
    }
    
    func prepareDatasource(_ totalSeenStoryCount: Int) {
        guard let storyCollection else { return }
        
        var surplus = 0
        if let adFrequency = AdEngine.shared.getAdFrequency(at: .story), adFrequency.value > 0 {
            surplus = totalSeenStoryCount % adFrequency.value
            Log.add(event: .info, "Surplus: \(surplus)")
        }
        
        paginatorCancellable = nil
        
        let communityId = storyTarget?.community?.communityId
        paginator = UIKitStoryPaginator(liveCollection: storyCollection, surplus: surplus, communityId: communityId, modelIdentifier: { $0.storyId })
        paginator?.load()
        
        paginatorCancellable = paginator?.$snapshots
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self, let stories = self.storyCollection?.snapshots else { return }
                
                if let hasUnseen = stories.first?.storyTarget?.hasUnseen {
                    self.hasUnseenStory = hasUnseen
                }
                
                if let failedStoryCount = stories.first?.storyTarget?.failedStoriesCount {
                    self.hasFailedStory = failedStoryCount != 0
                }
                
                if let syncingStoryCount = stories.first?.storyTarget?.syncingStoriesCount {
                    self.hasSyncingStory = syncingStoryCount != 0
                }
                
                let newSnapshot = self.mapToModel(items)
                
                // Search the first index of unseen story if present
                if self.hasUnseenStory {
                    for (index, item) in newSnapshot.items.enumerated() {
                        if case let .content(story) = item.type, story.isSeen == false {
                            self.unseenStoryIndex = index
                        }
                    }
                }
                
                self.items = newSnapshot.items
                self.itemCount = newSnapshot.items.count

                VideoPlayer.preload(urls: newSnapshot.videoURLs)
                
                
                if stories.count == 0 {
                    self.hasUnseenStory = false
                    self.hasFailedStory = false
                    self.hasSyncingStory = false
                }
                
                self.storyLoadingStatus = storyCollection.loadingStatus
            })
        
    }
    
    private func mapToModel(_ items: [PaginatedItem<AmityStory>]) -> (items: [PaginatedItem<AmityStoryModel>], videoURLs: [URL]) {
        var videoURLs: [URL] = []
        
        let mappedItems = items.map { item in
            switch item.type {
            case .ad(let ad):
                return PaginatedItem<AmityStoryModel>(id: ad.adId, type: .ad(ad))
                
            case .content(let story):
                if let videoURLStr = story.getVideoInfo()?.getVideo(resolution: .res_720p), let videoURL = URL(string: videoURLStr) {
                    videoURLs.append(videoURL)
                }
                return PaginatedItem<AmityStoryModel>(id: story.storyId, type: .content(AmityStoryModel(story: story)))
            }
        }
        
        return (mappedItems, videoURLs)
    }
    
}
