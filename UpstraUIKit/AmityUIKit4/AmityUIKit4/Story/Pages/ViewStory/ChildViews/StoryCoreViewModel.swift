//
//  StoryCoreViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/3/24.
//

import SwiftUI
import AVKit
import Combine
import AmitySDK

enum MoveDirection {
    case forward, backward
}

class StoryCoreViewModel: ObservableObject, Equatable {
    
    static func == (lhs: StoryCoreViewModel, rhs: StoryCoreViewModel) -> Bool {
        lhs.storyTarget.targetId == rhs.storyTarget.targetId
    }
    
    @Published var storySegmentIndex: Int = 0
    @Published var playVideo: Bool = false
    @Published var playTime: CMTime = .zero
    @Published var isVideoLoading: Bool = false
    @Published var progressBarViewModel = ProgressBarViewModel(progressArray: [])
    
    weak var storyPageViewModel: AmityViewStoryPageViewModel!
    weak var storyTarget: AmityStoryTargetModel!
   
    let storyManager = StoryManager()
    private var cancellable: AnyCancellable?
    private let debouncer = Debouncer(delay: 0.01)
    
    init(_ storyTarget: AmityStoryTargetModel, storyPageViewModel: AmityViewStoryPageViewModel) {
        self.storyTarget = storyTarget
        self.storyPageViewModel = storyPageViewModel
    }
    
    func playPauseVideo(_ play: Bool) {
        if let item = storyTarget.items.element(at: storySegmentIndex),
           case let .content(storyModel) = item.type,
           case .video = storyModel.storyType {
            playVideo = play
        }
    }
    
    func stopVideo() {
        playVideo = false
        playTime = .zero
    }
        
    func playIfVideoStory() {
        if let item = storyTarget.items.element(at: storySegmentIndex),
           case let .content(storyModel) = item.type,
           case .video = storyModel.storyType {
            playTime = .zero
            playVideo = true
        } else {
            playVideo = false
            playTime = .zero
            storyPageViewModel.totalDuration = STORY_DURATION
        }
    }
    
    func isLoadedIfVideoStory() -> Bool {
        if let item = storyTarget.items.element(at: storySegmentIndex),
           case let .content(storyModel) = item.type,
           case .video = storyModel.storyType {
            return !isVideoLoading
        } else {
            return true
        }
    }
    
    func moveStorySegment(direction: MoveDirection, _ host: AmitySwiftUIHostWrapper) {
        guard 0..<progressBarViewModel.progressArray.count ~= storySegmentIndex else {
            return
        }

        switch direction {
        case .forward:
            progressBarViewModel.progressArray[storySegmentIndex].progress = progressBarViewModel.segmentFullProgress
            
            let lastSegmentIndex = progressBarViewModel.progressArray.count - 1
            let lastTargetIndex = storyPageViewModel.storyTargets.count - 1
            
            if storySegmentIndex != lastSegmentIndex {
                storySegmentIndex += 1
            } else if storySegmentIndex == lastSegmentIndex && storyPageViewModel.storyTargetIndex != lastTargetIndex {
                storySegmentIndex = 0
                storyPageViewModel.storyTargetIndex += 1
            }
            else if storyPageViewModel.storyTargetIndex == lastTargetIndex {
                host.controller?.dismiss(animated: true)
            }
        
        case .backward:
            progressBarViewModel.progressArray[storySegmentIndex].progress = 0
            
            if storySegmentIndex >= 1 {
                storySegmentIndex -= 1
                progressBarViewModel.progressArray[storySegmentIndex].progress  = 0
            } else if storyPageViewModel.storyTargetIndex >= 1 {
                updateProgressBarViewModelProgressArray(0)
                storyPageViewModel.storyTargetIndex -= 1
            }
        }
    }
    
    func timerAction(_ host: AmitySwiftUIHostWrapper) {
        guard 0..<progressBarViewModel.progressArray.count ~= storySegmentIndex else {
            return
        }
        
        let lastSegmentIndex = progressBarViewModel.progressArray.count - 1
        let lastTargetIndex = storyPageViewModel.storyTargets.count - 1
        
        if progressBarViewModel.progressArray[storySegmentIndex].progress == progressBarViewModel.segmentFullProgress {
            if storySegmentIndex != lastSegmentIndex {
                storySegmentIndex += 1
            } else if storyPageViewModel.storyTargetIndex != lastTargetIndex {
                storySegmentIndex = 0
                updateProgressBarViewModelProgressArray(0)
                storyPageViewModel.storyTargetIndex += 1
            } else if storyPageViewModel.storyTargetIndex == lastTargetIndex {
                host.controller?.dismiss(animated: true)
            }
        } else {
            let progressValueToIncrease = progressBarViewModel.segmentFullProgress / CGFloat(storyPageViewModel.totalDuration / 0.001)
            let oldProgress = progressBarViewModel.progressArray[storySegmentIndex].progress
            let newProgress = oldProgress + progressValueToIncrease
            progressBarViewModel.progressArray[storySegmentIndex].progress = min(max(oldProgress, newProgress), progressBarViewModel.segmentFullProgress)
        }
    }

    func createProgressBarViewModelProgressArray(_ segmentCount: Int) {
        progressBarViewModel.progressArray = (0..<segmentCount).map({ index in
            return AmityProgressBarElementViewModel()
        })
    }
    
    func updateProgressBarViewModelProgressArray(_ currentIndex: Int) {
        progressBarViewModel.progressArray.enumerated()
            .forEach { index, model in
                if index < currentIndex {
                    model.progress = progressBarViewModel.segmentFullProgress
                } else {
                    model.progress = 0.0
                }
            }
    }
    
    func moveToUnseenStory(_ index: Int) {
        debouncer.run { [weak self] in
            guard self?.storySegmentIndex != index else { return }
            self?.updateProgressBarViewModelProgressArray(index)
            self?.storySegmentIndex = index
        }
    }
    
    @MainActor
    func deleteStory(storyId: String, _ host: AmitySwiftUIHostWrapper) async throws {
        let isLastStory = storyTarget.itemCount == 1
        let isLastTarget = storyPageViewModel.storyTargets.count == 1
        try await storyManager.deleteStory(storyId: storyId)
        
        if isLastStory && !isLastTarget {
            storyPageViewModel.storyTargets.remove(at: storyPageViewModel.storyTargetIndex)
        } else if isLastStory && isLastTarget {
            host.controller?.dismiss(animated: true)
        }
        
        moveStorySegment(direction: .backward, host)
    }
    
    @MainActor
    @discardableResult
    func addReaction(storyId: String) async throws -> Bool {
        try await storyManager.addReaction(storyId: storyId)
    }
    
    @MainActor
    @discardableResult
    func removeReaction(storyId: String) async throws -> Bool {
        try await storyManager.removeReaction(storyId: storyId)
    }
    
}
