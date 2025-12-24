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
    
    public init(viewModel: AmityLiveStreamChatViewModel, pageId: PageId? = nil) {
        self.pageId = pageId
        self.viewModel = viewModel
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .livestreamChatFeed))
    }
    
    public var body: some View {
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
        .updateTheme(with: viewConfig)
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
        LinearGradient(
            colors: [Color.black.opacity(0),
                     Color.black.opacity(0.7),
                     Color.black.opacity(0.8),
                     Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func getMessageBubble(_ message: MessageModel, isModerator: Bool, isMuted: Bool, isHost: Bool, isCoHost: Bool) -> some View {
        HStack(alignment: message.syncState == .error ? .center : .top, spacing: 8) {
            // User name and message content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(message.displayName)
                        .applyTextStyle(.captionSmall(Color(viewConfig.theme.baseColorShade1)))
                        .lineLimit(1)
                        .onTapGesture {
                            // Host cannot moderate Co-host
                            // but can remove from livestream
                            if viewModel.isHost && (isCoHost || viewModel.isWaitingCoHost?().1 == message.userId) {
                                viewModel.removeCoHostAction?()
                                return
                            }
                            
                            // Only streamer and moderators can see moderation options
                            guard viewModel.isStreamer || viewModel.isModerator(userId: AmityUIKitManagerInternal.shared.currentUserId) else { return }
                            
                            // Moderation options cannot be applied to host, Co-host and self
                            guard !isHost && !isCoHost && AmityUIKitManagerInternal.shared.currentUserId != message.userId else { return }
                            
                            viewModel.showModerationBottomSheet.message = message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.showModerationBottomSheet.show.toggle()
                            }
                        }
                    
                    let isBrand = message.user?.isBrand ?? false
                    
                    if isBrand {
                        Image(AmityIcon.brandBadge.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    
                    if isHost {
                        HostBadgeView()
                    } else if isCoHost {
                        CoHostBadgeView()
                    } else if isModerator {
                        ModeratorBadgeView()
                    }
                    
                    // Moderator only can see muted badge
                    if isMuted && (viewModel.isModerator(userId: AmityUIKitManagerInternal.shared.currentUserId) || viewModel.isStreamer) {
                        Image(AmityIcon.clipMuteIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                            .frame(width: 16, height: 14)
                    }
                }
                
                // Message content
                if message.isDeleted {
                    HStack(spacing: 6) {
                        Image(AmityIcon.trashBinIcon.getImageResource())
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                            .frame(width: 16, height: 18)
                            .offset(y: -1)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamChatDeletedMessage.localizedString)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
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
            } else if !message.isDeleted {
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
            }
        }
        .padding(.all, 12)
        .background(Color(UIColor(hex: "#636878")).opacity(0.3))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            let message = viewModel.showBottomSheet.message
                       
            if message?.userId != AmityUIKitManagerInternal.shared.currentUserId {
                let isFlagged = viewModel.showBottomSheet.message?.isFlaggedByMe ?? false
                let title = isFlagged ? AmityLocalizedStringSet.LiveChat.unreportMessage.localizedString : AmityLocalizedStringSet.LiveChat.reportMessage.localizedString
                
                BottomSheetItemView(icon: AmityIcon.flagIcon.getImageResource(), text: title)
                    .onTapGesture {
                        guard let message = viewModel.showBottomSheet.message else { return }
                        viewModel.showBottomSheet.show.toggle()
                        
                        AmityUserAction.perform(host: host) {
                            if isFlagged {
                                Task.runOnMainActor {
                                    try await viewModel.unflagMessage(message.id)
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.toastUnReportMessage.localizedString, bottomPadding: 60)
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    let page = AmityContentReportPage(type: .message(id: message.id)).environmentObject(viewConfig)
                                    let vc = AmitySwiftUIHostingNavigationController(rootView: page)
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
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationSentToast.localizedString, bottomPadding: 60)
                                    if let user = message?.user {
                                        viewModel.didFinishCoHostInvitationAction?(AmityUserModel(user: user))
                                    }
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationSendFailedToast.localizedString, bottomPadding: 60)
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
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.demoteSuccessToastMessage.localizedString, bottomPadding: 60)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.demoteFailedToastMessage.localizedString, bottomPadding: 60)
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
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.promoteSuccessToastMessage.localizedString, bottomPadding: 60)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.promoteFailedToastMessage.localizedString, bottomPadding: 60)
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
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.unmuteSuccessToastMessage.localizedString, bottomPadding: 60)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.unmuteFailedToastMessage.localizedString, bottomPadding: 60)
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
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.LiveChat.muteSuccessToastMessage.localizedString, bottomPadding: 60)
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.LiveChat.muteFailedToastMessage.localizedString, bottomPadding: 60)
                                    }
                                }
                            }
                        }
                }
            }
        }
        .padding(.bottom, 48)
    }
    
    private func showErrorActionSheet(message: MessageModel) {
        let alert = UIAlertController(title: AmityLocalizedStringSet.Social.livestreamChatMessageNotSentTitle.localizedString, message: nil, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = .dark

        let deleteAction = UIAlertAction(title: AmityLocalizedStringSet.Social.livestreamChatDeleteAction.localizedString, style: .destructive) { _ in
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
            alert.overrideUserInterfaceStyle = .dark
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
