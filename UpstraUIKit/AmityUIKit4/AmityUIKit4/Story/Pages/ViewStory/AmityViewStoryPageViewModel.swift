//
//  AmityStoryPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/3/24.
//

import SwiftUI
import AmitySDK
import Combine

let STORY_DURATION: CGFloat = 4.0

class AmityViewStoryPageViewModel: ObservableObject {
    @Published var storyTargetIndex: Int = 0
    
    @Published var storyTargets: [AmityStoryTargetModel] = []
    @Published var totalDuration: CGFloat = STORY_DURATION
    @Published var storyTargetLoadingStatus: AmityLoadingStatus = .notLoading
    @Published var shouldRunTimer: Bool = false
    @Published var showActivityIndicator: Bool = true
    var seenStoryCount: Int = 0
    
    private var cancellable = Set<AnyCancellable>()
    private var storyTargetObject: AmityObject<AmityStoryTarget>?
    private var storyTargetCollection: AmityCollection<AmityStoryTarget>?
    private var seenStoryModels: Set<AmityStoryModel> = Set()
    private let updateShouldRunTimedebouncer = Debouncer(delay: 0.1)
    private let storyTargetMovingDebouncer = Debouncer(delay: 0.3)
    
    let storyManager = StoryManager()
    let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
    
    var activeStoryTarget: AmityStoryTargetModel {
        storyTargets[storyTargetIndex]
    }
    
    init(type: AmityViewStoryPageType) {
        
        switch type {
        case .communityFeed(let communityId):
            storyTargetObject = storyManager.getStoryTarget(targetType: .community, targetId: communityId)
            storyTargetObject?.$snapshot
                .first()
                .sink { [weak self] target in
                    guard let self, let target else { return }
                    
                    let storyTarget = AmityStoryTargetModel(target)
                    self.storyTargets = [storyTarget]
                }
                .store(in: &cancellable)
            
            storyTargetObject?.$loadingStatus
                .sink(receiveValue: { [weak self] status in
                    guard let self else { return }
                    self.storyTargetLoadingStatus = status
                })
                .store(in: &cancellable)
            
        case .globalFeed(_):
            storyTargetCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
            storyTargetCollection?.$snapshots
                .first { !$0.isEmpty }
                .sink { [weak self] targets in
                    guard let self else { return }
                    
                    let storyTargets = targets.compactMap { target -> AmityStoryTargetModel? in
                        return AmityStoryTargetModel(target)
                    }.removeDuplicates()
                    
                    self.storyTargets = storyTargets
                }
                .store(in: &cancellable)
                    
            storyTargetCollection?.$loadingStatus
                .sink(receiveValue: { [weak self] status in
                    guard let self else { return }
                    self.storyTargetLoadingStatus = status
                })
                .store(in: &cancellable)
        }
    }
    
    deinit {
        timer.upstream.connect().cancel()
        URLImageService.defaultImageService.inMemoryStore?.removeAllImages()
    }
    
    func markAsSeen(_ storyModel: AmityStoryModel) {
        if !storyModel.isSeen {
            storyModel.analytics.markAsSeen()
        }
        seenStoryCount += 1
    }
    
    func debounceUpdateShouldRunTimer(_ value: Bool) {
        updateShouldRunTimedebouncer.run { [weak self] in
            guard self?.shouldRunTimer != value else { return }
            self?.shouldRunTimer = value
        }
    }
    
    func debounceUpdateStoryTargetIndex(_ value: Int) {
        storyTargetMovingDebouncer.run { [weak self] in
            guard self?.storyTargetIndex != value else { return }
            self?.storyTargetIndex = value
        }
    }
}
