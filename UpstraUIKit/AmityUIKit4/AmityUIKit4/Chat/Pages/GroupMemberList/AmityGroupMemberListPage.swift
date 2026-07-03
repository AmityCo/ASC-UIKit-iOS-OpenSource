//
//  AmityGroupMemberListPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmityGroupMemberListViewModel: ObservableObject {
    @Published var members: [AmityChannelMember] = []
    @Published var isLoading: Bool = true
    @Published var searchText: String = ""
    @Published var activeTab: MemberTab = .members
    @Published var isModerator: Bool = false
    @Published var flaggedByMeCache: [String: Bool] = [:]
    @Published var showActionSheet: Bool = false
    var selectedMember: AmityChannelMember?

    enum MemberTab { case members, moderators }

    private let channelId: String
    private let channelManager = ChannelManager()
    private let userManager = UserManager()
    private var collection: AmityCollection<AmityChannelMember>?
    private var token: AmityNotificationToken?
    private var cancellables = Set<AnyCancellable>()

    init(channelId: String, isModerator: Bool) {
        self.channelId = channelId
        self.isModerator = isModerator
        loadMembers()
        observeSearch()
    }

    private func loadMembers() {
        isLoading = true
        let roles: [String] = activeTab == .moderators ? ["channel-moderator"] : []
        let filterBuilder = AmityChannelMembershipFilterBuilder()
        filterBuilder.add(filter: .member)
        filterBuilder.add(filter: .mute)
        collection = channelManager.searchMembers(channelId: channelId, displayName: "", filterBuilder: filterBuilder, roles: roles)
        observeCollection()
    }

    private func observeSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] keyword in
                guard let self else { return }
                self.performSearch(keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .store(in: &cancellables)
    }

    private func performSearch(keyword: String) {
        isLoading = true
        let roles: [String] = activeTab == .moderators ? ["channel-moderator"] : []
        let filterBuilder = AmityChannelMembershipFilterBuilder()
        filterBuilder.add(filter: .member)
        filterBuilder.add(filter: .mute)
        collection = channelManager.searchMembers(channelId: channelId, displayName: keyword, filterBuilder: filterBuilder, roles: roles)
        observeCollection()
    }

    private func observeCollection() {
        token?.invalidate()
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            let snapshots = col.snapshots
            let others = snapshots.filter { $0.userId != currentUserId }
            let meFromSnapshot = snapshots.first { $0.userId == currentUserId }
            let synth = self.channelManager.getCurrentUserChannelMember(channelId: self.channelId)
            let synthEligible: AmityChannelMember? = {
                guard let synth else { return nil }
                if self.activeTab == .moderators && !synth.roles.contains("channel-moderator") { return nil }
                return synth
            }()
            let me = meFromSnapshot ?? synthEligible
            self.members = (me.map { [$0] } ?? []) + others
            self.isLoading = false
        }
    }

    func switchTab(_ tab: MemberTab) {
        activeTab = tab
        searchText = ""
        loadMembers()
    }

    func loadMore() {
        guard collection?.hasNext == true else { return }
        collection?.nextPage()
    }

    func addMembers(_ userIds: [String]) async throws {
        try await channelManager.addMembers(channelId: channelId, userIds: userIds)
    }

    func removeMember(_ userId: String) async throws {
        try await channelManager.removeMembers(channelId: channelId, userIds: [userId])
    }

    func banMember(_ userId: String) async throws {
        try await channelManager.banMembers(channelId: channelId, userIds: [userId])
    }

    func unbanMember(_ userId: String) async throws {
        try await channelManager.unbanMembers(channelId: channelId, userIds: [userId])
    }

    func promoteModerator(_ userId: String) async throws {
        try await channelManager.addRole(channelId: channelId, role: "channel-moderator", userIds: [userId])
    }

    func demoteModerator(_ userId: String) async throws {
        try await channelManager.removeRole(channelId: channelId, role: "channel-moderator", userIds: [userId])
    }

    func muteMember(_ userId: String) async throws {
        try await channelManager.muteMembers(channelId: channelId, userIds: [userId], mutePeriod: -1)
    }

    func unmuteMember(_ userId: String) async throws {
        try await channelManager.unmuteMembers(channelId: channelId, userIds: [userId])
    }

    func reportUser(_ userId: String) async throws {
        Log.chat.info("reportUser → flagUser(withId: \(userId)) requested")
        do {
            try await userManager.flagUser(withId: userId)
            flaggedByMeCache[userId] = true
            Log.chat.info("reportUser ← success (userId: \(userId))")
        } catch {
            Log.chat.warning("reportUser ← FAILED (userId: \(userId)) error: \(error.localizedDescription) raw: \(error)")
            throw error
        }
    }

    func unreportUser(_ userId: String) async throws {
        Log.chat.info("unreportUser → unflagUser(withId: \(userId)) requested")
        do {
            try await userManager.unflagUser(withId: userId)
            flaggedByMeCache[userId] = false
            Log.chat.info("unreportUser ← success (userId: \(userId))")
        } catch {
            Log.chat.warning("unreportUser ← FAILED (userId: \(userId)) error: \(error.localizedDescription) raw: \(error)")
            throw error
        }
    }

    func isUserFlaggedByMe(_ userId: String) async throws -> Bool {
        let value = try await userManager.isUserFlaggedByMe(withId: userId)
        Log.chat.debug("isUserFlaggedByMe(\(userId)) → \(value)")
        return value
    }

    func refreshFlagStatus(userId: String) {
        Task {
            do {
                let flagged = try await isUserFlaggedByMe(userId)
                flaggedByMeCache[userId] = flagged
            } catch {
                Log.chat.warning("refreshFlagStatus(\(userId)) failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Page

public struct AmityGroupMemberListPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .groupMemberListPage }

    @StateObject private var viewModel: AmityGroupMemberListViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    fileprivate enum PendingAction {
        case promote(AmityChannelMember)
        case demote(AmityChannelMember)
        case mute(AmityChannelMember)
        case unmute(AmityChannelMember)
        case remove(AmityChannelMember)
        case ban(AmityChannelMember)
    }

    private let channelId: String

    public init(channelId: String, isModerator: Bool) {
        self.channelId = channelId
        self._viewModel = StateObject(wrappedValue: AmityGroupMemberListViewModel(channelId: channelId, isModerator: isModerator))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .groupMemberListPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar
            tabBar
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            memberList
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
        .bottomSheet(isShowing: $viewModel.showActionSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            Group {
                if let member = viewModel.selectedMember {
                    let isFlaggedByMe = viewModel.flaggedByMeCache[member.userId] ?? false
                    let _ = print("IsUserFlaggedByMe \(isFlaggedByMe)")
                    AmityGroupMemberActionComponent(
                        member: member,
                        isPresented: $viewModel.showActionSheet,
                        isCurrentUserModerator: viewModel.isModerator,
                        isFlaggedByMe: isFlaggedByMe,
                        onPromote: {
                            scheduleAction(.promote(member))
                        },
                        onDemote: {
                            scheduleAction(.demote(member))
                        },
                        onMute: {
                            scheduleAction(.mute(member))
                        },
                        onUnmute: {
                            scheduleAction(.unmute(member))
                        },
                        onRemove: {
                            scheduleAction(.remove(member))
                        },
                        onBan: {
                            scheduleAction(.ban(member))
                        },
                        onReport: {
                            let alreadyFlagged = viewModel.flaggedByMeCache[member.userId] ?? false
                            Task {
                                await performAction(
                                    successMessage: alreadyFlagged
                                        ? AmityLocalizedStringSet.Chat.toastUserUnreported.localizedString
                                        : AmityLocalizedStringSet.Chat.toastUserReported.localizedString,
                                    errorMessage: alreadyFlagged
                                        ? AmityLocalizedStringSet.Chat.toastUnreportUserFailed.localizedString
                                        : AmityLocalizedStringSet.Chat.toastReportUserFailed.localizedString
                                ) {
                                    if alreadyFlagged {
                                        try await viewModel.unreportUser(member.userId)
                                    } else {
                                        try await viewModel.reportUser(member.userId)
                                    }
                                }
                            }
                        }
                    )
                    .environmentObject(host)
                } else {
                    EmptyView()
                }
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.GroupMemberList.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

            HStack {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 17, height: 17)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                if viewModel.isModerator {
                    Button {
                        let page = AmityAddGroupMemberPage(channelId: channelId)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    } label: {
                        Image(AmityIcon.Chat.chatCreationButton.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                tabButton(AmityLocalizedStringSet.Chat.GroupMemberList.tabMembers.localizedString, tab: .members)
                tabButton(AmityLocalizedStringSet.Chat.GroupMemberList.tabModerators.localizedString, tab: .moderators)
                Spacer()
            }
            .padding(.horizontal, 16)
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func tabButton(_ title: String, tab: AmityGroupMemberListViewModel.MemberTab) -> some View {
        let isSelected = viewModel.activeTab == tab
        return Button {
            viewModel.switchTab(tab)
        } label: {
            VStack(spacing: 0) {
                Text(title)
                    .applyTextStyle(.titleBold(isSelected ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.baseColorShade2)))
                    .padding(.vertical, 12)
                Rectangle()
                    .fill(isSelected ? Color(viewConfig.theme.primaryColor) : Color.clear)
                    .frame(height: 2)
            }
        }
        .fixedSize()
        .buttonStyle(.plain)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.Chat.searchButtonIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 14, height: 14)

            TextField(AmityLocalizedStringSet.Chat.GroupMemberList.searchPlaceholder.localizedString, text: $viewModel.searchText)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))

            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(AmityIcon.Chat.grayCloseIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(viewConfig.theme.baseColorShade4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Member list

    private var memberList: some View {
        Group {
            if viewModel.isLoading && viewModel.members.isEmpty {
                skeletonList
            } else if viewModel.members.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.members.enumerated()), id: \.element.userId) { index, member in
                            memberRow(member)
                                .onAppear {
                                    if index == viewModel.members.count - 1 { viewModel.loadMore() }
                                }
                        }
                    }
                }
                .background(Color(viewConfig.theme.backgroundColor))
            }
        }
    }

    private func memberRow(_ member: AmityChannelMember) -> some View {
        let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
        let isCurrentUser = member.userId == currentUserId
        let isMemberModerator = member.roles.contains("channel-moderator")
        let displayName = member.user?.displayName ?? member.userId

        return HStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AmityUserProfileImageView(displayName: displayName, avatarURL: {
                    if let urlStr = member.user?.getAvatarInfo()?.fileURL { return URL(string: urlStr) }
                    return nil
                }())
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                if isMemberModerator {
                    Color(viewConfig.theme.primaryColor.blend(.shade3))
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 16, height: 16)
                        )
                }
            }

            HStack(spacing: 0) {
                Text(displayName)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if isCurrentUser {
                    Text(AmityLocalizedStringSet.Chat.memberYouSuffix.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .fixedSize()
                        .padding(.leading, 4)
                }
                if member.user?.isBrand == true {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .fixedSize()
                        .padding(.leading, 4)
                }
                let _ = print("moderator \(viewModel.isModerator) muted \(member.isMuted)")
                if viewModel.isModerator && member.isMuted {
                    Image(AmityIcon.Chat.mutedMemberIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .fixedSize()
                        .padding(.leading, 2)
                }
            }

            Spacer()

            if !isCurrentUser {
                Button {
                    selectMember(member)
                } label: {
                    Image(AmityIcon.Chat.ellipsisIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color(viewConfig.theme.backgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCurrentUser {
                selectMember(member)
            }
        }
    }

    private func selectMember(_ member: AmityChannelMember) {
        viewModel.selectedMember = member
        viewModel.showActionSheet.toggle()
        let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
        if member.userId != currentUserId {
            viewModel.refreshFlagStatus(userId: member.userId)
        }
    }

    // MARK: - Action helpers

    private func scheduleAction(_ action: PendingAction) {
        viewModel.showActionSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            presentConfirmation(for: action)
        }
    }

    private func presentConfirmation(for action: PendingAction) {
        let strings = AmityLocalizedStringSet.Chat.GroupMemberList.self
        let title: String
        let message: String
        let confirmTitle: String
        let confirmStyle: UIAlertAction.Style
        let run: () -> Void

        switch action {
        case .promote(let m):
            title = strings.promoteTitle.localizedString
            message = strings.promoteMessage.localizedString
            confirmTitle = strings.promoteConfirm.localizedString
            confirmStyle = .default
            run = { Task { await runPromote(m) } }
        case .demote(let m):
            title = strings.demoteTitle.localizedString
            message = strings.demoteMessage.localizedString
            confirmTitle = strings.demoteConfirm.localizedString
            confirmStyle = .destructive
            run = { Task { await runDemote(m) } }
        case .mute(let m):
            title = strings.muteTitle.localizedString
            message = strings.muteMessage.localizedString
            confirmTitle = strings.muteConfirm.localizedString
            confirmStyle = .destructive
            run = { Task { await runMute(m) } }
        case .unmute(let m):
            title = strings.unmuteTitle.localizedString
            message = strings.unmuteMessage.localizedString
            confirmTitle = strings.unmuteConfirm.localizedString
            confirmStyle = .default
            run = { Task { await runUnmute(m) } }
        case .remove(let m):
            title = strings.removeTitle.localizedString
            message = strings.removeMessage.localizedString
            confirmTitle = strings.removeConfirm.localizedString
            confirmStyle = .destructive
            run = { Task { await runRemove(m) } }
        case .ban(let m):
            title = strings.banTitle.localizedString
            message = strings.banMessage.localizedString
            confirmTitle = strings.banConfirm.localizedString
            confirmStyle = .destructive
            run = { Task { await runBan(m) } }
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: strings.cancel.localizedString,
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: confirmTitle,
            style: confirmStyle
        ) { _ in run() })

        host.controller?.present(alert, animated: true)
    }

    private func runPromote(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastPromoted.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastPromoteError.localizedString
        ) { try await viewModel.promoteModerator(m.userId) }
    }

    private func runDemote(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastDemoted.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastDemoteError.localizedString
        ) { try await viewModel.demoteModerator(m.userId) }
    }

    private func runMute(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastMuted.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastMuteError.localizedString
        ) { try await viewModel.muteMember(m.userId) }
    }

    private func runUnmute(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastUnmuted.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastUnmuteError.localizedString
        ) { try await viewModel.unmuteMember(m.userId) }
    }

    private func runRemove(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastRemoved.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastRemoveError.localizedString
        ) { try await viewModel.removeMember(m.userId) }
    }

    private func runBan(_ m: AmityChannelMember) async {
        await performAction(
            successMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastBanned.localizedString,
            errorMessage: AmityLocalizedStringSet.Chat.GroupMemberList.toastBanError.localizedString
        ) { try await viewModel.banMember(m.userId) }
    }

    private func performAction(
        successMessage: String,
        errorMessage: String,
        action: @escaping () async throws -> Void
    ) async {
        do {
            try await action()
            toastStyle = .success
            toastMessage = successMessage
        } catch {
            toastStyle = .warning
            toastMessage = errorMessage
        }
        showToast = true
    }

    // MARK: - Skeleton / Empty

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 8) {
                        Circle().fill(Color(viewConfig.theme.baseColorShade4)).frame(width: 40, height: 40)
                        RoundedRectangle(cornerRadius: 4).fill(Color(viewConfig.theme.baseColorShade4)).frame(width: 160, height: 14)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 56)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(AmityIcon.Chat.searchNotFoundIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 47, height: 47)
            Text(AmityLocalizedStringSet.Chat.GroupMemberList.empty.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
