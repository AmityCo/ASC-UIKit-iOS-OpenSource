//
//  AmityGroupSettingPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmityGroupSettingViewModel: ObservableObject {
    @Published var channel: AmityChannel?
    @Published var displayName: String = ""
    @Published var avatarURL: URL?
    @Published var isModerator: Bool = false
    @Published var isLoading: Bool = true
    @Published var isNotificationsEnabled: Bool = true

    private let channelId: String
    private let channelManager = ChannelManager()
    private var channelToken: AmityNotificationToken?

    init(channelId: String, isModerator: Bool) {
        self.channelId = channelId
        self.isModerator = isModerator
    }

    deinit {
        channelToken?.invalidate()
        channelToken = nil
    }

    func loadChannelInfo() {
        let obj = channelManager.getChannel(channelId: channelId)
        channelToken = obj.observe { [weak self] obj, _ in
            guard let self, let ch = obj.snapshot else { return }
            self.channel = ch
            self.displayName = ch.displayName ?? ""
            if let urlStr = ch.getAvatarInfo()?.mediumFileURL {
                self.avatarURL = URL(string: urlStr)
            }
            let roles = ch.currentMember?.roles ?? []
            self.isModerator = roles.contains("channel-moderator")
            self.isLoading = false
        }
        let channel = obj.snapshot
        channel?.subscribeEvent(completion: { isSuccess, _ in
            if !isSuccess {
                Log.chat.warning("Failed to subscribe to events for channel \(self.channelId)")
            }
        })
        loadNotificationStatus()
    }

    func loadNotificationStatus() {
        let manager = channelManager.notificationManager(channelId: channelId)
        Task {
            do {
                let settings = try await manager.getSettings()
                self.isNotificationsEnabled = settings.isEnabled
            } catch {
                self.isNotificationsEnabled = true
            }
        }
    }

    func leaveChannel() async throws {
        try await channelManager.leaveChannel(channelId: channelId)
    }
}

// MARK: - Page

public struct AmityGroupSettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .groupSettingPage }

    @StateObject private var viewModel: AmityGroupSettingViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var activeAlert: GroupSettingAlert?
    private enum GroupSettingAlert: Identifiable {
        case leaveConfirm
        case lastModerator
        var id: Self { self }
    }
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    public init(channelId: String, isModerator: Bool) {
        self._viewModel = StateObject(wrappedValue: AmityGroupSettingViewModel(channelId: channelId, isModerator: isModerator))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .groupSettingPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                settingsList
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: .success, message: toastMessage, bottomPadding: 80)
        .onAppear { viewModel.loadChannelInfo() }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .leaveConfirm:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveGroupConfirm.localizedString),
                    primaryButton: .destructive(Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveConfirm.localizedString)) {
                        Task {
                            do {
                                try await viewModel.leaveChannel()
                                let navVC = host.controller?.navigationController
                                if navVC?.popToViewController(AmityChatHomePage.self, animated: true) == nil {
                                    navVC?.popViewController(animated: true)
                                }
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Chat.GroupSetting.toastLeft.localizedString)
                            } catch {
                                toastMessage = AmityLocalizedStringSet.Chat.GroupSetting.leaveFailed.localizedString
                                showToast = true
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .lastModerator:
                return Alert(
                    title: Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveLastModTitle.localizedString),
                    message: Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveLastModMessage.localizedString),
                    primaryButton: .default(Text(AmityLocalizedStringSet.Chat.GroupSetting.promoteMemberCTA.localizedString)) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityGroupMemberListPage(channelId: channel.channelId, isModerator: viewModel.isModerator)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(viewModel.displayName)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .padding(.horizontal, 56)
                .frame(maxWidth: .infinity)

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
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Settings list

    private var settingsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(placeholderView: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                        Image(AmityIcon.Chat.groupAvatarPlaceholderIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 53, height: 48)
                    }
                }, url: viewModel.avatarURL)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .frame(width: 120, height: 120)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)

                if viewModel.isModerator {
                    sectionHeader(AmityLocalizedStringSet.Chat.GroupSetting.sectionGroup.localizedString)
                    settingTile(icon: AmityIcon.Chat.editGroupProfileIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tileProfile.localizedString) {
                        guard let channel = viewModel.channel else { return }
                        let onSaved: () -> Void = {
                            host.controller?.navigationController?.popViewController(animated: true)
                        }
                        let page = AmityEditGroupProfilePage(channelId: channel.channelId, displayName: viewModel.displayName, avatarURL: viewModel.avatarURL, onSaved: onSaved)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                    settingTile(icon: AmityIcon.Chat.editGroupNotificationIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tileNotifications.localizedString, trailing: notificationModeLabel()) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityEditGroupNotificationPage(channelId: channel.channelId, currentMode: channel.notificationMode.rawValue)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                    settingTile(icon: AmityIcon.Chat.editMemberPermissionIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tilePermissions.localizedString) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityEditGroupMemberPermissionsPage(channelId: channel.channelId, isMuted: channel.isMuted)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                    settingTile(icon: AmityIcon.Chat.groupMemberListButtonIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tileAllMembers.localizedString) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityGroupMemberListPage(channelId: channel.channelId, isModerator: viewModel.isModerator)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                    settingTile(icon: AmityIcon.Chat.banMemberButtonIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tileBanned.localizedString) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityBannedGroupMemberListPage(channelId: channel.channelId, isModerator: viewModel.isModerator)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }

                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)

                    Spacer().frame(height: 24)

                    sectionHeader(AmityLocalizedStringSet.Chat.GroupSetting.sectionPreferences.localizedString)
                    settingTile(
                        icon: AmityIcon.Chat.editGroupNotificationIcon.imageResource,
                        title: AmityLocalizedStringSet.Chat.GroupSetting.tileMyNotifications.localizedString,
                        trailing: viewModel.isNotificationsEnabled ? AmityLocalizedStringSet.Chat.GroupSetting.toggleOn.localizedString : AmityLocalizedStringSet.Chat.GroupSetting.toggleOff.localizedString
                    ) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityGroupNotificationPreferencePage(channelId: channel.channelId, isSilentByModerator: channel.notificationMode == .silent)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }

                    Spacer().frame(height: 16)

                    Button {
                        if viewModel.isModerator,
                           let count = viewModel.channel?.moderatorCount,
                           count <= 1 {
                            activeAlert = .lastModerator
                        } else {
                            activeAlert = .leaveConfirm
                        }
                    } label: {
                        Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveButton.localizedString)
                            .applyTextStyle(.custom(16, .semibold, Color(viewConfig.theme.alertColor)))
                    }
                    .buttonStyle(.plain)
                } else {
                    sectionHeader(AmityLocalizedStringSet.Chat.GroupSetting.sectionGroup.localizedString)
                    settingTile(icon: AmityIcon.Chat.groupMemberListButtonIcon.imageResource, title: AmityLocalizedStringSet.Chat.GroupSetting.tileAllMembers.localizedString) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityGroupMemberListPage(channelId: channel.channelId, isModerator: viewModel.isModerator)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }

                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 1)

                    Spacer().frame(height: 24)

                    sectionHeader(AmityLocalizedStringSet.Chat.GroupSetting.sectionPreferences.localizedString)
                    settingTile(
                        icon: AmityIcon.Chat.editGroupNotificationIcon.imageResource,
                        title: AmityLocalizedStringSet.Chat.GroupSetting.tileMyNotifications.localizedString,
                        trailing: viewModel.isNotificationsEnabled ? AmityLocalizedStringSet.Chat.GroupSetting.toggleOn.localizedString : AmityLocalizedStringSet.Chat.GroupSetting.toggleOff.localizedString
                    ) {
                        guard let channel = viewModel.channel else { return }
                        let page = AmityGroupNotificationPreferencePage(channelId: channel.channelId, isSilentByModerator: channel.notificationMode == .silent)
                        let vc = AmitySwiftUIHostingController(rootView: page)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }

                    Spacer().frame(height: 16)

                    Button {
                        activeAlert = .leaveConfirm
                    } label: {
                        Text(AmityLocalizedStringSet.Chat.GroupSetting.leaveButton.localizedString)
                            .applyTextStyle(.custom(16, .semibold, Color(viewConfig.theme.alertColor)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .applyTextStyle(.custom(17, .bold, Color(viewConfig.theme.baseColor)))
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private func settingTile(icon: ImageResource, title: String, trailing: String = "", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(width: 24, height: 24)
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }

                Text(title)
                    .applyTextStyle(.custom(16, .regular, Color(viewConfig.theme.baseColor)))

                Spacer()

                if !trailing.isEmpty {
                    Text(trailing)
                        .applyTextStyle(.custom(14, .regular, Color(viewConfig.theme.baseColorShade1)))
                }

                Image(AmityIcon.Chat.rightArrowIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .frame(width: 16, height: 16)
            }
            .padding(.vertical, 16)
            .background(Color(viewConfig.theme.backgroundColor))
        }
        .buttonStyle(.plain)
    }

    private func notificationModeLabel() -> String {
        guard let ch = viewModel.channel else { return AmityLocalizedStringSet.Chat.GroupSetting.notifModeDefault.localizedString }
        switch ch.notificationMode {
        case .silent:
            return AmityLocalizedStringSet.Chat.GroupSetting.notifModeSilent.localizedString
        case .subscribe:
            return AmityLocalizedStringSet.Chat.GroupSetting.notifModeSubscribe.localizedString
        default:
            return AmityLocalizedStringSet.Chat.GroupSetting.notifModeDefault.localizedString
        }
    }
}
