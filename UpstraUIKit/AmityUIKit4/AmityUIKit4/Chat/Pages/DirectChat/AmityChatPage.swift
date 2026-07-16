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
                    if let urlStr = user.getAvatarInfo()?.fileURL {
                        self.avatarURL = URL(string: urlStr)
                    }
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
            if let urlStr = user.getAvatarInfo()?.fileURL {
                self.avatarURL = URL(string: urlStr)
            }
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

                    if pageViewModel.isBlocked {
                        blockedBar
                    } else {
                        AmityChatMessageComposeBar(viewModel: liveChatViewModel)
                            .isHidden(messageViewModel.initialQueryState != .success
                                      || (messageViewModel.muteState != .none && !messageViewModel.hasModeratorPermission))
                    }
                }
                .showToast(isPresented: $liveChatViewModel.showToast,
                           style: liveChatViewModel.toastMessage.style,
                           message: liveChatViewModel.toastMessage.message,
                           bottomPadding: 80)

                VStack {
                    Spacer()
                    ToastView(message: AmityLocalizedStringSet.Chat.toastLoading.localizedString, style: .loading)
                        .padding(.bottom, 24)
                }
                .opacity(messageViewModel.initialQueryState == .loading ? 1 : 0)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .onAppear {
            pageViewModel.loadChannelInfo()
        }
        .onChange(of: pageViewModel.displayName) { name in
            liveChatViewModel.channelDisplayName = name
        }
        .bottomSheet(isShowing: $showActionSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
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
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastUserUnreported.localizedString, style: .success)
                            } catch {
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastUnreportUserFailed.localizedString, style: .warning)
                            }
                        }
                    } else {
                        Task {
                            do {
                                try await pageViewModel.reportUser()
                                liveChatViewModel.showToastMessage(message: AmityLocalizedStringSet.Chat.toastUserReported.localizedString, style: .success)
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

    private var dmHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    host.controller?.dismissOrPop()
                } label: {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)

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
                    if pageViewModel.isOtherUserDeleted {
                        ZStack {
                            Circle()
                                .fill(Color(viewConfig.theme.secondaryColor.blend(.shade2)))
                            Image(AmityIcon.Chat.deletedUserAvatarIcon.imageResource)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(viewConfig.theme.backgroundColor))
                                .frame(width: 15, height: 16)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        AmityUserProfileImageView(displayName: pageViewModel.displayName, avatarURL: pageViewModel.avatarURL)
                            .frame(width: 40, height: 40)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)

                VStack(alignment: .leading, spacing: 2) {
                    if pageViewModel.isLoadingHeader {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 120, height: 14)
                    } else {
                        Text(pageViewModel.displayName)
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                            .lineLimit(1)
                    }

                    if !networkMonitor.isConnected {
                        HStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                            Text(AmityLocalizedStringSet.Chat.Home.waitingForNetwork.localizedString)
                                .applyTextStyle(.custom(12, .regular, Color(viewConfig.theme.baseColorShade1)))
                        }
                    }
                }

                Spacer()

                if AmityUIKitConfigController.shared.hasAnyEnabledChatUserAction() {
                    Button {
                        showActionSheet = true
                    } label: {
                        Image(AmityIcon.Chat.threeDotVerticalIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(viewConfig.theme.backgroundColor))

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
        }
    }

    // MARK: - Blocked bar

    private var blockedBar: some View {
        HStack {
            Spacer()
            Text(AmityLocalizedStringSet.Chat.DM.blockedBanner.localizedString)
                .applyTextStyle(.custom(14, .regular, Color(viewConfig.theme.baseColorShade1)))
            Spacer()
        }
        .frame(height: 42)
        .background(Color(viewConfig.theme.baseColorShade4))
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
