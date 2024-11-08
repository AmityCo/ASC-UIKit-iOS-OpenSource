//
//  StoryCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/8/23.
//

import SwiftUI
import AVKit
import AmitySDK
import Combine

struct StoryCoreView: View, AmityViewIdentifiable {
    var viewStoryPage: AmityViewStoryPage
    var targetName: String
    var avatar: URL?
    var isVerified: Bool
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @ObservedObject var storyTarget: AmityStoryTargetModel
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    @EnvironmentObject var storyCoreViewModel: StoryCoreViewModel
    
    @Binding var storySegmentIndex: Int
    @Binding var totalDuration: CGFloat
    @State private var muteVideo: Bool = false
    @State private var showRetryAlert: Bool = false
    @State private var showCommentTray: Bool = false
    
    @State private var hasStoryManagePermission: Bool = false
    
    var moveStoryTarget: ((MoveDirection) -> Void)?
    var moveStorySegment: ((MoveDirection) -> Void)?
    
    @State private var page: Page = Page.first()
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    init(_ viewStoryPage: AmityViewStoryPage, storyTarget: AmityStoryTargetModel,
         storySegmentIndex: Binding<Int>,
         totalDuration: Binding<CGFloat>,
         moveStoryTarget: ((MoveDirection) -> Void)? = nil,
         moveStorySegment: ((MoveDirection) -> Void)? = nil) {
        self.viewStoryPage = viewStoryPage
        self.storyTarget = storyTarget
        self._storySegmentIndex = storySegmentIndex
        self._totalDuration = totalDuration
        self.targetName = storyTarget.targetName
        self.avatar = storyTarget.avatar
        self.isVerified = storyTarget.isVerifiedTarget
        self.moveStoryTarget = moveStoryTarget
        self.moveStorySegment = moveStorySegment
    }
    
    var body: some View {
        Pager(page: page, data: storyTarget.items, id: \.id) { item in
            switch item.type {
            case .ad(let ad):
                StoryAdView(ad: ad, gestureView: getGestureView)
            case .content(let storyModel):
                getStoryView(storyModel)
            }
        }
        .contentLoadingPolicy(.lazy(recyclingRatio: 1))
        .overlay (
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                .offset(y: -40)
                .isHidden(storyTarget.items.count != 0, remove: false)
        )
        .onAppear {
            page.update(.new(index: storySegmentIndex))
            
            // Handle the case going back from Community Page
            host.controller?.navigationController?.navigationBar.isHidden = true
        }
        .onChange(of: storySegmentIndex) { value in
            page.update(.new(index: value))
        }
        .onChange(of: showRetryAlert) { value in
            storyPageViewModel.shouldRunTimer = !value
            storyCoreViewModel.playVideo = !value
        }
        .onChange(of: showCommentTray) { value in
            storyPageViewModel.shouldRunTimer = !value
            storyCoreViewModel.playVideo = !value
            
            if value == false {
                hideKeyboard()
            }
        }
        .sheet(isPresented: $showCommentTray) {
            getCommentSheetView()
        }
        .gesture(DragGesture().onChanged{ _ in})
        .environmentObject(viewConfig)
        .environmentObject(host)
        .animation(nil)
    }
    
    
    func getStoryView(_ storyModel: AmityStoryModel) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                GeometryReader { geometry in
                    if let imageURL = storyModel.imageURL {
                        StoryImageView(imageURL: imageURL,
                                  totalDuration: $totalDuration,
                                  displayMode: storyModel.imageDisplayMode,
                                  size: geometry.size)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            storyModel.syncState == .error || storyModel.syncState == .syncing ? Color.black.opacity(0.5) : nil
                        )
                    } else if let videoURL = storyModel.videoURL {
                        StoryVideoView(videoURL: videoURL,
                                  totalDuration: $totalDuration,
                                  muteVideo: $muteVideo,
                                  playVideo: $storyCoreViewModel.playVideo)
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
                .offset(y: 30) // height + padding top, bottom of progressBarView
                
                
            }
            
            if storyModel.syncState == .error {
                getFailedStoryBanner(storyModel)

            } else if storyModel.syncState == .syncing {
                getSyncingStoryBanner()
            } else {
                getAnalyticView(storyModel)
            }
        }
        .onAppear {
            storyPageViewModel.markAsSeen(storyModel)
            
            switch storyModel.storyType {
            case .image:
                storyCoreViewModel.playVideo = false
            case .video:
                storyCoreViewModel.playVideo = true
            }
        }
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
            .onAppear {
                Task {
                    hasStoryManagePermission = await StoryPermissionChecker.checkUserHasManagePermission(communityId: story.targetId)
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
            moveStorySegment?(.backward)
        }, onRightTap: {
            moveStorySegment?(.forward)
        }, onTouchAndHoldStart: {
            storyPageViewModel.shouldRunTimer = false
            storyCoreViewModel.playVideo = false
        }, onTouchAndHoldEnd: {
            storyPageViewModel.shouldRunTimer = true
            storyCoreViewModel.playVideo = true
        },onDragChanged: { direction, translation in
            guard let view = host.controller?.view else { return }
            
            if translation.y < 0 || (translation.y > 0 && translation.y <= 50) { return }
            
            storyPageViewModel.shouldRunTimer = false
            storyCoreViewModel.playVideo = false
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            })
            
        }, onDragEnded: { direction, translation in
            guard let view = host.controller?.view else { return }
            
            storyPageViewModel.shouldRunTimer = true
            storyCoreViewModel.playVideo = true
            
            if translation.y <= 200 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    if view.transform == .identity && direction == .upward {
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
                        try await storyPageViewModel.removeReaction(storyId: story.storyId)
                    } else {
                        try await storyPageViewModel.addReaction(storyId: story.storyId)
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
                            try await storyCoreViewModel.storyManager.deleteStory(storyId: storyModel.storyId)
                            
                            switch storyModel.storyType {
                            case .image:
                                if let storyTarget = storyModel.storyTarget, let url = storyModel.imageURL {
                                    let targetType: AmityStoryTargetType = AmityStoryTargetType(rawValue: storyTarget.targetType) ?? .community
                                    let createOptions = AmityImageStoryCreateOptions(targetType: targetType, tartgetId: storyTarget.targetId, imageFileURL: url, items: storyModel.storyItems)
                                    
                                    try await storyCoreViewModel.storyManager.createImageStory(in: storyTarget.targetId, createOption: createOptions)
                                }
                                
                            case .video:
                                if let storyTarget = storyModel.storyTarget, let url = storyModel.videoURL {
                                    let targetType: AmityStoryTargetType = AmityStoryTargetType(rawValue: storyTarget.targetType) ?? .community
                                    let createOptions = AmityVideoStoryCreateOptions(targetType: targetType, tartgetId: storyTarget.targetId, videoFileURL: url, items: storyModel.storyItems)
                                    
                                    try await storyCoreViewModel.storyManager.createVideoStory(in: storyTarget.targetId, createOption: createOptions)
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
                            try await storyCoreViewModel.storyManager.deleteStory(storyId: storyModel.storyId)
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
        if let item = storyTarget.items.element(at: storySegmentIndex),
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
}


class StoryCoreViewModel: ObservableObject {
    
    @Published var playVideo: Bool = true
    let storyManager = StoryManager()
    
    init() {}
}

struct StoryImageView: View {
    
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    
    private let imageURL: URL
    private let displayMode: ContentMode
    private let size: CGSize
    @Binding private var totalDuration: CGFloat
    
    init(imageURL: URL, totalDuration: Binding<CGFloat>, displayMode: ContentMode, size: CGSize) {
        self.imageURL = imageURL
        self._totalDuration = totalDuration
        self.displayMode = displayMode
        self.size = size
    }
    
    var body: some View {
        URLImage(imageURL) { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                .onAppear {
                    storyPageViewModel.shouldRunTimer = false
                }
            
        } content: { image, imageInfo in
            image
                .resizable()
                .aspectRatio(contentMode: displayMode)
                .frame(width: size.width, height: size.height)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: UIImage(cgImage: imageInfo.cgImage).averageGradientColor ?? [.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .onAppear {
                    storyPageViewModel.shouldRunTimer = true
                }
                .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.storyImageView)
        }
        .environment(\.urlImageOptions, URLImageOptions.amityOptions)
        .onAppear {
            totalDuration = STORY_DURATION
            Log.add(event: .info, "Story TotalDuration: \(totalDuration)")
        }
    }
}

struct StoryVideoView: View {
    
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    @EnvironmentObject var storyCoreViewModel: StoryCoreViewModel
    
    private let videoURL: URL
    @Binding var totalDuration: CGFloat
    @Binding var muteVideo: Bool
    @Binding var playVideo: Bool
    
    @State private var showActivityIndicator: Bool = false
    @State private var time: CMTime = .zero
    
    init(videoURL: URL, totalDuration: Binding<CGFloat>, muteVideo: Binding<Bool>, playVideo: Binding<Bool>) {
        self.videoURL = videoURL
        self._totalDuration = totalDuration
        self._muteVideo = muteVideo
        self._playVideo = playVideo
    }
    
    var body: some View {
        VideoPlayer(url: videoURL, play: $playVideo, time: $time)
            .autoReplay(false)
            .mute(muteVideo)
            .contentMode(.scaleAspectFit)
            .onStateChanged({ state in
                switch state {
                case .loading:
                    storyPageViewModel.shouldRunTimer = false
                    showActivityIndicator = true
                case .playing(totalDuration: let totalDuration):
                    storyPageViewModel.shouldRunTimer = true
                    self.totalDuration = totalDuration
                    showActivityIndicator = false
                    Log.add(event: .info, "Story TotalDuration: \(totalDuration)")
                case .paused(playProgress: _, bufferProgress: _): break
                case .error(_): break
                    
                }
            })
            .overlay(
                ActivityIndicatorView(isAnimating: $showActivityIndicator, style: .medium)
            )
            .onAppear {
                time = .zero
                storyPageViewModel.shouldRunTimer = true
            }
            .onDisappear {
            }
            .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.storyVideoView)
    }
}
