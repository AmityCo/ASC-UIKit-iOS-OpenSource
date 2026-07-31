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

                    AmityChatMessageComposeBar(viewModel: liveChatViewModel, isGroupChat: true)
                        // Visible during initial load too (Figma 12041:242294); hidden only on error/banned or when muted without permission.
                        .isHidden((messageViewModel.initialQueryState != .success && messageViewModel.initialQueryState != .loading)
                                  || (messageViewModel.muteState != .none && !messageViewModel.hasModeratorPermission))
                }
            }
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            pageViewModel.loadChannelInfo()
        }
        .onChange(of: pageViewModel.displayName) { name in
            liveChatViewModel.channelDisplayName = name
        }
    }

    // MARK: - Group Header

    // Header skeleton stays until BOTH the channel info and the initial messages
    // have loaded. isLoadingHeader alone resolves from local cache almost instantly,
    // so on its own the skeleton would vanish before messages arrive.
    private var isHeaderLoading: Bool {
        pageViewModel.isLoadingHeader || messageViewModel.initialQueryState == .loading
    }

    private var groupHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .frame(width: 24, height: 24)  // Figma 10848:54642: chevron glyph 24pt
                        // Match the direct-chat back button: expand to the 44x44 HIG
                        // minimum tap target while keeping the 24pt glyph at its original
                        // position. Frame grows 10pt per side, so leading -10 keeps the
                        // chevron 16pt from the edge and trailing (12 - 10 = +2) preserves
                        // the original 12pt visual gap to the avatar. contentShape makes
                        // the whole frame tappable, not just the glyph.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, -10)
                .padding(.trailing, 2)

                Button {
                    navigateToSettings()
                } label: {
                    HStack(spacing: 12) {  // 12pt gap avatar → name
                        if isHeaderLoading {
                            // Skeleton avatar while channel info loads (Figma 12041:242294 → circle)
                            Circle()
                                .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                                .frame(width: 40, height: 40)
                                .shimmering()
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(viewConfig.color(.surfaceAvatarProfileDefault)))
                                    .overlay(
                                        Image(AmityIcon.DesignSystem.commentsAltS.imageResource)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(Color(viewConfig.color(.iconAvatarDefault)))
                                    )
                                AsyncImage(placeholderView: { Color.clear }, url: pageViewModel.avatarURL)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

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

                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Trailing overflow meatball: ellipsis-v-r, 24pt glyph in a 32pt box.
                Button {
                    navigateToSettings()
                } label: {
                    Image(AmityIcon.DesignSystem.ellipsisVR.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color(viewConfig.color(.surfaceBannerDefaultGeneral)))

            Rectangle()
                .fill(Color(viewConfig.color(.lineDividerPostDefault)))
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
    @Published var isLoadingHeader: Bool = true

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
            self.isLoadingHeader = false
        }
    }
}
