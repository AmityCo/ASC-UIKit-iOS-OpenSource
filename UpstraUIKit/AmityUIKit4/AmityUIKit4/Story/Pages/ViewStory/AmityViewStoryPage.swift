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

let STORY_DURATION: CGFloat = 4.0

public enum AmityViewStoryPageType {
      case communityFeed(String)
      // User can start viewing any specific story target in Global Feed.
      // It will be the communityId of story target that user clicked on AmityStoryTabComponent
      // in our UI flow.
      case globalFeed(String)
}

public struct AmityViewStoryPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .storyPage
    }

    @StateObject var viewModel: AmityStoryPageViewModel
    
    @State private var totalDuration: CGFloat = STORY_DURATION
    
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
        
    private let storyPageType: AmityViewStoryPageType
    
    @State private var page: Page = Page.first()
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(type: AmityViewStoryPageType) {
        self.storyPageType = type
        _viewModel = StateObject(wrappedValue: AmityStoryPageViewModel(type: type))
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .storyPage))
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
                                .onReceive(storyTarget.$itemCount) { count in                                    
                                    Log.add(event: .info, "Story Segment Changed: \(count) - \(storyTarget.targetName)")
                                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: count)
                                    
                                    if storyTarget.hasUnseenStory {
                                        storySegmentIndex = storyTarget.unseenStoryIndex
                                    }
                                    
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
                                .isHidden(viewConfig.isHidden(elementId: .progressBarElement), remove: false)

                            HStack(spacing: 0) {
                                /// Show overflow menu if item is the story
                                /// Hide it if item is ads
                                if let item = viewModel.storyTargets[storyTargetIndex].items.element(at: storySegmentIndex),
                                   case let .content(_) = item.type {
                                    Button {
                                        showBottomSheet.toggle()
                                    } label: {
                                        let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .overflowMenuElement, key: "overflow_menu_icon", of: String.self) ?? "")
                                        Image(icon)
                                            .frame(width: 24, height: 20)
                                            .padding(.trailing, 20)
                                    }
                                    .onAppear {
                                        Task {
                                            let storyTargetId = viewModel.storyTargets[storyTargetIndex].targetId
                                            hasStoryManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: storyTargetId)
                                        }
                                    }
                                    .isHidden(!hasStoryManagePermission, remove: false)
                                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.meatballsButton)
                                    .isHidden(viewConfig.isHidden(elementId: .overflowMenuElement), remove: false)
                                }
                                
                                Button {
                                    Log.add(event: .info, "Tapped Closed!!!")
                                    host.controller?.dismiss(animated: true)
                                } label: {
                                    let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .closeButtonElement, key: "close_icon", of: String.self) ?? "")
                                    Image(icon)
                                        .frame(width: 24, height: 18)
                                        .padding(.trailing, 25)
                                }
                                .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.closeButton)
                                .isHidden(viewConfig.isHidden(elementId: .closeButtonElement), remove: false)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .contentLoadingPolicy(.lazy(recyclingRatio: 1))
                .bottomSheet(isPresented: $showBottomSheet, height: 148, topBarBackgroundColor: Color(viewConfig.theme.backgroundColor), animation: .easeIn(duration: 0.1)) {
                    getBottomSheetView()
                }
                .onAppear {
                    page.update(.new(index: storyTargetIndex))
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
                    Toast.showToast(style: viewModel.toastStyle, message: viewModel.toastMessage, bottomPadding: 70)
                }
                .onReceive(viewModel.$storyTargets) { value in
                    if case .globalFeed(let communityId) = storyPageType {
                        storyTargetIndex = value.firstIndex { $0.targetId == communityId } ?? 0
                    }
                }
                .onChange(of: storyTargetIndex) { value in
                    viewModel.preloadStoryTargets(value, viewModel.storyTargets)
                    storySegmentIndex = 0
                    page.update(.new(index: value))
                    updateProgressSegmentWidth(totalWidth: geometry.size.width, numberOfStories: viewModel.storyTargets[value].items.count)
                    
                }
                .onChange(of: totalDuration) { value in
                    progressValueToIncrease = progressSegmentWidth / CGFloat(value / 0.001)
                }
                .onChange(of: storySegmentIndex) { _ in

                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .environmentObject(viewConfig)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }
    
    
    @ViewBuilder
    private func getBottomSheetView() -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(AmityIcon.trashBinIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Button {
                    isAlertShown.toggle()
                    showBottomSheet.toggle()
                } label: {
                    Text("Delete story")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }
                .buttonStyle(.plain)
                .alert(isPresented: $isAlertShown, content: {
                    Alert(title: Text(AmityLocalizedStringSet.Story.deleteStoryTitle.localizedString), message: Text(AmityLocalizedStringSet.Story.deleteStoryMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                        if let item = viewModel.storyTargets[storyTargetIndex].items.element(at: storySegmentIndex),
                            case let .content(story) = item.type {
                            Task { @MainActor in
                                try await viewModel.deleteStory(storyId: story.storyId)
                                storyCoreViewModel.playVideo = false
                                moveStorySegment(direction: .backward)
                                showToast.toggle()
                            }
                        }
                    }))
                })
                .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.BottomSheet.deleteButton)
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
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
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].items.count - 1
            
            
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
            let lastStorySegmentIndex = viewModel.storyTargets[storyTargetIndex].items.count - 1
            
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
    private var seenStoryCount: Int = 0
    
    private var cancellable: AnyCancellable?
    private var storyTargetObject: AmityObject<AmityStoryTarget>?
    private var storyTargetCollection: AmityCollection<AmityStoryTarget>?
    private var seenStoryModels: Set<AmityStoryModel> = Set()
    
    let storyManager = StoryManager()
    let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
    var shouldRunTimer: Bool = false
    
    init(type: AmityViewStoryPageType) {
        
        switch type {
        case .communityFeed(let communityId):
            storyTargetObject = storyManager.getStoryTarget(targetType: .community, targetId: communityId)
            cancellable = nil
            cancellable = storyTargetObject?.$snapshot
                .first { [weak self] _ in
                    self?.storyTargetObject?.dataStatus == .fresh
                }
                .sink { [weak self] target in
                    guard let target else { return }
                    
                    let storyTarget = AmityStoryTargetModel(target)
                    storyTarget.fetchStory()
                    
                    self?.storyTargets = [storyTarget]
                }
            
        case .globalFeed(let communityId):
            storyTargetCollection = storyManager.getGlobaFeedStoryTargets(options: .smart)
            cancellable = nil
            cancellable = storyTargetCollection?.$snapshots
                .first { !$0.isEmpty }
                .sink { [weak self] targets in
                    let storyTargets = targets.compactMap { target -> AmityStoryTargetModel? in
                        return AmityStoryTargetModel(target)
                    }.removeDuplicates()
                    self?.preloadStoryTargets(storyTargets.firstIndex { $0.targetId == communityId } ?? 0, storyTargets)
                    
                    self?.storyTargets = storyTargets
                }
        }
    }
    
    deinit {
        seenStoryModels.forEach { $0.analytics.markAsSeen() }
        timer.upstream.connect().cancel()
        URLImageService.defaultImageService.inMemoryStore?.removeAllImages()
    }
    
    func preloadStoryTargets(_ index: Int, _ storyTargets: [AmityStoryTargetModel]) {
        let nextStoryTargetIndex = index + 1
        let previousStoryTargetIndex = index - 1
        
        if index <= storyTargets.count - 1 {
            storyTargets[index].fetchStory(totalSeenStoryCount: seenStoryCount)
        }
        
        if nextStoryTargetIndex <= storyTargets.count - 1 {
            Log.add(event: .info, "Preloaded next index: \(nextStoryTargetIndex)")
            storyTargets[nextStoryTargetIndex].fetchStory(totalSeenStoryCount: seenStoryCount)
        }
        
        if previousStoryTargetIndex >= 0 {
            Log.add(event: .info, "Preloaded previous index: \(previousStoryTargetIndex)")
            storyTargets[previousStoryTargetIndex].fetchStory(totalSeenStoryCount: seenStoryCount)
        }
    }
    
    func markAsSeen(_ storyModel: AmityStoryModel) {
        seenStoryModels.insert(storyModel)
        seenStoryCount += 1
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
