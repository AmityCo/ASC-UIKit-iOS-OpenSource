//
//  AmityChatPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmityChatPageViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var avatarURL: URL?
    @Published var otherUserId: String?
    @Published var isBlocked: Bool = false
    @Published var isMuted: Bool = false
    @Published var isReportedByMe: Bool = false
    @Published var isLoadingHeader: Bool = true
    @Published var isOtherUserDeleted: Bool = false

    private let channelId: String
    private let userManager = UserManager()
    private let channelManager = ChannelManager()
    private var channelToken: AmityNotificationToken?
    private var membersToken: AmityNotificationToken?
    private var otherUserToken: AmityNotificationToken?
    private var followInfoToken: AmityNotificationToken?

    init(channelId: String) {
        self.channelId = channelId
    }

    deinit {
        channelToken?.invalidate()
        channelToken = nil
        membersToken?.invalidate()
        membersToken = nil
        otherUserToken?.invalidate()
        otherUserToken = nil
        followInfoToken?.invalidate()
        followInfoToken = nil
    }

    func loadChannelInfo() {
        let channelObject = channelManager.getChannel(channelId: channelId)
        channelToken = channelObject.observe { [weak self] obj, _ in
            guard let self, let ch = obj.snapshot else { return }
            if ch.channelType != .conversation {
                self.displayName = ch.displayName ?? ""
                if let urlStr = ch.getAvatarInfo()?.fileURL {
                    self.avatarURL = URL(string: urlStr)
                }
            }
            self.isMuted = ch.isMuted
        }

        let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
        let membersCollection = channelManager.getMembers(channelId: channelId)
        membersToken = membersCollection.observe { [weak self] col, _ in
            guard let self else { return }
            if self.otherUserId != nil { return }
            let members = col.snapshots
            guard let other = members.first(where: { $0.userId != currentUserId }) else {
                return
            }
            let otherUID = other.userId
            self.otherUserId = otherUID
            if let user = other.user {
                if user.isDeleted {
                    self.isOtherUserDeleted = true
                    self.displayName = AmityLocalizedStringSet.Chat.deletedUser.localizedString
                    self.avatarURL = nil
                } else {
                    self.isOtherUserDeleted = false
                    if let name = user.displayName, !name.isEmpty {
                        self.displayName = name
                    }
                    self.avatarURL = user.resolvedAvatarURL
                }
            }
            self.isLoadingHeader = false
            self.checkBlockStatus(otherUserId: otherUID)
            self.loadReportStatus(otherUserId: otherUID)
            self.observeOtherUserLive(userId: otherUID)
            self.membersToken?.invalidate()
            self.membersToken = nil
        }
    }

    private func observeOtherUserLive(userId: String) {
        otherUserToken?.invalidate()
        let userObject = userManager.getUser(withId: userId)
        otherUserToken = userObject.observe { [weak self] obj, _ in
            guard let self, let user = obj.snapshot else { return }
            if user.isDeleted {
                self.isOtherUserDeleted = true
                self.displayName = AmityLocalizedStringSet.Chat.deletedUser.localizedString
                self.avatarURL = nil
                return
            }
            self.isOtherUserDeleted = false
            if let name = user.displayName, !name.isEmpty {
                self.displayName = name
            }
            self.avatarURL = user.resolvedAvatarURL
        }
    }

    private func checkBlockStatus(otherUserId: String) {
        let followInfoObject = userManager.getFollowInfo(withId: otherUserId)
        followInfoToken = followInfoObject.observe { [weak self] obj, _ in
            guard let self, let info = obj.snapshot else { return }
            self.isBlocked = info.status == .blocked
        }
    }

    private func loadReportStatus(otherUserId: String) {
        Task {
            do {
                let flagged = try await userManager.isUserFlaggedByMe(withId: otherUserId)
                self.isReportedByMe = flagged
            } catch { }
        }
    }

    // MARK: - Block / Unblock

    func blockUser() async throws {
        guard let userId = otherUserId else { return }
        try await userManager.blockUser(withId: userId)
    }

    func unblockUser() async throws {
        guard let userId = otherUserId else { return }
        try await userManager.unblockUser(withId: userId)
    }

    // MARK: - Mute / Unmute

    func muteChannel() async throws {
        let manager = channelManager.notificationManager(channelId: channelId)
        try await manager.disable()
        isMuted = true
    }

    func unmuteChannel() async throws {
        let manager = channelManager.notificationManager(channelId: channelId)
        try await manager.enable()
        isMuted = false
    }

    // MARK: - Report / Unreport user

    func reportUser() async throws {
        guard let userId = otherUserId else { return }
        try await userManager.flagUser(withId: userId)
        isReportedByMe = true
    }

    func unreportUser() async throws {
        guard let userId = otherUserId else { return }
        try await userManager.unflagUser(withId: userId)
        isReportedByMe = false
    }
}

// MARK: - Page

public struct AmityChatPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .chatPage }

    private let channelId: String
    private let jumpToMessageId: String?

    @StateObject private var pageViewModel: AmityChatPageViewModel
    @StateObject private var liveChatViewModel: AmityChatRoomViewModel
    @StateObject private var messageViewModel: AmityChatMessageListViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var showActionSheet = false
    @State private var showMuteToast = false
    @State private var muteToastMessage = ""

    public init(channelId: String, jumpToMessageId: String? = nil) {
        self.channelId = channelId
        self.jumpToMessageId = jumpToMessageId
        let lvm = AmityChatRoomViewModel(channelId: channelId, aroundMessageId: jumpToMessageId)
        self._pageViewModel = StateObject(wrappedValue: AmityChatPageViewModel(channelId: channelId))
        self._liveChatViewModel = StateObject(wrappedValue: lvm)
        self._messageViewModel = StateObject(wrappedValue: lvm.messageList)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .chatPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            dmHeader

            ZStack {
                VStack(spacing: 0) {
                    AmityChatMessageListComponent(viewModel: liveChatViewModel, pageId: .chatPage)
                        // Anchored to the message list so the toast sits just above the
                        // compose bar divider (independent of the compose bar's height).
                        .showToast(isPresented: $liveChatViewModel.showToast,
                                   style: liveChatViewModel.toastMessage.style,
                                   message: liveChatViewModel.toastMessage.message,
                                   bottomPadding: 8)

                    // Loading toast sits 16pt above the compose bar divider (Figma 12041:242294)
                    if messageViewModel.initialQueryState == .loading {
                        ToastView(message: AmityLocalizedStringSet.Chat.toastLoading.localizedString, style: .loading)
                            .padding(.bottom, 16)
                    }

                    if pageViewModel.isBlocked {
                        blockedBar
                    } else {
                        AmityChatMessageComposeBar(viewModel: liveChatViewModel)
                            // Visible during initial load too (Figma 12041:242294); hidden only on error/banned or when muted without permission.
                            .isHidden((messageViewModel.initialQueryState != .success && messageViewModel.initialQueryState != .loading)
                                      || (messageViewModel.muteState != .none && !messageViewModel.hasModeratorPermission))
                    }
                }
            }
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .onAppear {
            pageViewModel.loadChannelInfo()
        }
        .onChange(of: pageViewModel.displayName) { name in
            liveChatViewModel.channelDisplayName = name
        }
        .bottomSheet(isShowing: $showActionSheet, height: .contentSize, backgroundColor: Color(viewConfig.color(.surfaceSheetsBackgroundGeneral))) {
            AmityConversationChatUserActionComponent(
                isMuted: pageViewModel.isMuted,
                isReportedByMe: pageViewModel.isReportedByMe,
                isBlocked: pageViewModel.isBlocked,
                pageId: .chatPage,
                onMuteUnmute: {
                    showActionSheet = false
                    if pageViewModel.isMuted {
                        Task {
                            do {
                                try await pageViewModel.unmuteChannel()
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastNotificationsOn.localizedString, style: .success)
                            } catch {
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastUnmuteFailed.localizedString, style: .warning)
                            }
                        }
                    } else {
                        Task {
                            do {
                                try await pageViewModel.muteChannel()
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastNotificationsOff.localizedString, style: .success)
                            } catch {
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastMuteFailed.localizedString, style: .warning)
                            }
                        }
                    }
                },
                onReportUnreport: {
                    showActionSheet = false
                    if pageViewModel.isReportedByMe {
                        Task {
                            do {
                                try await pageViewModel.unreportUser()
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastDirectUserUnreported.localizedString, style: .success)
                            } catch {
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastUnreportUserFailed.localizedString, style: .warning)
                            }
                        }
                    } else {
                        Task {
                            do {
                                try await pageViewModel.reportUser()
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastDirectUserReported.localizedString, style: .success)
                            } catch {
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastReportUserFailed.localizedString, style: .warning)
                            }
                        }
                    }
                },
                onBlockUnblock: {
                    showActionSheet = false
                    let isCurrentlyBlocked = pageViewModel.isBlocked
                    let displayName = pageViewModel.displayName
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let keyWindow = UIApplication.shared.connectedScenes
                            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                            .first { $0.isKeyWindow }
                        guard let rootVC = keyWindow?.rootViewController else { return }
                        var topVC = rootVC
                        while let presented = topVC.presentedViewController {
                            topVC = presented
                        }

                        let title = isCurrentlyBlocked
                            ? AmityLocalizedStringSet.Chat.DM.unblockUserTitle.localizedString
                            : AmityLocalizedStringSet.Chat.DM.blockUserTitle.localizedString
                        let message = isCurrentlyBlocked
                            ? AmityLocalizedStringSet.Chat.DM.unblockUserMessage.localized(arguments: displayName)
                            : AmityLocalizedStringSet.Chat.DM.blockUserMessage.localized(arguments: displayName)
                        let confirmTitle = isCurrentlyBlocked
                            ? AmityLocalizedStringSet.Chat.DM.unblockUserConfirm.localizedString
                            : AmityLocalizedStringSet.Chat.DM.blockUserConfirm.localizedString

                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel))
                        alert.addAction(UIAlertAction(
                            title: confirmTitle,
                            style: .destructive
                        ) { _ in
                            Task {
                                if isCurrentlyBlocked {
                                    do {
                                        try await pageViewModel.unblockUser()
                                        liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastUserUnblocked.localizedString, style: .success)
                                    } catch {
                                        liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastUnblockFailed.localizedString, style: .warning)
                                    }
                                } else {
                                    do {
                                        try await pageViewModel.blockUser()
                                        liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastUserBlocked.localizedString, style: .success)
                                    } catch {
                                        liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.DMAction.toastBlockFailed.localizedString, style: .warning)
                                    }
                                }
                            }
                        })
                        topVC.present(alert, animated: true)
                    }
                }
            )
            .environmentObject(viewConfig)
            .padding(.bottom, 32)
        }
    }

    // MARK: - DM Header

    // Header skeleton stays until BOTH the channel/user info and the initial
    // messages have loaded. isLoadingHeader alone resolves from local cache almost
    // instantly, so on its own the skeleton would vanish before messages arrive.
    private var isHeaderLoading: Bool {
        pageViewModel.isLoadingHeader || messageViewModel.initialQueryState == .loading
    }

    private var dmHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    // The chat room is PUSHED onto the nav stack by AmityChatHomePage,
                    // so "back" must POP. dismissOrPop() checks presentingViewController
                    // first and dismisses the whole modal (closing the UIKit) when the
                    // nav stack itself was presented — the reported bug. Prefer popping
                    // whenever we're not the root of the nav stack; fall back otherwise.
                    if let nav = host.controller?.navigationController,
                       nav.viewControllers.count > 1 {
                        nav.popViewController(animated: true)
                    } else {
                        host.controller?.dismissOrPop()
                    }
                } label: {
                    Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .frame(width: 24, height: 24)  // Figma 10848:54642: chevron glyph 24pt
                        // Expand the tappable region to the 44x44 HIG minimum without
                        // moving the glyph or eating into the avatar: the frame grows
                        // 10pt on each side of the 24pt glyph, so negative padding pulls
                        // that growth back — leading -10 keeps the chevron 16pt from the
                        // edge, trailing (12 - 10 = +2) preserves the original 12pt visual
                        // gap to the avatar. contentShape makes the whole frame tappable.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, -10)
                .padding(.trailing, 2)

                Button {
                    if let userId = pageViewModel.otherUserId {
                        let ctx = AmityChatPageBehavior.Context(
                            page: self,
                            userId: userId,
                            avatarURL: pageViewModel.avatarURL
                        )
                        AmityUIKit4Manager.behaviour.chatPageBehavior?.onAvatarTap(context: ctx)
                    }
                } label: {
                    if isHeaderLoading {
                        // Skeleton avatar while channel/user info loads (Figma 12041:242294)
                        Circle()
                            .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                            .frame(width: 40, height: 40)
                            .shimmering()
                    } else if pageViewModel.isOtherUserDeleted {
                        ZStack {
                            // Token-less composite: DS has no surface token for the deleted-user
                            // avatar disc — keep the legacy theme fills (matches Task 2 / ChatListItemView).
                            Circle()
                                .fill(Color(viewConfig.theme.secondaryColor.blend(.shade2)))
                            Image(AmityIcon.DesignSystem.userS.imageResource)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                                .frame(width: 15, height: 16)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        AmityChatUserProfileImageView(displayName: pageViewModel.displayName, avatarURL: pageViewModel.avatarURL)
                            .frame(width: 40, height: 40)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)  // 12pt gap avatar → name

                VStack(alignment: .leading, spacing: 2) {
                    if isHeaderLoading {
                        // Skeleton title bar (Figma 12041:242294 → 140×10, fully rounded)
                        Capsule()
                            .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                            .frame(width: 140, height: 10)
                            .shimmering()
                    } else {
                        Text(pageViewModel.displayName)
                            .applyTextStyle(.bodyBold(Color(viewConfig.color(.textBannerDefaultHeaderGeneral))))
                            .lineLimit(1)
                    }

                    if !networkMonitor.isConnected {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                            Text(AmityLocalizedStringSet.Chat.Home.waitingForNetwork.localizedString)
                                .applyTextStyle(.custom(12, .regular, Color(viewConfig.color(.textListSubheadDefaultDefault))))
                        }
                    }
                }

                Spacer()

                if AmityUIKitConfigController.shared.hasAnyEnabledChatUserAction() {
                    Button {
                        showActionSheet = true
                    } label: {
                        Image(AmityIcon.DesignSystem.ellipsisVR.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                            .frame(width: 24, height: 24)  // 24pt glyph in a 32pt icon-button box
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)  // overflow meatball 32pt box
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color(viewConfig.color(.surfaceBannerDefaultGeneral)))

            Rectangle()
                .fill(Color(viewConfig.color(.lineDividerPostDefault)))
                .frame(height: 1)
        }
    }

    // MARK: - Blocked bar

    private var blockedBar: some View {
        HStack {
            Spacer()
            Text(AmityLocalizedStringSet.Chat.DM.blockedBanner.localizedString)
                .applyTextStyle(.custom(14, .regular, Color(viewConfig.color(.textBannerSubdueSubheadGeneral))))
            Spacer()
        }
        .frame(height: 42)
        .background(Color(viewConfig.color(.surfaceBannerSubdueGeneral)))
    }

    // MARK: - Navigation

    private func navigateToUserProfile(userId: String) {
        let profilePage = AmityUserProfilePage(userId: userId)
        let vc: UIViewController = AmitySwiftUIHostingController(rootView: profilePage)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - DM User Action Bottom Sheet

#if DEBUG
#Preview {
    AmityChatPage(channelId: "")
}
#endif
