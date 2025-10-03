//
//  LivestreamVideoPlayerView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import SwiftUI

struct LivestreamVideoPlayerView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: .livestreamPlayerPage)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @State private var showOverlay = false
    @State private var opacity = 0.0
    @State private var isPlaying = true
    @StateObject var networkMonitor = NetworkMonitor()
    @State var degreesRotating = 0.0
    
    @State private var showBottomSheet = false
    @State private var showShareSheet = false
    
    
    private let debouncer = Debouncer(delay: 2)
    @StateObject var viewModel: LivestreamVideoPlayerViewModel
    let liveChatFeedHeight = (UIScreen.main.bounds.height - 50) / 2.5
    
    init(post: AmityPostModel) {
        self._viewModel = StateObject(wrappedValue: LivestreamVideoPlayerViewModel(post: post))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
                .ignoresSafeArea()
            
            if let stream = viewModel.stream {
                let streamTerminationLabels = stream.moderation?.terminateLabels ?? []
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
                    
                } else if stream.status == .ended {
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
                        if let view = AmityUIKitManagerInternal.shared.behavior.livestreamBehavior?.createLivestreamPlayer(stream: stream, client: AmityUIKit4Manager.client, isPlaying: $isPlaying.wrappedValue && networkMonitor.isConnected) {
                            AnyView(view)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .onTapGesture {
                                    displayOverlay()
                                    isPlaying.toggle()
                                }
                        }
                        
                        HStack {
                            // Live badge overlay in original position (top-leading)
                            Text(AmityLocalizedStringSet.Social.livestreamPlayerLive.localizedString)
                                .applyTextStyle(.captionBold(Color.white))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(UIColor(hex: "FF305A")))
                                .cornerRadius(4, corners: .allCorners)
                                .padding([.leading, .vertical], 16)
                            
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
                        .isHidden(viewModel.post.targetCommunity == nil)
                        .id("liveReactionView")
                    
                    liveChatFeedView
                        .isHidden(viewModel.post.targetCommunity == nil)
                    
                    if viewModel.post.feedType == .reviewing {
                        inPostReviewComposeBar
                    } else {
                        liveChatComposeBar
                            .isHidden(viewModel.post.targetCommunity == nil)
                    }
                }
                
                // Reaction bar overlay
                if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                    reactionBarOverlay
                        .visibleWhen(liveChatViewModel.showReactionBar)
                }
            }
            .visibleWhen(viewModel.stream?.status ?? .none != .ended)
            
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
                        HStack(spacing: 8) {
                            Image(AmityIcon.LiveStream.close.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.white)
                                .padding(2)
                                .onTapGesture {
                                    viewModel.unobservePostAndStream()
                                    
                                    host.controller?.dismiss(animated: true)
                                }
                            
                            // Community and streamer info
                            if let stream = viewModel.stream {
                                HStack(spacing: 8) {
                                    // Community profile image
                                    if let community = stream.community {
                                        AsyncImage(placeholder: AmityIcon.defaultCommunity.imageResource,
                                                   url: URL(string: community.avatar?.mediumFileURL ?? ""),
                                                   contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            // Community name
                                            if let community = stream.community {
                                                Text(community.displayName)
                                                    .applyTextStyle(.captionBold(Color.white))
                                                    .lineLimit(1)
                                                
                                                // Streamer info
                                                if let streamer = stream.user {
                                                    Text("By \(streamer.displayName ?? "")")
                                                        .applyTextStyle(.captionSmall(Color.white.opacity(0.8)))
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                    } else if let streamer = stream.user {
                                        AmityUserProfileImageView(
                                            displayName: streamer.displayName ?? "",
                                            avatarURL: URL(string: streamer.getAvatarInfo()?.mediumFileURL ?? "")
                                        )
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        
                                        Text(streamer.displayName ?? "")
                                            .applyTextStyle(.captionBold(Color.white))
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                    
                    Image(isPlaying ? AmityIcon.livestreamPauseIcon.getImageResource() : AmityIcon.videoControlIcon.getImageResource())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .opacity(opacity)
                        .animation(.easeInOut(duration: opacity == 0 ? 1.0 : 0), value: opacity)
                    
                    Spacer()
                    Spacer()
                }
            }
            
            PostDetailEmptyStateView(action: {
                viewModel.unobservePostAndStream()
                
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
        .onTapGesture {
            displayOverlay()
        }
        .onChange(of: viewModel.isStreamTerminated) { isTerminated in
            guard isTerminated else { return }
            
            // Show terminated screen
            let terminatedVc = AmitySwiftUIHostingController(rootView: AmityLivestreamTerminatedPage(type: .watcher, onDismiss: {
                viewModel.unobservePostAndStream()
            }))
            terminatedVc.modalPresentationStyle = .overFullScreen
            self.host.controller?.navigationController?.pushViewController(terminatedVc, animated: false)
            
            // Stop player
            isPlaying = false
        }
        .onChange(of: viewModel.isBannedFromStream) { isBanned in
            guard isBanned else { return }
            
            // unobserve post and stream
            viewModel.unobservePostAndStream()
            
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
            Color.black
                .frame(height: 50)
            
            if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                AmityLiveStreamChatComposeBar(viewModel: liveChatViewModel)
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
                    AmityReactionBar(targetType: viewModel.stream?.referenceType ?? "", targetId: viewModel.stream?.referenceId ?? "", streamId: viewModel.stream?.streamId ?? "", onReactionTap: { reaction in
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
                    Toast.showToast(style: .success, message: "Link copied")
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
    
    func displayOverlay() {
        opacity = 1.0
        
        debouncer.run {
            opacity = 0.0
        }
    }
}
