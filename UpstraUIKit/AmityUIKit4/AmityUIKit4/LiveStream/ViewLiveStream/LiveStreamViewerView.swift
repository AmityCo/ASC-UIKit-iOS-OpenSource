//
//  LivestreamVideoPlayerView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import SwiftUI
import AVKit

struct LiveStreamViewerView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: .livestreamPlayerPage)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @State private var showOverlay = false
    @State private var playPauseOpacity = 0.0
    @State private var isPlaying = true
    @StateObject var networkMonitor = NetworkMonitor()
    @State var degreesRotating = 0.0
    
    @State private var showBottomSheet = false
    @State private var showShareSheet = false
    
    private let debouncer = Debouncer(delay: 2)
    @ObservedObject var viewModel: LiveStreamViewerViewModel
    let liveChatFeedHeight = (UIScreen.main.bounds.height - 50) / 5
    
    init(viewModel: LiveStreamViewerViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
                .ignoresSafeArea()
            
            if let room = viewModel.room {
                let streamTerminationLabels = room.moderation?.terminateLabels ?? []
                if !streamTerminationLabels.isEmpty {
                    VStack(alignment: .center) {
                        Image(AmityIcon.livestreamErrorIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 12)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedTitle.localizedString)
                            .applyTextStyle(.titleBold(Color.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedMessage.localizedString)
                            .applyTextStyle(.caption(Color.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                } else if room.status == .ended || room.status == .recorded {
                    VStack(alignment: .center) {
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedTitle.localizedString)
                            .applyTextStyle(.titleBold(Color.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedMessage.localizedString)
                            .applyTextStyle(.caption(Color.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                } else {
                    ZStack(alignment: .topTrailing) {
                        // Video player fills entire screen                        
                        LiveStreamPlayerView(streamURL: URL(string: room.livePlaybackUrl ?? "")!, isPlaying: isPlaying)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .dismissKeyboardOnDrag()
                            .onTapGesture {
                                playPauseButtonAction()
                            }
                        
                        HStack {
                            // Live badge overlay in original position (top-leading)
                            HStack(alignment: .center, spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                
                                if viewModel.watchingCount > 0 {
                                    Image(AmityIcon.Chat.membersCount.imageResource)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 14)
                                        .foregroundColor(Color.white)
                                    
                                    Text("\(viewModel.watchingCount.formattedCountString)")
                                        .applyTextStyle(.captionBold(.white))
                                } else {
                                    Text(AmityLocalizedStringSet.Social.livestreamPlayerLive.localizedString)
                                        .applyTextStyle(.captionBold(.white))
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4, corners: .allCorners)
                            
                            Image(AmityIcon.LiveStream.menu.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white)
                                .padding(.trailing, 16)
                                .padding(.leading, 4)
                                .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.defaultDarkTheme.backgroundColor)) {
                                    VStack(spacing: 0) {
                                        shareableLinkItemView
                                    }
                                    .padding(.bottom, 64)
                                }
                                .sheet(isPresented: $showShareSheet) {
                                    let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .livestream, id: viewModel.post.postId)
                                    ShareActivitySheetView(link: shareLink)
                                }
                                .onTapGesture {
                                    showBottomSheet.toggle()
                                }
                        }
                        .padding(.top, 20)
                        
                        playPauseButton
                    }
                    .ignoresSafeArea(.keyboard, edges: .all)
                }
                // Stream is not available but request to fetch stream is complete.
            } else if viewModel.isLoaded {
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamErrorIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableMessage.localizedString)
                        .applyTextStyle(.caption(Color.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            }
            
            
            ZStack(alignment: .bottom) {
                // live chat feed and compose bar
                VStack(alignment: .trailing, spacing: 0) {
                    liveReactionView
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                        .isHidden(viewModel.post.targetUser != nil)
                        .id("liveReactionView")
                    
                    liveChatFeedView
                        .isHidden(viewModel.post.targetUser != nil)
                    
                    if viewModel.post.feedType == .reviewing {
                        inPostReviewComposeBar
                    } else if viewModel.post.targetCommunity?.isJoined == false {
                        joinCommunityComposeBar
                    } else {
                        liveChatComposeBar
                            .isHidden(viewModel.post.targetUser != nil)
                    }
                }
                
                // Reaction bar overlay
                if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                    reactionBarOverlay
                        .visibleWhen(liveChatViewModel.showReactionBar)
                }
            }
            .isHidden(viewModel.room?.status ?? .none == .ended || viewModel.room?.status ?? .none == .recorded)
            
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamReconnectingIcon.imageResource)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(degreesRotating))
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerReconnectingTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerReconnectingMessage.localizedString)
                        .applyTextStyle(.caption(Color.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    withAnimation(.linear(duration: 1)
                        .speed(1).repeatForever(autoreverses: false)) {
                            degreesRotating = 360.0
                        }
                }
            }
            .opacity(networkMonitor.isConnected ? 0 : 1)
                        
            ZStack(alignment: .bottom) {
                VStack {
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(AmityIcon.LiveStream.close.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white)
                                .padding(2)
                                .onTapGesture {
                                    viewModel.cleanup()
                                    host.controller?.dismissOrPop()
                                }
                            
                            // Community and streamer info
                            if let room = viewModel.room {
                                HStack(spacing: 8) {
                                    if let event = viewModel.post.event {
                                        HStack(spacing: 8) {
                                            AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource,
                                                       url: URL(string: event.coverImage?.mediumFileURL ?? ""),
                                                       contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                // Event title
                                                Text(event.title)
                                                    .applyTextStyle(.bodyBold(Color.white))
                                                    .lineLimit(1)
                                                
                                                // Event Creator info
                                                if let creator = event.creator {
                                                    HStack(spacing: 4) {
                                                        Text("By \(creator.displayName ?? "")")
                                                            .applyTextStyle(.caption(Color.white))
                                                            .lineLimit(1)
                                                        
                                                        Image(AmityIcon.brandBadge.imageResource)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 18, height: 18)
                                                            .opacity(creator.isBrand ? 1 : 0)
                                                    }
                                                }
                                            }
                                            
                                            Spacer(minLength: 120)
                                        }
                                    } else if case .community(_, let community) = room.target, let community {
                                        AsyncImage(placeholder: AmityIcon.defaultCommunity.imageResource,
                                                   url: URL(string: community.avatar?.mediumFileURL ?? ""),
                                                   contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            // Community name
                                            HStack(spacing: 4) {
                                                Image(AmityIcon.lockBlackIcon.imageResource)
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 14, height: 18)
                                                    .foregroundColor(Color.white)
                                                    .isHidden(community.isPublic)
                                                
                                                Text(community.displayName)
                                                    .applyTextStyle(.bodyBold(Color.white))
                                                    .lineLimit(1)
                                                
                                                Image(AmityIcon.verifiedBadge.imageResource)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 18, height: 18)
                                                    .opacity(community.isOfficial ? 1 : 0)
                                                    .layoutPriority(1)
                                            }
                                            
                                            // Streamer info
                                            if let streamer = room.creator {
                                                HStack(spacing: 4) {
                                                    Text("By \(streamer.displayName ?? "")")
                                                        .applyTextStyle(.caption(Color.white.opacity(0.8)))
                                                        .lineLimit(1)
                                                    
                                                    Image(AmityIcon.brandBadge.imageResource)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 18, height: 18)
                                                        .opacity(streamer.isBrand ? 1 : 0)
                                                        .layoutPriority(1)
                                                }
                                            }
                                        }
                                    } else if room.targetType == "user", let user = room.creator {
                                        AmityUserProfileImageView(
                                            displayName: user.displayName ?? "",
                                            avatarURL: URL(string: user.getAvatarInfo()?.mediumFileURL ?? "")
                                        )
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        
                                        HStack(spacing: 4) {
                                            Text(user.displayName ?? "")
                                                .applyTextStyle(.bodyBold(Color.white))
                                                .lineLimit(1)
                                            
                                            Image(AmityIcon.brandBadge.imageResource)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 18, height: 18)
                                                .opacity(user.isBrand ? 1 : 0)
                                                .layoutPriority(1)
                                        }
                                    }
                                    
                                    Spacer(minLength: 150)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
            }
            
            PostDetailEmptyStateView(action: {
                viewModel.cleanup()
                host.controller?.dismiss(animated: true)
            })
            .ignoresSafeArea()
            .opacity(viewModel.isPostDeleted ? 1 : 0)
            .onChange(of: viewModel.isPostDeleted) { isDeleted in
                if isDeleted {
                    isPlaying = false
                }
            }
        }
        .onChange(of: viewModel.isStreamTerminated) { isTerminated in
            guard isTerminated else { return }
            
            // Show terminated screen
            let terminatedVc = AmitySwiftUIHostingController(rootView: AmityLivestreamTerminatedPage(type: .watcher, onDismiss: {
                viewModel.cleanup()
            }))
            terminatedVc.modalPresentationStyle = .overFullScreen
            self.host.controller?.navigationController?.pushViewController(terminatedVc, animated: false)
            
            // Stop player
            isPlaying = false
        }
        .onChange(of: viewModel.isBannedFromStream) { isBanned in
            guard isBanned else { return }
            
            // unobserve post and stream
            viewModel.cleanup()
            
            // Stop player
            isPlaying = false
            
            // Show banned screen
            let bannedVC = AmitySwiftUIHostingController(rootView: AmityLivestreamBannedPage(onDismiss: {
                // Move to post detail page
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let postDetailPage = AmityPostDetailPage(id: viewModel.post.postId)
                    let topController = UIApplication.topViewController()
                    topController?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: postDetailPage))
                }
            }))
            bannedVC.modalPresentationStyle = .overFullScreen
            self.host.controller?.navigationController?.pushViewController(bannedVC, animated: false)
        }
        .environmentObject(viewConfig)
    }
    
    @ViewBuilder
    private var liveReactionView: some View {
        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
            LiveReactionView(viewModel: liveChatViewModel.liveReactionViewModel)
                .frame(width: liveChatViewModel.liveReactionViewModel.width, height: liveChatViewModel.isTextEditorFocused ? 0.1 : liveChatViewModel.liveReactionViewModel.height)
        }
    }
    
    @ViewBuilder
    private var liveChatFeedView: some View {
        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
            AmityLiveStreamChatFeed(viewModel: liveChatViewModel, pageId: .createLivestreamPage)
                .frame(height: liveChatViewModel.isTextEditorFocused ? 0.1 : liveChatFeedHeight)
        }
    }
    
    @ViewBuilder
    private var liveChatComposeBar: some View {
        ZStack {
            if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                Color.black
                    .frame(height: 50)
                
                AmityLiveStreamChatComposeBar(viewModel: liveChatViewModel)
                    .frame(height: 35)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .onTapGesture {
                        AmityUserAction.perform(host: host) {
                            if !liveChatViewModel.isCommunityMember {
                                AmityUIKitManagerInternal.shared.behavior.globalBehavior?.handleNonMemberAction(context: .init(host: host))
                                return
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var reactionBarOverlay: some View {
        ZStack {
            // Full screen overlay with tap gesture to dismiss
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.liveStreamChatViewModel?.showReactionBar = false
                    }
                }
            
            // Reaction bar positioned at trailing bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AmityReactionBar(targetType: viewModel.room?.referenceType ?? "", targetId: viewModel.room?.referenceId ?? "", streamId: viewModel.room?.roomId ?? "", onReactionTap: { reaction in
                        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                            liveChatViewModel.liveReactionViewModel.addReaction(reaction)
                            
                            AmityUserAction.perform(host: host) {
                                // Intentionally left empty to show toast only for guest user
                            }
                        }
                        
                    })
                    .padding(.trailing, 24)
                    .scaleEffect(viewModel.liveStreamChatViewModel?.showReactionBar ?? false ? 1.0 : 0.0, anchor: .bottomTrailing)
                    .padding(.bottom, 58)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    var shareableLinkItemView: some View {
        let copyLinkConfig = viewConfig.forElement(.copyLink)
        let shareLinkConfig = viewConfig.forElement(.shareLink)
        
        BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? "", tintColor: .white)
            .onTapGesture {
                showBottomSheet.toggle()
                
                let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .livestream, id: viewModel.post.postId)
                UIPasteboard.general.string = shareLink
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoLinkCopied.localizedString, bottomPadding: 60)
                }
            }
        
        BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? "", tintColor: .white)
            .onTapGesture {
                showBottomSheet.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showShareSheet = true
                }
            }
    }
    
    private var inPostReviewComposeBar: some View {
        ZStack {
            Color.black
                .frame(height: 50)
            
            Text("This live stream has started, but with limited visibility until the post has been approved.")
                .applyTextStyle(.body(Color(viewConfig.theme.secondaryColor.blend(.shade2))))
                .multilineTextAlignment(.center)
                .padding(.leading, 32)
                .padding(.trailing, 32)
                .padding(.vertical, 6)
                .background(Color.black)
        }
    }
    
    private var joinCommunityComposeBar: some View {
        ZStack {
            Color.black
                .frame(height: 50)
            
            Text("Join community to interact with live stream.")
                .applyTextStyle(.body(Color(viewConfig.theme.secondaryColor.blend(.shade2))))
                .multilineTextAlignment(.center)
                .padding(.leading, 32)
                .padding(.trailing, 32)
                .padding(.vertical, 6)
                .background(Color.black)
        }
    }
    
    private var playPauseButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Image(isPlaying ? AmityIcon.LiveStream.pauseIcon.imageResource : AmityIcon.LiveStream.playIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                   
                Spacer()
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: playPauseOpacity)
        .opacity(playPauseOpacity)
        .allowsHitTesting(false)
    }
    
    func playPauseButtonAction() {
        if playPauseOpacity == 1.0 {
            isPlaying.toggle()
            
            // Pause/Resume watch time tracking accordingly
            if isPlaying {
                viewModel.watchMinuteTracker.resumeTracking()
            } else {
                viewModel.watchMinuteTracker.pauseTracking()
            }
        }
        
        playPauseOpacity = 1.0
        
        debouncer.run {
            playPauseOpacity = 0.0
        }
    }
}
