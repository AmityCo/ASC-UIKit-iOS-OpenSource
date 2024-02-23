//
//  AmityViewStoryPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/29/23.
//

import SwiftUI
import AVKit
import AmitySDK
import Combine

public struct AmityViewStoryPage: AmityPageView {
    @EnvironmentObject public var host: SwiftUIHostWrapper
    
    public var id: PageId {
        .storyPage
    }

    @StateObject var viewModel: AmityStoryPageViewModel
    
    @State private var totalDuration: CGFloat = 4.0
    
    @State private var storyTargetIndex = 0
    @State private var storySegmentIndex: Int = 0
    @State private var progressSegmentWidth: CGFloat = 0.0
    @State private var progressValueToIncrease: CGFloat = 0.0
    @State private var showBottomSheet: Bool = false
    @State private var isAlertShown: Bool = false
    @State private var showToast: Bool = false
    
    @State private var hasStoryManagePermission: Bool = false
    @StateObject private var progressBarViewModel: ProgressBarViewModel = ProgressBarViewModel(progressArray: [])
    @StateObject private var storyCoreViewModel: StoryCoreViewModel = StoryCoreViewModel()
        
    @State private var page: Page = Page.first()
    
    public init(storyTargets: [AmityStoryTargetModel], startFromTargetIndex: Int) {
        _viewModel = StateObject(wrappedValue: AmityStoryPageViewModel(storyTargets: storyTargets))
        _storyTargetIndex = State(initialValue: startFromTargetIndex)
        
        // preload the first stories from the staring story target
        preloadStoryTargets(startFromTargetIndex, storyTargets)
    }
    
   
    public var body: some View {
        
        AmityView(configId: configId,
                  config: { configDict in
        }) { config in
            GeometryReader { geometry in
                Pager(page: page, data: viewModel.storyTargets, id: \.targetId) { storyTarget in
                    ZStack() {
                        
                        StoryCoreView(self, storyTarget: storyTarget,
                                      storySegmentIndex: $storySegmentIndex,
                                      totalDuration: $totalDuration,
                                      moveStoryTarget: { direction in moveStoryTarget(direction: direction) },
                                      moveStorySegment: { direction in moveStorySegment(direction: direction) })
                            .environmentObject(viewModel)
                            .environmentObject(storyCoreViewModel)
                            .environmentObject(host)

                        
                        VStack(alignment: .trailing) {
                            ProgressBarView(pageId: id, progressBarViewModel: progressBarViewModel)
                                .frame(height: 3)
                                .padding(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                                .animation(nil)
                                .onAppear {
                                    Log.add(event: .info, "ProgressBar Appeared")
                                }
                                .onReceive(storyTarget.$storyCount) { count in
                                    Log.add(event: .info, "Story Segment Changed: \(count) - \(storyTarget.targetName)")
                                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: count)
                                    
                                    progressBarViewModel.progressArray = (0..<count).map({ index in
                                        // If a story is deleted and story count is changed, this block will trigger again.
                                        // All segments till storySegmentIndex need to be filled.
                                        if index < storySegmentIndex && storySegmentIndex != 0 {
                                            let model = AmityProgressBarElementViewModel()
                                            model.progress = progressSegmentWidth
                                            return model
                                        }
                                        return AmityProgressBarElementViewModel()
                                    })
                                }
                                .onReceive(storyTarget.$unseenStoryIndex) { index in
                                    if storyTarget.hasUnseenStory  && index != 0 {
                                        storySegmentIndex = index
                                        updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: storyTarget.storyCount)
                                        
                                        progressBarViewModel.progressArray = (0...index).map({ index in
                                            // All segments till storySegmentIndex need to be filled if segment are skipped.
                                            if index < storySegmentIndex && storySegmentIndex != 0 {
                                                let model = AmityProgressBarElementViewModel()
                                                model.progress = progressSegmentWidth
                                                return model
                                            }
                                            return AmityProgressBarElementViewModel()
                                        })
                                    }
                                }

                            HStack(spacing: 0) {
                                let storyCreatorId = viewModel.storyTargets[storyTargetIndex].stories.element(at: storySegmentIndex)?.creatorId
                                let storyTargetId = viewModel.storyTargets[storyTargetIndex].targetId
                                
                                Button {
                                    showBottomSheet.toggle()
                                } label: {
                                    let icon = AmityIcon.getImageResource(named: getElementConfig(elementId: .overflowMenuElement, key: "overflow_menu_icon", of: String.self) ?? "")
                                    Image(icon)
                                        .frame(width: 24, height: 20)
                                        .padding(.trailing, 20)
                                }
                                .onAppear {
                                    Task {
                                        hasStoryManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: storyTargetId)
                                    }
                                }
                                .isHidden(!(hasStoryManagePermission && AmityUIKitManagerInternal.shared.currentUserId == storyCreatorId), remove: false)
                                
                                Button {
                                    Log.add(event: .info, "Tapped Closed!!!")
                                    host.controller?.dismiss(animated: true)
                                } label: {
                                    let icon = AmityIcon.getImageResource(named: getElementConfig(elementId: .closeButtonElement, key: "close_icon", of: String.self) ?? "")
                                    Image(icon)
                                        .frame(width: 24, height: 18)
                                        .padding(.trailing, 25)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .contentLoadingPolicy(.lazy(recyclingRatio: 1))
                .bottomSheet(isPresented: $showBottomSheet, height: 148) {
                    getBottomSheetView()
                }
                .onAppear {
                    page.update(.new(index: storyTargetIndex))
                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: viewModel.storyTargets[storyTargetIndex].stories.count)
                }
                .onDisappear {
                    viewModel.shouldRunTimer =  false
                }
                .onReceive(viewModel.timer, perform: { _ in
                    guard viewModel.shouldRunTimer else { return }
                    timerAction()
                })
                .onChange(of: showBottomSheet) { value in
                    viewModel.shouldRunTimer = !value
                    storyCoreViewModel.playVideo = !value
                }
                .onChange(of: isAlertShown) { value in
                    viewModel.shouldRunTimer = !value
                    storyCoreViewModel.playVideo = !value
                }
                .onChange(of: showToast) { value in
                    Toast.showToast(style: viewModel.toastStyle, message: viewModel.toastMessage)
                }
                .onChange(of: storyTargetIndex) { value in
                    preloadStoryTargets(value, viewModel.storyTargets)
                    storySegmentIndex = 0
                    page.update(.new(index: value))
                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: viewModel.storyTargets[value].stories.count)
                    
                }
                .onChange(of: totalDuration) { value in
                    progressValueToIncrease = progressSegmentWidth / CGFloat(value / 0.001)
                }
                .onChange(of: storySegmentIndex) { _ in

                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
    
    
    @ViewBuilder
    private func getBottomSheetView() -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(AmityIcon.trashBinIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                
                Button {
                    isAlertShown.toggle()
                    showBottomSheet.toggle()
                } label: {
                    Text("Delete story")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.black)
                }
                .buttonStyle(.plain)
                .alert(isPresented: $isAlertShown, content: {
                    Alert(title: Text(AmityLocalizedStringSet.Story.deleteStoryTitle.localizedString), message: Text(AmityLocalizedStringSet.Story.deleteStoryMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                        if let story = viewModel.storyTargets[storyTargetIndex].stories.element(at: storySegmentIndex) {
                            Task { @MainActor in
                                try await viewModel.deleteStory(storyId: story.storyId)
                                storyCoreViewModel.playVideo = false
                                moveStorySegment(direction: .backward)
                                showToast.toggle()
                            }
                        }
                    }))
                })
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            Spacer()
        }
    }
    
    func preloadStoryTargets(_ index: Int, _ storyTargets: [AmityStoryTargetModel]) {
        let nextStoryTargetIndex = index + 1
        let previousStoryTargetIndex = index - 1
        
        storyTargets[index].fetchStory()
        
        if nextStoryTargetIndex <= storyTargets.count - 1 {
            Log.add(event: .info, "Preloaded next index: \(nextStoryTargetIndex)")
            storyTargets[nextStoryTargetIndex].fetchStory()
        }
        
        if previousStoryTargetIndex >= 0 {
            Log.add(event: .info, "Preloaded previous index: \(nextStoryTargetIndex)")
            storyTargets[previousStoryTargetIndex].fetchStory()
        }
    }
    
    
    private func updateProgressSegmentWidth(totalWidth: CGFloat, numberOfStories: Int) {
        progressSegmentWidth = (totalWidth - 37 - (3.0 * CGFloat(numberOfStories))) / CGFloat(numberOfStories)
        progressValueToIncrease = progressSegmentWidth / CGFloat(totalDuration / 0.001)
    }
    
    
    private func timerAction() {
        
        guard storySegmentIndex < progressBarViewModel.progressArray.count else {
            host.controller?.dismiss(animated: true)
            return
        }
        
        if progressBarViewModel.progressArray[storySegmentIndex].progress == progressSegmentWidth {
            
            let lastStoryTargetIndex = viewModel.storyTargets.count - 1
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].stories.count - 1
            
            
            if storySegmentIndex != lastStorySegmentIndex {
                storySegmentIndex += 1
            } else {

                if storyTargetIndex != lastStoryTargetIndex {
                    storyTargetIndex += 1
                } else {
                    host.controller?.dismiss(animated: true)
                }
                
            }
         
        } else {
            let oldProgress = progressBarViewModel.progressArray[storySegmentIndex].progress
            let newProgress = oldProgress + progressValueToIncrease
            progressBarViewModel.progressArray[storySegmentIndex].progress = min(max(oldProgress, newProgress), progressSegmentWidth)
        }
    }
    
    
    func moveStorySegment(direction: MoveDirection) {
        guard storySegmentIndex < progressBarViewModel.progressArray.count else {
            return
        }

        switch direction {
        case .forward:
            progressBarViewModel.progressArray[storySegmentIndex].progress = progressSegmentWidth
            
            let lastStoryTargetIndex = viewModel.storyTargets.count - 1
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].stories.count - 1
            
            if storySegmentIndex != lastStorySegmentIndex {
                storySegmentIndex += 1
            } else if storyTargetIndex == lastStoryTargetIndex && storySegmentIndex == lastStorySegmentIndex {
                host.controller?.dismiss(animated: true)
            }
        
        case .backward:
            progressBarViewModel.progressArray[storySegmentIndex].progress = 0
            
            if storySegmentIndex >= 1 {
                storySegmentIndex -= 1
                progressBarViewModel.progressArray[storySegmentIndex].progress  = 0
            } else if storyTargetIndex >= 1 {
                storyTargetIndex -= 1
            }
        }
    }
    
    
    func moveStoryTarget(direction: MoveDirection) {
        switch direction {
        case .forward:
            guard storyTargetIndex < viewModel.storyTargets.count - 1 else { return }
            storyTargetIndex += 1
        case .backward:
            guard storyTargetIndex > 0 else { return }
            storyTargetIndex -= 1
        }
    }
}

enum MoveDirection {
    case forward, backward
}

class AmityStoryPageViewModel: ObservableObject {
    
    @Published var storyTargets: [AmityStoryTargetModel] = []
    @Published var toastMessage: String = ""
    @Published var toastStyle: ToastStyle = .success
    
    let storyManager = StoryManager()
    let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
    var shouldRunTimer: Bool = false
    
    init(storyTargets: [AmityStoryTargetModel]) {
        self.storyTargets = storyTargets
    }
    
    deinit {
        timer.upstream.connect().cancel()
    }
    
    @MainActor
    func deleteStory(storyId: String) async throws {
        try await storyManager.deleteStory(storyId: storyId)
        toastMessage = AmityLocalizedStringSet.Story.storyDeletedToastMessage.localizedString
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
