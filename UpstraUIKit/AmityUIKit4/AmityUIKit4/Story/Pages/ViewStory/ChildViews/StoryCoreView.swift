//
//  StoryCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/8/23.
//

import SwiftUI
import AmitySDK
import Combine
import AVKit

struct StoryCoreView: View, AmityViewIdentifiable {
    var viewStoryPage: AmityViewStoryPage
    var targetName: String
    var avatar: URL?
    var isVerified: Bool
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @ObservedObject var storyTarget: AmityStoryTargetModel
    @ObservedObject var storyPageViewModel: AmityViewStoryPageViewModel
    @StateObject private var viewModel: StoryCoreViewModel
 
    @State private var muteVideo: Bool = false
    @State private var showRetryAlert: Bool = false
    @State private var showCommentTray: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var isAlertShown: Bool = false
    @StateObject private var page = Page.first()
    @State private var hasStoryManagePermission: Bool = false
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private var isActiveTarget: Bool {
        storyPageViewModel.activeStoryTarget == storyTarget
    }
    
    init(_ viewStoryPage: AmityViewStoryPage,
         storyPageViewModel: AmityViewStoryPageViewModel,
         storyTarget: AmityStoryTargetModel) {
        self.viewStoryPage = viewStoryPage
        self.storyTarget = storyTarget
        self.targetName = storyTarget.targetName
        self.avatar = storyTarget.avatar
        self.isVerified = storyTarget.isVerifiedTarget
       
        self.storyPageViewModel = storyPageViewModel
        self._viewModel = StateObject(wrappedValue: StoryCoreViewModel(storyTarget, storyPageViewModel: storyPageViewModel))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Pager(page: page, data: storyTarget.items, id: \.id) { item in
                getContentView(item)
                    .environmentObject(storyPageViewModel)
                    .environmentObject(viewModel)
            }
            .contentLoadingPolicy(.lazy(recyclingRatio: 1))
            .disableDragging()
            .onPageChanged { segmentIndex in
                viewModel.storySegmentIndex = segmentIndex
                guard isActiveTarget else { return }
                
                viewModel.playIfVideoStory()
                
                // Mark Seen
                if let item = storyTarget.items.element(at: viewModel.storySegmentIndex), case .content(let storyModel) = item.type {
                    storyPageViewModel.markAsSeen(storyModel)
                }
            }
            .onChange(of: viewModel.storySegmentIndex) { segmentIndex in
                guard page.index != segmentIndex else { return }
                page.update(.new(index: segmentIndex))
            }
            
            ProgressBarView(pageId: .storyPage, progressBarViewModel: viewModel.progressBarViewModel)
                .frame(height: 3)
                .padding(EdgeInsets(top: 16, leading: 20, bottom: 10, trailing: 20))
                .onReceive(storyTarget.$itemCount) { count in
                    guard count != viewModel.progressBarViewModel.progressArray.count else { return }
                    viewModel.createProgressBarViewModelProgressArray(count)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        viewModel.updateProgressBarViewModelProgressArray(viewModel.storySegmentIndex)
                    }
                }
                .isHidden(viewConfig.isHidden(elementId: .progressBarElement), remove: false)
        }
        .onChange(of: storyPageViewModel.storyTargetIndex) { targetIndex in
            viewModel.updateProgressBarViewModelProgressArray(viewModel.storySegmentIndex)
            viewModel.stopVideo()
            
            guard isActiveTarget else { return }
            viewModel.storyTarget.fetchStory(totalSeenStoryCount: storyPageViewModel.seenStoryCount)
            viewModel.playIfVideoStory()
            
            // Mark Seen
            if let item = storyTarget.items.element(at: viewModel.storySegmentIndex), case .content(let storyModel) = item.type {
                storyPageViewModel.markAsSeen(storyModel)
            }
        }
        .onReceive(storyTarget.$unseenStoryIndex) { index in
            viewModel.moveToUnseenStory(index)
        }
        .onReceive(storyPageViewModel.timer, perform: { _ in
            guard storyPageViewModel.shouldRunTimer, isActiveTarget else { return }
            guard storyTarget.storyLoadingStatus == .loaded || !storyTarget.items.isEmpty else { return }
            guard viewModel.isLoadedIfVideoStory() else { return }
            
            viewModel.timerAction(host)
        })
        .onChange(of: storyPageViewModel.shouldRunTimer) { shouldRunTimer in
            guard isActiveTarget else { return }
            viewModel.playPauseVideo(shouldRunTimer)
        }
        .onAppear {
            storyTarget.fetchStory()
            checkStoryPermission()
            Log.add(event: .info, "StoryTarget: \(storyTarget.targetName) appeared!!!")
            // Handle the case going back from Community Page
            host.controller?.navigationController?.navigationBar.isHidden = true
        }
        .onDisappear {
            Log.add(event: .info, "StoryTarget: index \(storyTarget.targetName) disappeared!!!")
        }
        .onChange(of: showBottomSheet) { value in
            storyPageViewModel.debounceUpdateShouldRunTimer(!value)
        }
        .onChange(of: isAlertShown) { value in
            storyPageViewModel.debounceUpdateShouldRunTimer(!value)
        }
        .onChange(of: showRetryAlert) { value in
            storyPageViewModel.debounceUpdateShouldRunTimer(!value)
        }
        .onChange(of: showCommentTray) { value in
            storyPageViewModel.debounceUpdateShouldRunTimer(!value)
            
            if value == false {
                hideKeyboard()
            }
        }
        .padding(.bottom, 25)
        .sheet(isPresented: $showCommentTray) {
            getCommentSheetView()
        }
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, sheetContent: {
            getBottomSheetView()
        })
        .environmentObject(viewConfig)
        .environmentObject(host)
        .animation(nil)
    }
    
    @ViewBuilder
    func getContentView(_ item: PaginatedItem<AmityStoryModel>) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                
                switch item.type {
                case .ad(let ad):
                    StoryAdView(ad: ad, gestureView: getGestureView)
                case .content(let storyModel):
                    getStoryView(storyModel)
                }
                
                HStack(spacing: 0) {
                    /// Show overflow menu if item is the story
                    /// Hide it if item is ads
                    if case .content(_) = item.type {
                        Button {
                            showBottomSheet.toggle()
                        } label: {
                            let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .overflowMenuElement, key: "overflow_menu_icon", of: String.self) ?? "")
                            Image(icon)
                                .frame(width: 24, height: 20)
                                .padding(.trailing, 20)
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
                .padding(.top, 40)
            }
        }
    }
    
    
    func getStoryView(_ storyModel: AmityStoryModel) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                GeometryReader { geometry in
                    if let imageURL = storyModel.imageURL {
                        StoryImageView(imageURL: imageURL,
                                       displayMode: storyModel.imageDisplayMode,
                                       size: geometry.size,
                                       onLoading: {
                            guard isActiveTarget else { return }
                            storyPageViewModel.shouldRunTimer = false
                            storyPageViewModel.showActivityIndicator = true
                        }, onLoaded: {
                            guard isActiveTarget else { return }
                            storyPageViewModel.shouldRunTimer = true
                            storyPageViewModel.showActivityIndicator = false
                        })
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            storyModel.syncState == .error || storyModel.syncState == .syncing ? Color.black.opacity(0.5) : nil
                        )
                    } else if let videoURL = storyModel.videoURL {
                        StoryVideoView(videoURL: videoURL,
                                       muteVideo: $muteVideo,
                                       time: $viewModel.playTime,
                                       playVideo: $viewModel.playVideo, onLoading: {
                            guard isActiveTarget else { return }
                            viewModel.isVideoLoading = true
                            storyPageViewModel.showActivityIndicator = true
                        }, onPlaying: { videoDuration in
                            guard isActiveTarget else { return }
                            viewModel.isVideoLoading = false
                            storyPageViewModel.shouldRunTimer = true
                            storyPageViewModel.showActivityIndicator = false
                            storyPageViewModel.totalDuration = videoDuration
                        })
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            storyModel.syncState == .error || storyModel.syncState == .syncing ? Color.black.opacity(0.5) : nil
                        )
                    }
                }
                
                getGestureView()
                
                getMuteButton()
                    .offset(x: 16, y: 98)
                    .isHidden(storyModel.storyType != .video)
                    .isHidden(viewConfig.isHidden(elementId: .muteUnmuteButtonElement))
                
                VStack(alignment: .center) {
                    getMetadataView(targetName: targetName,
                                    avatar: avatar,
                                    isVerified: isVerified,
                                    story: storyModel)
                    Spacer()
                    
                    if let firstItem = storyModel.storyItems.first, let hyperlinkItem = firstItem as? AmityHyperLinkItem {
                        let data = hyperlinkItem.getData()
                        let model = HyperLinkModel(url: data["url"] as? String ?? "", urlName: data["customText"] as? String ?? "")
                        getHyperLinkView(data: model, story: storyModel)
                    }
                }
                .padding(.top, 30)
            }
            
            if storyModel.syncState == .error {
                getFailedStoryBanner(storyModel)

            } else if storyModel.syncState == .syncing {
                getSyncingStoryBanner()
            } else {
                getAnalyticView(storyModel)
            }
        }
        .environmentObject(viewModel)
    }
    
    
    func getMetadataView(targetName: String, avatar: URL?, isVerified: Bool, story: AmityStoryModel) -> some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: avatar)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .padding(.leading, 16)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.communityAvatar)
                
                AmityCreateNewStoryButtonElement(componentId: .storyTabComponent)
                    .frame(width: 16.0, height: 16.0)
                    .isHidden(!hasStoryManagePermission)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.createStoryIcon)
                    .isHidden(viewConfig.isHidden(elementId: .createNewStoryButtonElement), remove: false)
            }
            .onTapGesture {
                if hasStoryManagePermission {
                    let context = AmityViewStoryPageBehaviour.Context(page: viewStoryPage, targetId: storyTarget.targetId, targetType: .community)
                    AmityUIKit4Manager.behaviour.viewStoryPageBehaviour?.goToCreateStoryPage(context: context)
                }
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(targetName)
                        .applyTextStyle(.bodyBold(.white))
                        .frame(height: 20)
                        .onTapGesture {
                            guard let community = story.community else { return }
                            let context = AmityViewStoryPageBehaviour.Context(page: viewStoryPage, targetId: community.communityId, targetType: .community)
                            AmityUIKit4Manager.behaviour.viewStoryPageBehaviour?.goToCommunityPage(context: context)
                        }
                        .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.communityDisplayNameTextView)
                    
                    Image(AmityIcon.verifiedWhiteBadge.getImageResource())
                        .resizable()
                        .frame(width: 20, height: 20)
                        .offset(x: -5)
                        .isHidden(!isVerified)
                    
                    Spacer(minLength: 80)
                }
                HStack {
                    Text(story.createdAt.timeAgoString)
                        .applyTextStyle(.caption(.white))
                        .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.createdAtTextView)
                    Text("•")
                        .applyTextStyle(.caption(.white))
                    Text("By \(story.creatorName)")
                        .applyTextStyle(.caption(.white))
                        .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.creatorDisplayNameTextView)
                }
                
            }
            
            Spacer()
        }
    }
    
    func getMuteButton() -> some View {
        let muteIcon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "mute_icon", of: String.self) ?? "")
        let unmuteIcon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "unmute_icon", of: String.self) ?? "")
        let color = Color(UIColor(hex: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "background_color", of: String.self) ?? ""))
        return Image(muteVideo ? muteIcon
              : unmuteIcon)
        .frame(width: 32, height: 32)
        .background(color)
        .clipShape(.circle)
        .onTapGesture {
            muteVideo.toggle()
        }
        .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.muteButton)
    }
    
    
    func getHyperLinkView(data: HyperLinkModel, story: AmityStoryModel) -> some View {
        HStack(spacing: 0) {
            Image(AmityIcon.hyperLinkBlueIcon.getImageResource())
                .frame(width: 20, height: 20)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
            
            let title = data.getCustomName().isEmpty ? data.getDomainName() ?? "" : data.getCustomName()
            Text(title)
                .applyTextStyle(.body(Color(viewConfig.defaultLightTheme.baseColor)))
                .lineLimit(1)
                .padding(.trailing, 16)
                .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.hyperlinkTextView)
        }
        .frame(height: 40)
        .background(Color(UIColor(hex: "#EBECEF")).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(EdgeInsets(top: 0, leading: 24, bottom: 62, trailing: 24))
        .onTapGesture {
            story.analytics.markLinkAsClicked()
            
            guard let url = URLHelper.concatProtocolIfNeeded(urlStr: data.url) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.hyperlinkView)
    }
    
    
    func getGestureView() -> some View {
        GestureView(onLeftTap: {
            viewModel.moveStorySegment(direction: .backward, host)
        }, onRightTap: {
            viewModel.moveStorySegment(direction: .forward, host)
        }, onTouchAndHoldStart: {
            storyPageViewModel.shouldRunTimer = false
        }, onTouchAndHoldEnd: {
            storyPageViewModel.shouldRunTimer = true
        }, onDragChanged: { direction, translation in
            guard let view = host.controller?.view else { return }
            guard direction == .downward || direction == .upward else { return }
            
            if translation.y < 0 || (translation.y > 0 && translation.y <= 50) { return }
            
            storyPageViewModel.debounceUpdateShouldRunTimer(false)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            })
            
        }, onDragEnded: { direction, translation in
            guard let view = host.controller?.view else { return }
            guard direction == .downward || direction == .upward else { return }
            
            storyPageViewModel.debounceUpdateShouldRunTimer(true)
            
            if translation.y <= 200 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    if view.transform == .identity && direction == .upward  && translation.y < -100 {
                        showCommentTray = true
                    }
                    
                    view.transform = .identity
                })
            } else {
                host.controller?.dismiss(animated: true)
            }
        })
    }
    
    
    func getAnalyticView(_ story: AmityStoryModel) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Label {
                Text("\(story.viewCount)")
                    .applyTextStyle(.body(.white))
                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.reachButtonTextView)
            } icon: {
                let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .impressionIconElement, key: "impression_icon", of: String.self) ?? "")
                Image(icon)
                    .frame(width: 20, height: 16)
                    .padding(.trailing, -4)
            }
            .foregroundColor(.white)
            .isHidden(!(story.isModerator || story.isCreator))
            .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.reachButton)
            .isHidden(viewConfig.isHidden(elementId: .impressionIconElement), remove: false)
            
            Spacer()
            
            let commentBtnBgColor = Color(UIColor(hex: viewConfig.getConfig(elementId: .storyCommentButtonElement, key: "background_color", of: String.self) ?? "#FFFFFF"))
            HStack(spacing: 0) {
                let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .storyCommentButtonElement, key: "comment_icon", of: String.self) ?? "")
                Image(icon)
                    .frame(width: 20, height: 16)
                    .padding(.leading, 10)
                    .padding(.trailing, 4)
                Text(story.commentCount.formattedCountString)
                    .lineLimit(1)
                    .font(AmityTextStyle.body(.clear).getFont().monospacedDigit())
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.commentButtonTextView)
            }
            .frame(minWidth: 56)
            .frame(height: 40)
            .fixedSize()
            .background(commentBtnBgColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture {
                ImpactFeedbackGenerator.impactFeedback(style: .light)
                showCommentTray.toggle()
            }
            .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.commentButton)
            .isHidden(viewConfig.isHidden(elementId: .storyCommentButtonElement))
            
            let isCommunityMember = story.storyTarget?.community?.isJoined ?? true
            let reactionBtnBgColor = Color(UIColor(hex: viewConfig.getConfig(elementId: .storyReactionButtonElement, key: "background_color", of: String.self) ?? ""))
            HStack(spacing: 0) {
                let icon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .storyReactionButtonElement, key: "reaction_icon", of: String.self) ?? "")
                let likedIcon = AmityIcon.likeReactionIcon.getImageResource()
                Image(story.isLiked ? likedIcon : icon)
                    .frame(width: 20, height: 16)
                    .padding(.leading, 10)
                    .padding(.trailing, 4)
                Text(story.reactionCount.formattedCountString)
                    .lineLimit(1)
                    .font(AmityTextStyle.body(.clear).getFont().monospacedDigit())
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
                    .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.reactionButtonTextView)
            }
            .frame(minWidth: 56)
            .frame(height: 40)
            .fixedSize()
            .background(reactionBtnBgColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture {
                guard isCommunityMember else {
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Story.nonMemberReactStoryMessage.localizedString)
                    return
                }
                
                ImpactFeedbackGenerator.impactFeedback(style: .light)
                
                Task {
                    if story.isLiked {
                        try await viewModel.removeReaction(storyId: story.storyId)
                    } else {
                        try await viewModel.addReaction(storyId: story.storyId)
                    }
                }
            }
            .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.reactionButton)
            .isHidden(viewConfig.isHidden(elementId: .storyReactionButtonElement))
        }
        .frame(height: 56)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 25, trailing: 12))
        .background(Color.black)
    }
    
    
    func getFailedStoryBanner(_ storyModel: AmityStoryModel) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Image(AmityIcon.statusWarningIcon.getImageResource())
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8))
            Text(AmityLocalizedStringSet.Story.failedStoryBannerMessage.localizedString)
                .applyTextStyle(.body(.white))
            Spacer()
            Button(action: {
                showRetryAlert.toggle()
                
                let alertViewController = UIAlertController(title: AmityLocalizedStringSet.Story.failedStoryAlertTitle.localizedString,
                                                            message: AmityLocalizedStringSet.Story.failedStoryAlertMessage.localizedString, preferredStyle: .alert)
                
                let retryAction = UIAlertAction(title: AmityLocalizedStringSet.General.retry.localizedString, style: .default, handler: {_ in
                    Task {
                        do {
                            try await viewModel.storyManager.deleteStory(storyId: storyModel.storyId)
                            
                            switch storyModel.storyType {
                            case .image:
                                if let storyTarget = storyModel.storyTarget, let url = storyModel.imageURL {
                                    let targetType: AmityStoryTargetType = AmityStoryTargetType(rawValue: storyTarget.targetType) ?? .community
                                    let createOptions = AmityImageStoryCreateOptions(targetType: targetType, tartgetId: storyTarget.targetId, imageFileURL: url, items: storyModel.storyItems)
                                    
                                    try await viewModel.storyManager.createImageStory(in: storyTarget.targetId, createOption: createOptions)
                                }
                                
                            case .video:
                                if let storyTarget = storyModel.storyTarget, let url = storyModel.videoURL {
                                    let targetType: AmityStoryTargetType = AmityStoryTargetType(rawValue: storyTarget.targetType) ?? .community
                                    let createOptions = AmityVideoStoryCreateOptions(targetType: targetType, tartgetId: storyTarget.targetId, videoFileURL: url, items: storyModel.storyItems)
                                    
                                    try await viewModel.storyManager.createVideoStory(in: storyTarget.targetId, createOption: createOptions)
                                }
                                
                            }
                        } catch {
                            Toast.showToast(style: .warning, message: error.localizedDescription)
                        }
                    }
                    showRetryAlert.toggle()
                })
                
                let discardAction = UIAlertAction(title: AmityLocalizedStringSet.General.discard.localizedString, style: .destructive, handler: {_ in
                    let alertViewController = UIAlertController(title: AmityLocalizedStringSet.Story.deleteStoryTitle.localizedString, message: AmityLocalizedStringSet.Story.deleteStoryMessage.localizedString, preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .default) { _ in
                        showRetryAlert.toggle()
                    }
                    
                    let deleteAction = UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive) { _ in
                        Task {
                            try await viewModel.storyManager.deleteStory(storyId: storyModel.storyId)
                        }
                        showRetryAlert.toggle()
                    }
                    
                    alertViewController.addAction(cancelAction)
                    alertViewController.addAction(deleteAction)
                    host.controller?.present(alertViewController, animated: true)
                })
                
                let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .default, handler: {_ in
                    showRetryAlert.toggle()
                })
                
                alertViewController.addAction(retryAction)
                alertViewController.addAction(discardAction)
                alertViewController.addAction(cancelAction)
                
                host.controller?.present(alertViewController, animated: true)
            }, label: {
                Image(AmityIcon.threeDotIcon.getImageResource())
                    .padding(.trailing, 16)
            })
        }
        .frame(height: 44)
        .background(Color.red)
        .padding(.bottom, 37)
    }
    
    
    func getSyncingStoryBanner() -> some View {
        HStack(alignment: .center, spacing: 0) {
            CircularProgressView()
                .frame(width: 15, height: 15)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8))
            Text(AmityLocalizedStringSet.Story.creatingStory.localizedString)
                .applyTextStyle(.body(.white))
            Spacer()
        }
        .frame(height: 44)
        .background(Color.black)
        .padding(.bottom, 37)
    }
    
    
    
    @ViewBuilder
    func getCommentSheetView() -> some View {
        if #available(iOS 16.0, *) {
            getCommentSheetContentView()
            .presentationDetents([.fraction(0.75)])
        } else {
            getCommentSheetContentView()
        }
    }
    
    
    @ViewBuilder
    func getCommentSheetContentView() -> some View {
        if let item = storyTarget.items.element(at: viewModel.storySegmentIndex),
           case let .content(story) = item.type {
            let isCommunityMember = story.storyTarget?.community?.isJoined ?? true
            let allowCreateComment = story.storyTarget?.community?.storySettings.allowComment ?? false
            
            AmityCommentTrayComponent(referenceId: story.storyId,
                                      referenceType: .story,
                                      community: story.storyTarget?.community,
                                      shouldAllowInteraction: isCommunityMember,
                                      shouldAllowCreation: allowCreateComment)
        }
    }
    
    
    @ViewBuilder
    private func getBottomSheetView() -> some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: AmityIcon.trashBinIcon.getImageResource(), text: "Delete story", isDestructive: true)
                .onTapGesture {
                    let alertController = UIAlertController(title: AmityLocalizedStringSet.Story.deleteStoryTitle.localizedString, message: AmityLocalizedStringSet.Story.deleteStoryMessage.localizedString, preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel) { _ in
                        isAlertShown.toggle()
                    }
                    
                    let deleteAction = UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive) { _ in
                        isAlertShown.toggle()
                        if let item = storyTarget.items.element(at: viewModel.storySegmentIndex),
                            case let .content(story) = item.type {
                            Task { @MainActor in
                                try await viewModel.deleteStory(storyId: story.storyId, host)
                                Toast.showToast(style: .success, message: "Successfully deleted the story.")
                            }
                        }
                    }
                    
                    alertController.addAction(cancelAction)
                    alertController.addAction(deleteAction)
                    
                    showBottomSheet.toggle()
                    isAlertShown.toggle()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        host.controller?.present(alertController, animated: true)
                    }
                }
        }
        .padding(.bottom, 32)
    }
    
    private func checkStoryPermission() {
        // Check StoryManage Permission
        Task {
            let storyTargetId = storyTarget.targetId
            let hasPermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: storyTargetId)
            let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
            
            guard let community = storyTarget.storyTarget?.community else {
                hasStoryManagePermission = false
                return
            }
            
            hasStoryManagePermission = (allowAllUserCreation || hasPermission) && community.isJoined
        }
    }
}
