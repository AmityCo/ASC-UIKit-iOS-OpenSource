//
//  AmityGroupChatPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityGroupChatPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .groupChatPage }

    private let channelId: String
    private let jumpToMessageId: String?

    @StateObject private var pageViewModel: AmityGroupChatPageViewModel
    @StateObject private var liveChatViewModel: AmityChatRoomViewModel
    @StateObject private var messageViewModel: AmityChatMessageListViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var networkMonitor = NetworkMonitor()

    public init(channelId: String, jumpToMessageId: String? = nil) {
        self.channelId = channelId
        self.jumpToMessageId = jumpToMessageId
        let lvm = AmityChatRoomViewModel(channelId: channelId, aroundMessageId: jumpToMessageId)
        self._pageViewModel = StateObject(wrappedValue: AmityGroupChatPageViewModel(channelId: channelId))
        self._liveChatViewModel = StateObject(wrappedValue: lvm)
        self._messageViewModel = StateObject(wrappedValue: lvm.messageList)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .groupChatPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Group header (tappable → settings)
            groupHeader

            ZStack {
                VStack(spacing: 0) {
                    AmityChatMessageListComponent(viewModel: liveChatViewModel, pageId: .groupChatPage)

                    AmityChatMessageComposeBar(viewModel: liveChatViewModel, isGroupChat: true)
                        .isHidden(messageViewModel.initialQueryState != .success
                                  || (messageViewModel.muteState != .none && !messageViewModel.hasModeratorPermission))
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
        .onAppear {
            pageViewModel.loadChannelInfo()
        }
        .onChange(of: pageViewModel.displayName) { name in
            liveChatViewModel.channelDisplayName = name
        }
    }

    // MARK: - Group Header

    private var groupHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
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
                    navigateToSettings()
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                                .overlay(
                                    Image(AmityIcon.Chat.groupAvatarPlaceholderIcon.imageResource)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                )
                            AsyncImage(placeholderView: { Color.clear }, url: pageViewModel.avatarURL)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pageViewModel.displayName)
                                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                                .lineLimit(1)

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
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(viewConfig.theme.backgroundColor))

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
        }
    }

    // MARK: - Navigation

    private func navigateToSettings() {
        guard let channel = pageViewModel.channel else { return }
        let settingsPage = AmityGroupSettingPage(channelId: channelId, isModerator: pageViewModel.isModerator)
        let vc = AmitySwiftUIHostingController(rootView: settingsPage)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - ViewModel

@MainActor
final class AmityGroupChatPageViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var avatarURL: URL?
    @Published var isModerator: Bool = false
    @Published var channel: AmityChannel?

    private let channelId: String
    private let channelManager = ChannelManager()
    private var channelToken: AmityNotificationToken?

    init(channelId: String) {
        self.channelId = channelId
    }

    deinit {
        channelToken?.invalidate()
        channelToken = nil
    }

    func loadChannelInfo() {
        let channelObject = channelManager.getChannel(channelId: channelId)
        channelToken = channelObject.observe { [weak self] obj, _ in
            guard let self, let ch = obj.snapshot else { return }
            self.channel = ch
            self.displayName = ch.displayName ?? ""
            if let urlStr = ch.getAvatarInfo()?.fileURL {
                self.avatarURL = URL(string: urlStr)
            }
            let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            let roles = ch.currentMember?.roles ?? []
            self.isModerator = roles.contains("channel-moderator")
        }
    }
}
