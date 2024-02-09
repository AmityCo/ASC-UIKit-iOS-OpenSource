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
    @EnvironmentObject var host: SwiftUIHostWrapper
    
    public var id: PageId {
        .storyPage
    }
    
    let urlImageService = URLImageService(fileStore: URLImageFileStore(), inMemoryStore: URLImageInMemoryStore())
    

    @StateObject var viewModel: AmityStoryPageViewModel
    
    @State private var totalDuration: CGFloat = 4.0
    
    @State private var storyTargetIndex = 0
    @State private var storySegmentIndex: Int = 0
    @State private var progressSegmentWidth: CGFloat = 0.0
    @State private var progressValueToIncrease: CGFloat = 0.0
    @State private var showBottomSheet: Bool = false
    @State private var isAlertShown: Bool = false
    @State private var showToast: Bool = false
    
    // TEMP: Need to implement async/await func later and check to get the correct result
    @State private var hasStoryManagePermission: Bool = StoryPermissionChecker.shared.checkUserHasManagePermission()
    
    @StateObject private var progressBarViewModel: ProgressBarViewModel = ProgressBarViewModel(progressArray: [])
    @StateObject private var storyCoreViewModel: StoryCoreViewModel
        
    public init(storyTargets: [StoryTarget]) {
        _viewModel = StateObject(wrappedValue: AmityStoryPageViewModel(storyTargets: storyTargets))
    
        // TEMP: for image and player caching
        _storyCoreViewModel = StateObject(wrappedValue: StoryCoreViewModel(storyCollection: storyTargets[0].stories))
        
    }
    
   
    public var body: some View {
        
        AmityView(configId: configId,
                  config: { configDict in
        }) { config in
            GeometryReader { geometry in
                TabView(selection: $storyTargetIndex) {
                    ForEach(0..<viewModel.storyTargets.count, id: \.self) { index in
                        let storyTarget = viewModel.storyTargets[index]
                        ZStack() {
                            StoryCoreView(storySegmentIndex: $storySegmentIndex,
                                          totalDuration: $totalDuration,
                                          targetName: storyTarget.targetName,
                                          avatar: storyTarget.avatar ?? AmityIcon.defaultCommunityAvatar.getImage()!, 
                                          isVerified: storyTarget.isVerifiedTarget,
                                          nextStorySegment: {moveStorySegment(direction: .forward)},
                                          previousStorySegment: {moveStorySegment(direction: .backward)})
                                .environmentObject(storyTarget.stories)
                                .environmentObject(viewModel)
                                .environmentObject(storyCoreViewModel)
                                .environmentObject(host)

                            
                            VStack(alignment: .trailing) {
                                ProgressBarView(pageId: id, progressBarViewModel: progressBarViewModel)
                                    .frame(height: 3)
                                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                                    .onAppear {
                                        Log.add(event: .info, "ProgressBar Appeared")
                                    }
                                    .onReceive(storyTarget.stories.$snapshots) { values in
                                        guard values.count != progressBarViewModel.progressArray.count else { return }
                                        
                                        Log.add(event: .info, "ProgressBar Segment Count changed!!!")
                                        
                                        updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: values.count)
                                        
                                        progressBarViewModel.progressArray = (0..<values.count).map({ index in
                                            if index < storySegmentIndex && storySegmentIndex != 0 {
                                                let model = AmityProgressBarElementViewModel()
                                                model.progress = progressSegmentWidth
                                                return model
                                            }
                                            return AmityProgressBarElementViewModel()
                                        })
                                    }

                                HStack(spacing: 0) {
                                    let storyCreatorId = viewModel.storyTargets[storyTargetIndex].stories.object(at: storySegmentIndex)?.creatorId
                                    if let storyCreatorId,
                                        hasStoryManagePermission,
                                        AmityUIKitManagerInternal.shared.currentUserId == storyCreatorId {
                                        Button {
                                            showBottomSheet.toggle()
                                        } label: {
                                            let icon = AmityIcon.getImageResource(named: getElementConfig(elementId: .overflowMenuElement, key: "overflow_menu_icon", of: String.self) ?? "")
                                            Image(icon)
                                                .frame(width: 24, height: 20)
                                                .padding(.trailing, 20)
                                        }
                                    }
                                    
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
                        }.tag(index)
                    }
                }
                .bottomSheet(isPresented: $showBottomSheet, height: 148) {
                    getBottomSheetView()
                }
                .onAppear {
                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: viewModel.storyTargets[storyTargetIndex].stories.count())
                }
                .onDisappear {
                    viewModel.timer.upstream.connect().cancel()
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
                    storySegmentIndex = 0
                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: viewModel.storyTargets[value].stories.count())
                    
                }
                .onChange(of: totalDuration) { value in
                    progressValueToIncrease = progressSegmentWidth / CGFloat(value / 0.001)
                }
                .onChange(of: storySegmentIndex) { _ in

                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .environment(\.urlImageService, urlImageService)
        .environment(\.urlImageOptions, URLImageOptions(loadOptions: [ .loadImmediately ]))
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
                        if let story = viewModel.storyTargets[storyTargetIndex].stories.object(at: storySegmentIndex) {
                            Task { @MainActor in
                                storyCoreViewModel.playVideo = false
                                try await viewModel.deleteStory(storyId: story.storyId)
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
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].stories.count() - 1
            
            
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
    
    
    func moveStorySegment(direction: SegmentMoveDirection) {
        
        guard storySegmentIndex < progressBarViewModel.progressArray.count else {
            return
        }
        
        switch direction {
        case .forward:
            progressBarViewModel.progressArray[storySegmentIndex].progress = progressSegmentWidth
            
            let lastStoryTargetIndex = viewModel.storyTargets.count - 1
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].stories.count() - 1
            
            if storySegmentIndex != lastStorySegmentIndex {
                storySegmentIndex += 1
            } else if storyTargetIndex == lastStoryTargetIndex && storySegmentIndex == lastStorySegmentIndex {
                host.controller?.dismiss(animated: true)
            }
        
        case .backward:
            guard progressBarViewModel.progressArray.count > 1 else {
                return
            }
            
            progressBarViewModel.progressArray[storySegmentIndex].progress = 0
            
            if storySegmentIndex >= 1 {
                storySegmentIndex -= 1
                progressBarViewModel.progressArray[storySegmentIndex].progress  = 0
            } else if storyTargetIndex >= 1 {
                storyTargetIndex -= 1
            }
        }
        
    }
    
    
    enum SegmentMoveDirection {
        case forward, backward
    }
}


class AmityStoryPageViewModel: ObservableObject {
    
    @Published var storyTargets: [StoryTarget] = []
    @Published var toastMessage: String = ""
    @Published var toastStyle: ToastStyle = .success
    
    let storyManager = StoryManager()
    let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
    var shouldRunTimer: Bool = true
    
    init(storyTargets: [StoryTarget]) {
        self.storyTargets = storyTargets
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
