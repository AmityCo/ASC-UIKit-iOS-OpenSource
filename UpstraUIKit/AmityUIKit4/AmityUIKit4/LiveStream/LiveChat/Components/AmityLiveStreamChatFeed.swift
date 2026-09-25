//
//  AmityLiveStreamChatFeed.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/26/25.
//

import Foundation
import SwiftUI
import AmitySDK

public struct AmityLiveStreamChatFeed: AmityComponentView {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .livestreamChatFeed
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: AmityLiveStreamChatViewModel
    
    @Namespace private var topID
    @State private var animatingMessageIds: Set<String> = []
    @State private var lastMessageInViewport: Bool = true
    @State private var showDummyLastMessage: Bool = false
    @State private var lastMessageHeight: CGFloat = 0
    @State private var pinnedBannerHeight: CGFloat = 0
    
    public init(viewModel: AmityLiveStreamChatViewModel, pageId: PageId? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .livestreamChatFeed))
    }
    
    public var body: some View {
        chatStack
            .overlay(pinnedBannerOverlay, alignment: .top) // iOS 14-safe overlay signature
            .animation(.easeInOut(duration: 0.2), value: viewModel.pinnedMessage?.messageId)
            .updateTheme(with: viewConfig)
    }

    /// Pinned banner overlaid at the top of the chat. Its BOTTOM sits 8px into the chat list (Figma
    /// overlap); extra height when expanded extends UPWARD over the video, so the chat list below
    /// never moves. The overlay is not clipped, so the bubble can render above the feed frame.
    @ViewBuilder
    private var pinnedBannerOverlay: some View {
        Group {
            if let pinnedMessage = viewModel.pinnedMessage {
                pinnedBanner(pinnedMessage)
            }
        }
        .padding(.horizontal, 16)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { pinnedBannerHeight = geo.size.height }
                    .onChange(of: geo.size.height) { pinnedBannerHeight = $0 }
            }
        )
        // The overlay is top-aligned (banner top at the chat top); shift it up by its own height so
        // its BOTTOM sits 8px into the chat top. When expanded it gets taller → shifts further up →
        // grows upward over the video, while the chat list below stays put.
        .offset(y: -(pinnedBannerHeight - 8))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var chatStack: some View {
        ZStack(alignment: .top) {
            // Attaching bottom sheet modifier to the ZStack will effect the new message appear animation
            // This modifier use fullScreenCover internally, and it will try to rebuild the entire view hierarchy when something inside view hierarchy is changed.
            backgroundOverlay
                .bottomSheet(isShowing: $viewModel.showBottomSheet.show, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                    bottomSheetView
                }
                .bottomSheet(isShowing: $viewModel.showModerationBottomSheet.show, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                    moderationBottomsheetView
                }
            
            // This scroll view is upside down to match the chat feed direction and to support reverse pagination smoothly
            // Messages will be displayed in reverse order without needing to reverse the message data source
            // Note: need to arrange view hirearchy reversely to algin with the upside-down scroll view
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        Color.clear
                            .frame(maxHeight: showDummyLastMessage ? lastMessageHeight : 0)
                            .animation(.easeOut(duration: 0.6), value: showDummyLastMessage)
                            .isHidden(!showDummyLastMessage)
                        
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.uniqueId) { index, message in
                            getMessageBubble(message,
                                             isModerator: viewModel.moderators.contains(item: message.userId),
                                             isMuted: viewModel.mutedMembers.contains(item: message.userId),
                                             isHost: viewModel.hostUserId == message.userId,
                                             isCoHost: viewModel.coHostUserId == message.userId)
                                .modifier(NewMessageAnimationModifier(
                                    isAnimating: animatingMessageIds.contains(message.uniqueId)
                                ))
                                .scaleEffect(x: 1, y: -1)
                                .applyIf(index == 0) {
                                    $0.readSize { lastMessageHeight = $0.height }
                                }
                                .onAppear {
                                    if index == 0 {
                                        lastMessageInViewport = true
                                    }
                                }
                                .onDisappear {
                                    if index == 0 {
                                        lastMessageInViewport = false
                                    }
                                }
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id(topID)
                            .onAppear {
                                guard !viewModel.messages.isEmpty else { return }
                                viewModel.loadPreviousMessages()
                            }
                    }
                }
                .padding(.horizontal, 16)
                .scaleEffect(x: 1, y: -1)
                .padding(.bottom, 12)
                .mask(fadeMask)
                .onChange(of: viewModel.messages.first?.uniqueId, perform: { _ in
                    guard lastMessageInViewport else { return }
                    handleMessagesUpdateAnimation(messages: viewModel.messages, proxy: proxy)
                })
                .onAppear {
                    handleMessagesUpdateAnimation(messages: viewModel.messages, proxy: proxy)
                }
            }
        }
    }

    @ViewBuilder
    private func pinnedBanner(_ pinnedMessage: AmityPinnedMessage) -> some View {
        let messageText = pinnedMessage.data?["text"] as? String ?? ""
        let authorId = pinnedMessage.creatorPublicId
        let currentUserId = AmityUIKitManagerInternal.shared.currentUserId
        let isMutedAuthor = viewModel.isMuted(userId: authorId)
            && (viewModel.isStreamer || viewModel.isModerator(userId: currentUserId) || authorId == currentUserId)
        // A deleted author shows "Deleted user" (same as the chat bubble via MessageModel).
        let isAuthorDeleted = viewModel.pinnedAuthor?.isDeleted ?? false
        let displayName = isAuthorDeleted
            ? AmityLocalizedStringSet.Chat.deletedUser.localizedString
            : (viewModel.pinnedAuthor?.displayName ?? AmityLocalizedStringSet.Social.livestreamChatUnknownUser.localizedString)

        PinnedMessageBannerView(
            messageText: messageText,
            displayName: displayName,
            isBrand: viewModel.pinnedAuthor?.isBrand ?? false,
            isHost: viewModel.hostUserId == authorId,
            isCoHost: viewModel.coHostUserId == authorId,
            isModerator: viewModel.isModerator(userId: authorId),
            isMutedAuthor: isMutedAuthor,
            canPin: viewModel.canPin,
            onUnpin: {
                Task.runOnMainActor {
                    do {
                        try await viewModel.unpinMessage()
                    } catch {
                        // Silent by design: no pin-specific error UI. Pin state is unchanged
                        // and the banner keeps reflecting the channel live object; the view
                        // model recomputes canPin on failure.
                    }
                }
            },
            isExpanded: $viewModel.isPinnedMessageExpanded
        )
    }

    private var fadeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.black.opacity(0),
                         Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 45)
            
            Color.black
        }
    }
    
    private var backgroundOverlay: some View {
        Color.clear
    }
    
    private func getMessageBubble(_ message: MessageModel, isModerator: Bool, isMuted: Bool, isHost: Bool, isCoHost: Bool) -> some View {
        HStack(alignment: message.syncState == .error ? .center : .top, spacing: 8) {
            // User name and message content
            VStack(alignment: .leading, spacing: 8) {
                let currentUserId = AmityUIKitManagerInternal.shared.currentUserId
                // Streamer, Cohost, Moderator, Owner message only can see muted badge
                let shouldShowMutedBadge = isMuted && (viewModel.isStreamer || viewModel.isModerator(userId: currentUserId) || message.isOwner)

                LiveStreamChatBylineView(
                    displayName: message.displayName,
                    isBrand: message.user?.isBrand ?? false,
                    isHost: isHost,
                    isCoHost: isCoHost,
                    isModerator: isModerator,
                    showMutedIcon: shouldShowMutedBadge,
                    onNameTap: {
                        // Host cannot moderate Co-host
                        // but can remove from livestream
                        if viewModel.isHost && (isCoHost || viewModel.isWaitingCoHost?().1 == message.userId) {
                            viewModel.removeCoHostAction?()
                            return
                        }

                        // Only streamer and moderators can see moderation options
                        guard viewModel.isStreamer || viewModel.isModerator(userId: currentUserId) else { return }

                        // Moderation options cannot be applied to host, Co-host and self
                        guard !isHost && !isCoHost && currentUserId != message.userId else { return }

                        viewModel.showModerationBottomSheet.message = message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.showModerationBottomSheet.show.toggle()
                        }
                    }
                )

                // Message content
                if viewModel.deletedMessageIds[message.uniqueId] == true {
                    HStack(spacing: 6) {
                        Image(AmityIcon.trashBinIcon.getImageResource())
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColorShade2))
                            .frame(width: 16, height: 18)
                            .offset(y: -1)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamChatDeletedMessage.localizedString)
                            .applyTextStyle(.caption(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                    }
                } else {
                    Text(message.text)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColor)))
                }
            }
            
            Spacer()
            
            // Action button
            if message.syncState == .error {
                Button {
                    showErrorActionSheet(message: message)
                } label: {
                    Image(AmityIcon.statusWarningIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 20)
                }
            } else if viewModel.deletedMessageIds[message.uniqueId] != true {
                Button {
                    viewModel.showBottomSheet.message = message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.showBottomSheet.show.toggle()
                    }
                } label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                }
                .accessibilityIdentifier(AccessibilityID.Chat.LiveChatFeed.messageMenuButton)
            }
        }
        .padding(.all, 12)
        .background(Color(AmityFixedColor.shared.liveStreamChatBubble))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            let message = viewModel.showBottomSheet.message
            let isMessageDeleted = (message?.isDeleted ?? true)
                || (message.map { viewModel.deletedMessageIds[$0.uniqueId] == true } ?? true)

            // Pin / Unpin — only for users who may pin, and never on a deleted message.
            // The server owns the pinned state; the banner reflects the result via the channel event.
            if viewModel.canPin, !isMessageDeleted, let message {
                let isAlreadyPinned = viewModel.pinnedMessage?.messageId == message.id
                let title = isAlreadyPinned
                    ? AmityLocalizedStringSet.LiveChat.unpinMessage.localizedString
                    : AmityLocalizedStringSet.LiveChat.pinMessage.localizedString
                let icon = isAlreadyPinned
                    ? AmityIcon.LiveStream.unpinnedLivestreamMessage.imageResource
                    : AmityIcon.LiveStream.livestreamPinProductIcon.imageResource

                BottomSheetItemView(icon: icon, text: title)
                    .accessibilityIdentifier(AccessibilityID.Chat.LiveChatFeed.pinMessageButton)
                    .onTapGesture {
                        viewModel.showBottomSheet.show.toggle()
                        Task.runOnMainActor {
                            do {
                                if isAlreadyPinned {
                                    try await viewModel.unpinMessage(message.id)
                                } else {
                                    try await viewModel.pinMessage(message.id)
                                }
                            } catch {
                                // Silent by design: no pin-specific error UI. Pin state is unchanged,
                                // the menu closes, and the banner keeps reflecting the live object.
                                // The view model recomputes canPin on failure (e.g. a stale 403).
                            }
                        }
                    }
            }

            if message?.userId != AmityUIKitManagerInternal.shared.currentUserId {
                let isFlagged = viewModel.showBottomSheet.message?.isFlaggedByMe ?? false
                let title = isFlagged ? AmityLocalizedStringSet.LiveChat.unreportMessage.localizedString : AmityLocalizedStringSet.LiveChat.reportMessage.localizedString
                
                BottomSheetItemView(icon: AmityIcon.flagIcon.getImageResource(), text: title)
                    .onTapGesture {
                        guard let message = viewModel.showBottomSheet.message else { return }
                        viewModel.showBottomSheet.show.toggle()
                        
                        AmityUserAction.perform(host: host, toastBottomPadding: Toast.bottomBarPadding) {
                            if isFlagged {
                                Task.runOnMainActor {
                                    try await viewModel.unflagMessage(message.id)
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.toastUnReportMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    PiPState.shared.setAutoPiPSuppressed(true)
                                    let page = AmityContentReportPage(type: .message(id: message.id), bottomBarHeight: viewModel.composeBarHeight).environmentObject(viewConfig)
                                    let vc = PiPSuppressingNavigationController(rootView: page)
                                    vc.isNavigationBarHidden = true
                                    host.controller?.present(vc, animated: true)
                                }
                            }
                        }
                    }
            }
            
            // Show Delete option if message is current user's own message
            // If not, show delete option only for streamer(host and co-host) and moderators (except for host)
            if message?.userId == AmityUIKitManagerInternal.shared.currentUserId ||
                (viewModel.isStreamer || viewModel.isModerator(userId: AmityUIKitManagerInternal.shared.currentUserId)) && message?.userId != viewModel.hostUserId {
                BottomSheetItemView(icon: AmityIcon.trashBinIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.deleteMessage.localizedString, isDestructive: true)
                    .onTapGesture {
                        guard let message = viewModel.showBottomSheet.message else { return }
                        Task.runOnMainActor {
                            try await viewModel.deleteMessage(message.id)
                            viewModel.showBottomSheet.show.toggle()
                        }
                    }
                
            }
        }
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private var moderationBottomsheetView: some View {
        let message = viewModel.showModerationBottomSheet.message
        VStack(spacing: 0) {
            
            VStack(spacing: 0) {
                let isModerator = viewModel.isModerator(userId: message?.userId ?? "")
                let isBrand = message?.user?.isBrand ?? false

                HStack(spacing: 6) {
                    Text(message?.displayName ?? AmityLocalizedStringSet.Social.livestreamChatUnknownUser.localizedString)
                        .applyTextStyle(.titleBold(.white))
                        .lineLimit(1)
                    
                    if isBrand {
                        Image(AmityIcon.brandBadge.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .layoutPriority(1)
                    }
                    
                    if viewModel.isMuted(userId: message?.userId ?? "") {
                        Image(AmityIcon.clipMuteIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                            .frame(width: 16, height: 14)
                            .layoutPriority(1)
                    }
                }
                .padding(.horizontal, 8)
                
                if isModerator {
                    ModeratorBadgeView()
                        .padding(.top, 6)
                }
            }
            .padding(.bottom, 16)
            .padding(.top, 10)
            
            Rectangle()
                .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                .frame(height: 1)
                .padding(.bottom, 12)
            
            // Show Invite as Co-host option
            // if there is not a co-host in the room and waiting for co-host acceptance
            // only host can see this option
            if viewModel.coHostUserId.isEmpty && !(viewModel.isWaitingCoHost?().0 ?? false) && viewModel.participantRole == .host {
                BottomSheetItemView(icon: AmityIcon.inviteUserIcon.getImageResource(), text: AmityLocalizedStringSet.Social.livestreamChatInviteAsCoHost.localizedString)
                    .onTapGesture {
                        viewModel.showModerationBottomSheet.show.toggle()
                        showAlert(title: AmityLocalizedStringSet.Social.livestreamConfirmInviteCoHostTitle.localizedString, message: AmityLocalizedStringSet.Social.livestreamConfirmInviteCoHostMessage.localizedString, actionTitle: AmityLocalizedStringSet.Social.livestreamInviteButton.localizedString) {
                            Task.runOnMainActor {
                                do {
                                    try await viewModel.inviteAsCoHost(userId: message?.userId ?? "")
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationSentToast.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                    if let user = message?.user {
                                        viewModel.didFinishCoHostInvitationAction?(AmityUserModel(user: user))
                                    }
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationSendFailedToast.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                }
                            }
                        }
                    }
            }
            
            // Show Promote/Demote moderator option if ther user is not muted
            if viewModel.isMuted(userId: message?.userId ?? "") == false {
                if viewModel.isModerator(userId: message?.userId ?? "") {
                    BottomSheetItemView(icon: AmityIcon.communityMemberIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.demoteToMember.localizedString)
                        .onTapGesture {
                            viewModel.showModerationBottomSheet.show.toggle()
                            showAlert(title: AmityLocalizedStringSet.LiveChat.demoteToMemberTitle.localizedString,
                                      message: AmityLocalizedStringSet.LiveChat.demoteToMemberDesc.localizedString,
                                      actionTitle: AmityLocalizedStringSet.LiveChat.demote.localizedString,
                                      isDestructive: true) {
                                Task.runOnMainActor {
                                    do {
                                        if let userId = message?.userId {
                                            try await viewModel.demoteModerator(userId: userId)
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.demoteSuccessToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.demoteFailedToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                    }
                                }
                            }
                        }
                } else {
                    BottomSheetItemView(icon: AmityIcon.communityModeratorIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.promoteToModerator.localizedString)
                        .onTapGesture {
                            viewModel.showModerationBottomSheet.show.toggle()
                            showAlert(title: AmityLocalizedStringSet.LiveChat.promoteToModeratorTitle.localizedString,
                                      message: AmityLocalizedStringSet.LiveChat.promoteToModeratorDesc.localizedString,
                                      actionTitle: AmityLocalizedStringSet.LiveChat.promote.localizedString) {
                                Task.runOnMainActor {
                                    do {
                                        if let userId = message?.userId {
                                            try await viewModel.promoteModerator(userId: userId)
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.promoteSuccessToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.promoteFailedToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                    }
                                }
                            }
                        }
                }
            }
            
            // Show Mute/Unmute option if the user is not a moderator
            if viewModel.isModerator(userId: message?.userId ?? "") == false {
                if viewModel.isMuted(userId: message?.userId ?? "") {
                    BottomSheetItemView(icon: AmityIcon.clipUnmuteIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.unmuteUser.localizedString)
                        .onTapGesture {
                            viewModel.showModerationBottomSheet.show.toggle()
                            showAlert(title: AmityLocalizedStringSet.LiveChat.unmuteUserTitle.localizedString,
                                      message: AmityLocalizedStringSet.LiveChat.unmuteUserDesc.localizedString,
                                      actionTitle: AmityLocalizedStringSet.LiveChat.unmute.localizedString) {
                                Task.runOnMainActor {
                                    do {
                                        if let userId = message?.userId {
                                            try await viewModel.unmuteMember(userId: userId)
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.unmuteSuccessToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.unmuteFailedToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                    }
                                }
                            }
                        }
                } else {
                    BottomSheetItemView(icon: AmityIcon.clipMuteIcon.getImageResource(), text: AmityLocalizedStringSet.LiveChat.muteUser.localizedString)
                        .onTapGesture {
                            viewModel.showModerationBottomSheet.show.toggle()
                            showAlert(title: AmityLocalizedStringSet.LiveChat.muteUserTitle.localizedString,
                                      message: AmityLocalizedStringSet.LiveChat.muteUserDesc.localizedString,
                                      actionTitle: AmityLocalizedStringSet.LiveChat.mute.localizedString,
                                      isDestructive: true) {
                                Task.runOnMainActor {
                                    do {
                                        if let userId = message?.userId {
                                            try await viewModel.muteMember(userId: userId)
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.muteSuccessToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.muteFailedToastMessage.localizedString, aboveBottomBarHeight: viewModel.composeBarHeight)
                                    }
                                }
                            }
                        }
                }
            }
        }
        .padding(.bottom, 48)
    }
    
    /// System dialogs follow the UIKit theme, which can differ from the device appearance.
    private var alertInterfaceStyle: UIUserInterfaceStyle {
        AmityUIKitConfigController.shared.getCurrentThemeStyle() == .dark ? .dark : .light
    }

    private func showErrorActionSheet(message: MessageModel) {
        let alert = UIAlertController(title: AmityLocalizedStringSet.Social.livestreamChatMessageNotSentTitle.localizedString, message: nil, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = alertInterfaceStyle

        let deleteAction = UIAlertAction(title: AmityLocalizedStringSet.General.delete.localizedString, style: .destructive) { _ in
            Task.runOnMainActor {
                try await viewModel.deleteMessage(message.id)
            }
        }

        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            host.controller?.present(alert, animated: true)
        }
    }
    
    private func handleMessagesUpdateAnimation(messages: [MessageModel], proxy: ScrollViewProxy) {
        // Check if new message was added
        if let firstMessage = messages.first,
           !animatingMessageIds.contains(firstMessage.uniqueId) {
            
            showDummyLastMessage = true
            
            // Animate the new message
            animatingMessageIds.insert(firstMessage.uniqueId)
            
            // Remove from animating set after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animatingMessageIds.remove(firstMessage.uniqueId)
                showDummyLastMessage = false
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    proxy.scrollTo(firstMessage.uniqueId, anchor: .bottom)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, actionTitle: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.overrideUserInterfaceStyle = alertInterfaceStyle
            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
            let workAction = UIAlertAction(title: actionTitle, style: isDestructive ? .destructive : .default) { _ in
                action()
            }
            alert.addAction(cancelAction)
            alert.addAction(workAction)
            
            alert.preferredAction = workAction
            host.controller?.present(alert, animated: true)
        }
    }
}


/// Holds PiP suppression for as long as its presentation is on screen, then releases it.
///
/// Tied to the navigation controller rather than the page's `onDisappear` because the
/// report flow pushes a second page, and that would fire on the push — releasing
/// suppression while the flow is still covering the player.
private final class PiPSuppressingNavigationController<Content: View>: AmitySwiftUIHostingNavigationController<Content> {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PiPState.shared.setAutoPiPSuppressed(false)
    }
}

private struct NewMessageAnimationModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 0.9 : 1.0, anchor: .center)
            .opacity(isAnimating ? 0.7 : 1.0)
            .offset(y: isAnimating ? 25 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
    }
}
