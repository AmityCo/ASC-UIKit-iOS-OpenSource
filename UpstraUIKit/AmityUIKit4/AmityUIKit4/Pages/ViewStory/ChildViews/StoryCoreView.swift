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
    var targetName: String
    var avatar: UIImage
    var isVerified: Bool
    
    @EnvironmentObject var host: SwiftUIHostWrapper
    @EnvironmentObject var storyCollection: AmityCollection<AmityStory>
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    @EnvironmentObject var storyCoreViewModel: StoryCoreViewModel
    
    @Binding var storySegmentIndex: Int
    @Binding var totalDuration: CGFloat
    @State private var muteVideo: Bool = false
    @State private var showRetryAlert: Bool = false
    @State private var showCommentTray: Bool = false
    
    // TEMP: Need to implement async/await func later and check to get the correct result
    @State private var hasStoryManagePermission: Bool = StoryPermissionChecker.shared.checkUserHasManagePermission()
    
    var nextStorySegment: (() -> Void)?
    var previousStorySegment: (() -> Void)?
    
    init(storySegmentIndex: Binding<Int>, totalDuration: Binding<CGFloat>, targetName: String, avatar: UIImage, isVerified: Bool, nextStorySegment: (() -> Void)? = nil, previousStorySegment: (() -> Void)? = nil) {
        self._storySegmentIndex = storySegmentIndex
        self._totalDuration = totalDuration
        self.targetName = targetName
        self.avatar = avatar
        self.isVerified = isVerified
        self.nextStorySegment = nextStorySegment
        self.previousStorySegment = previousStorySegment
    }
    
    var body: some View {
        TabView(selection: $storySegmentIndex) {
            ForEach(Array(storyCollection.snapshots.enumerated()), id: \.element.storyId) { index, amityStory in
                let storyModel = AmityStoryModel(story: amityStory)
                
                VStack(spacing: 0) {
                    ZStack {
                        GeometryReader { geometry in
                            if let imageURL = storyModel.imageURL {
                                ImageView(imageURL: imageURL,
                                          totalDuration: $totalDuration,
                                          displayMode: storyModel.imageDisplayMode,
                                          size: geometry.size)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .overlay(
                                    storyModel.syncState == .error || storyModel.syncState == .syncing ? Color.black.opacity(0.5) : nil
                                )
                            } else if let videoURLStr = storyModel.videoURLStr,
                                      let videoURL = URL(string: videoURLStr) {
                                VideoView(videoURL: videoURL,
                                          totalDuration: $totalDuration,
                                          muteVideo: $muteVideo)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .overlay(
                                    storyModel.syncState == .error || storyModel.syncState == .syncing ? Color.black.opacity(0.5) : nil
                                )
                                
                                let muteIcon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "mute_icon", of: String.self) ?? "")
                                let unmuteIcon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "unmute_icon", of: String.self) ?? "")
                                let color = Color(UIColor(hex: getConfig(pageId: .storyPage, elementId: .muteUnmuteButtonElement, key: "background_color", of: String.self) ?? ""))
                                Image(muteVideo ? muteIcon
                                      : unmuteIcon)
                                .frame(width: 32, height: 32)
                                .background(color)
                                .clipShape(.circle)
                                .offset(x: 16, y: 98)
                                .onTapGesture {
                                    muteVideo.toggle()
                                }
                            }
                        }
                        
                        getGestureView()
                            .offset(y: 130) // not to overlap gesture from metadata view & muteVideo view
                        
                        VStack(alignment: .center) {
                            getMetadataView(targetName: targetName,
                                            avatar: avatar,
                                            isVerified: isVerified,
                                            story: storyModel)
                            Spacer()
                            
                            if let firstItem = storyModel.storyItems.first, let hyperlinkItem = firstItem as? AmityHyperLinkItem {
                                let data = hyperlinkItem.getData()
                                let model = HyperLinkModel(url: data["url"] as? String ?? "", urlName: data["customText"] as? String ?? "")
                                getHyperLinkView(data: model)
                            }
                        }
                        .offset(y: 30) // height + padding top, bottom of progressBarView
                        
                        
                    }
                    
                    if storyModel.syncState == .error {
                        getFailedStoryBanner(tapped: {
                            showRetryAlert.toggle()
                        })
                        .alert(isPresented: $showRetryAlert, content: {
                            Alert(title: Text(AmityLocalizedStringSet.Story.failedStoryAlertTitle.localizedString),
                                  message: Text(AmityLocalizedStringSet.Story.failedStoryAlertMessage.localizedString),
                                  primaryButton: .cancel(),
                                  secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.discard.localizedString), action: {
                                Task {
                                    storyCoreViewModel.playVideo = false
                                    try await storyCoreViewModel.storyManager.deleteStory(storyId: storyModel.storyId)
                                }
                            }))
                        })
                    } else if storyModel.syncState == .syncing {
                        getSyncingStoryBanner()
                    } else {
                        getAnalyticView(storyModel)
                    }
                }
                .onAppear {
                    // Last story already appeared on screen
                    Log.add(event: .info, "Story index: \(index) total: \(storyCollection.snapshots.count)")
                    amityStory.analytics.markAsSeen()
                }
                .id(amityStory.storyId)
                .tag(index)
            }
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
            BottomSheetDragIndicator()
            if let story = storyCollection.object(at: storySegmentIndex) {
                let isCommunityMember = story.storyTarget?.community?.isJoined ?? true
                let allowCreateComment = story.storyTarget?.community?.storySettings.allowComment ?? false
                AmityCommentTrayComponent(referenceId: story.storyId, referenceType: .story, hideCommentButtons: !isCommunityMember, allowCreateComment: allowCreateComment)
            }
        }
        .gesture(DragGesture().onChanged{ _ in})
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(nil)
    }
    
    
    func getMetadataView(targetName: String, avatar: UIImage, isVerified: Bool, story: AmityStoryModel) -> some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .padding(.leading, 16)
                
                if hasStoryManagePermission {
                    AmityCreateNewStoryButtonElement(componentId: .storyTabComponent)
                        .frame(width: 16.0, height: 16.0)
                }
            }
            .onTapGesture {
                if hasStoryManagePermission {
                    goToStoryCreationPage(targetId: story.targetId, avatar: avatar)
                }
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(targetName)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(height: 20)
                        .foregroundColor(.white)
                        .onTapGesture {
                            host.controller?.dismiss(animated: true)
                        }
                    
                    if isVerified {
                        Image(AmityIcon.verifiedWhiteBadge.getImageResource())
                            .resizable()
                            .frame(width: 20, height: 20)
                            .offset(x: -5)
                    }
                }
                HStack {
                    Text(story.createdAt.timeAgoString)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("By \(story.creatorName)")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                
            }
            
            Spacer()
        }
    }
    
    
    func getHyperLinkView(data: HyperLinkModel) -> some View {
        HStack(spacing: 0) {
            Image(AmityIcon.hyperLinkBlueIcon.getImageResource())
                .frame(width: 20, height: 20)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
            
            let title = data.getCustomName().isEmpty ? data.getDomainName() ?? "" : data.getCustomName()
            Text(title)
                .lineLimit(1)
                .font(.system(size: 15))
                .padding(.trailing, 16)
        }
        .frame(height: 40)
        .background(Color(UIColor(hex: "#EBECEF")).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(EdgeInsets(top: 0, leading: 24, bottom: 62, trailing: 24))
        .onTapGesture {
            guard let url = URLHelper.concatProtocolIfNeeded(urlStr: data.url) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    
    func getGestureView() -> some View {
        GestureView(onLeftTap: {
            previousStorySegment?()
        }, onRightTap: {
            nextStorySegment?()
        }, onTouchAndHoldStart: {
            storyPageViewModel.shouldRunTimer = false
            storyCoreViewModel.playVideo = false
        }, onTouchAndHoldEnd: {
            storyPageViewModel.shouldRunTimer = true
            storyCoreViewModel.playVideo = true
        }, onDragEnded: { _ in
            host.controller?.dismiss(animated: true)
        })
    }
    
    
    func getAnalyticView(_ story: AmityStoryModel) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Label {
                Text("\(story.viewCount)")
                    .font(.system(size: 15))
            } icon: {
                let icon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, componentId: nil, elementId: .impressionIconElement, key: "impression_icon", of: String.self) ?? "")
                Image(icon)
                    .frame(width: 20, height: 16)
                    .padding(.trailing, -4)
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showCommentTray.toggle()
            } label: {
                let color = Color(UIColor(hex: getConfig(pageId: .storyPage, elementId: .storyCommentButtonElement, key: "background_color", of: String.self) ?? "#FFFFFF"))
                HStack(spacing: 0) {
                    let icon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .storyCommentButtonElement, key: "comment_icon", of: String.self) ?? "")
                    Image(icon)
                        .frame(width: 20, height: 16)
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                    Text(story.commentCount.formattedCountString)
                        .lineLimit(1)
                        .font(.system(size: 15).monospacedDigit())
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
                .frame(minWidth: 56)
                .frame(height: 40)
                .fixedSize()
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            let isCommunityMember = story.storyTarget?.community?.isJoined ?? true
            Button(feedbackStyle: .light) {
                guard isCommunityMember else {
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Story.nonMemberReactStoryMessage.localizedString)
                    return
                }
                
                Task {
                    if story.isLiked {
                        try await storyPageViewModel.removeReaction(storyId: story.storyId)
                    } else {
                        try await storyPageViewModel.addReaction(storyId: story.storyId)
                    }
                }
            } label: {
                let color = Color(UIColor(hex: getConfig(pageId: .storyPage, elementId: .storyReactionButtonElement, key: "background_color", of: String.self) ?? ""))
                HStack(spacing: 0) {
                    let icon = AmityIcon.getImageResource(named: getConfig(pageId: .storyPage, elementId: .storyReactionButtonElement, key: "reaction_icon", of: String.self) ?? "")
                    let likedIcon = AmityIcon.likeReactionIcon.getImageResource()
                    Image(story.isLiked ? likedIcon : icon)
                        .frame(width: 20, height: 16)
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                    Text(story.reactionCount.formattedCountString)
                        .lineLimit(1)
                        .font(.system(size: 15).monospacedDigit())
                        .foregroundColor(.white)
                        .padding(.trailing, 10)
                }
                .frame(minWidth: 56)
                .frame(height: 40)
                .fixedSize()
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .frame(height: 56)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 25, trailing: 12))
        .background(Color.black)
    }
    
    
    func getFailedStoryBanner(tapped: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Image(AmityIcon.statusWarningIcon.getImageResource())
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8))
            Text(AmityLocalizedStringSet.Story.failedStoryBannerMessage.localizedString)
                .font(.system(size: 15))
                .foregroundColor(Color.white)
            Spacer()
            Button(action: {
                tapped()
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
                .font(.system(size: 15))
                .foregroundColor(Color.white)
            Spacer()
        }
        .frame(height: 44)
        .background(Color.black)
        .padding(.bottom, 37)
    }
    
    
    private func goToStoryCreationPage(targetId: String, avatar: UIImage?) {
        let createStoryPage = AmityCreateStoryPage(targetId: targetId, avatar: avatar)
        let controller = SwiftUIHostingController(rootView: createStoryPage)
        
        host.controller?.navigationController?.setViewControllers([controller], animated: false)
    }
}

// TEMP: temporary solution for Caching
class StoryCoreViewModel: ObservableObject {
    
    @Published var playVideo: Bool = true
    let storyManager = StoryManager()
    
    private var disposeBag: Set<AnyCancellable> = []
    private var storySyncState: AmitySyncState = .default
    
    init(storyCollection: AmityCollection<AmityStory>) {
        storyCollection.$snapshots
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] stories in
                var urls: [URL] = []
                
                for story in stories {
                    if let urlStr = story.getVideoInfo()?.getVideo(resolution: .res_720p),
                       let url = URL(string: urlStr) {
                        urls.append(url)
                    }
                    
                }
                
                // This code observe story creation state.
                // We can observe first story cause liveCollection will have failed story or syncing story at the first index.
                if let newStorySyncState = stories.first?.syncState {
                    let oldStorySyncState = self?.storySyncState
                    
                    if oldStorySyncState == .syncing && newStorySyncState == .synced {
                        self?.playVideo = false
                    }
                    
                    self?.storySyncState = newStorySyncState
                }
                
                VideoPlayer.preload(urls: urls)
            }.store(in: &disposeBag)
    }
}

struct ImageView: View {
    
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
                .onDisappear {
                    storyPageViewModel.shouldRunTimer = true
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
        }
        .onAppear {
            totalDuration = 4.0
            Log.add(event: .info, "Story TotalDuration: \(totalDuration)")
            Log.add(event: .info, "Story ImageDisplayMode: \(displayMode)")
        }
    }
}

struct VideoView: View {
    
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    @EnvironmentObject var storyCoreViewModel: StoryCoreViewModel
    
    private let videoURL: URL
    @Binding var totalDuration: CGFloat
    @Binding var muteVideo: Bool
    
    @State private var showActivityIndicator: Bool = false
    @State private var time: CMTime = .zero
    @StateObject private var viewModel = VideoViewModel()
    
    init(videoURL: URL, totalDuration: Binding<CGFloat>, muteVideo: Binding<Bool>) {
        self.videoURL = videoURL
        self._totalDuration = totalDuration
        self._muteVideo = muteVideo
    }
    
    var body: some View {
        VideoPlayer(url: videoURL, play: $viewModel.playVideo, time: $time)
            .autoReplay(false)
            .mute(muteVideo)
            .contentMode(.scaleToFill)
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
                viewModel.playVideo(true)
            }
            .onDisappear {
                viewModel.playVideo(false)
            }
            .onChange(of: storyCoreViewModel.playVideo) { play in
                Log.add(event: .info, "PlayVideo: \(play)")
                viewModel.playVideo(play)
            }
    }
}

class VideoViewModel: ObservableObject {
    @Published var playVideo: Bool = true
    
    func playVideo(_ value: Bool) {
        guard value != playVideo else { return }
        playVideo = value
        
    }
}
