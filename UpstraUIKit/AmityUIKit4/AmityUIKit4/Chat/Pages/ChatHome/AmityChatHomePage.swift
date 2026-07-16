//
//  AmityChatHomePage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmityChatHomePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .chatHomePage }

    @StateObject private var viewModel = AmityChatHomeViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showCreateMenu = false
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success
    @State private var showArchiveLimitAlert = false

    private let onBack: (() -> Void)?
    private let backButtonSize: CGFloat = 24

    public init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .socialHomePage)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Navigation bar
            navigationBar

            // MARK: Pill tab row
            if viewModel.visibleTabs.count > 1 {
                pillTabRow
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(viewConfig.theme.backgroundColor))
            }

            // MARK: Channel list
            ZStack {
                ForEach(viewModel.visibleTabs, id: \.self) { tab in
                    tabContent(for: tab)
                        .opacity(viewModel.selectedTab == tab ? 1 : 0)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
        .alert(isPresented: $showArchiveLimitAlert) {
            Alert(
                title: Text(AmityLocalizedStringSet.Chat.Archive.limitTitle.localizedString),
                message: Text(AmityLocalizedStringSet.Chat.Archive.limitMessage.localizedString),
                dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            )
        }
    }

    // MARK: - Navigation bar

    private var navigationBar: some View {
        HStack(spacing: 0) {
            if let onBack {
                Button(action: onBack) {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: backButtonSize, height: backButtonSize)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
            }

            Text(AmityLocalizedStringSet.Chat.Home.title.localizedString)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                .padding(.leading, onBack == nil ? 16 : 8)

            Spacer()

            if !networkMonitor.isConnected {
                HStack(spacing: 4) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                    Text(AmityLocalizedStringSet.Chat.Home.waitingForNetwork.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                }
            }

            Spacer()

            circleIconButton(image: AmityIcon.Chat.searchButtonIcon.imageResource) {
                let nav = AmitySwiftUIHostingNavigationController(rootView: AmitySearchChannelPage())
                nav.isNavigationBarHidden = true
                nav.modalPresentationStyle = .fullScreen
                nav.modalTransitionStyle = .coverVertical
                host.controller?.present(nav, animated: true)
            }

            createChannelButton

            Menu {
                Button {
                    let page = AmityArchivedChatPage()
                    let vc = AmitySwiftUIHostingController(rootView: page)
                    host.controller?.navigationController?.pushViewController(vc, animated: true)
                } label: {
                    Label {
                        Text(AmityLocalizedStringSet.Chat.Home.menuArchived.localizedString)
                    } icon: {
                        Image(AmityIcon.Chat.archivedMenuIcon.imageResource)
                            .renderingMode(.template)
                    }
                }
            } label: {
                Image(AmityIcon.Chat.homeOptionIcon.imageResource)
                    .padding(.trailing, 8)
            }

            Spacer().frame(width: 8)
        }
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Pill tab row

    private var pillTabRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.visibleTabs, id: \.self) { tab in
                pillTabButton(tab)
            }
            Spacer()
        }
    }

    private func pillTabButton(_ tab: ChatHomeTab) -> some View {
        let isSelected = viewModel.selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
            }
        } label: {
            Text(tab.title)
                .applyTextStyle(isSelected
                    ? .bodyBold(.white)
                    : .body(Color(viewConfig.theme.baseColorShade1)))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? Color(viewConfig.theme.highlightColor)
                              : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? Color.clear
                                : Color(viewConfig.theme.baseColorShade4),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab content

    private func tabContent(for tab: ChatHomeTab) -> some View {
        let channels: [AmityChannel] = {
            switch tab {
            case .all:    return viewModel.allChannels
            case .direct: return viewModel.directChannels
            case .group:  return viewModel.groupChannels
            }
        }()

        return AmityChatListComponent(
            channels: channels,
            isLoading: viewModel.isLoading,
            tab: tab,
            theme: viewConfig.theme,
            isPushNotificationEnabled: viewModel.isPushNotificationEnabled,
            onChannelTap: { channel in
                navigate(to: channel)
            },
            onLoadMore: {
                viewModel.loadMoreIfNeeded(for: tab)
            },
            onArchive: { channelId in
                Task {
                    let result = await viewModel.archiveChannel(channelId)
                    switch result {
                    case .success:
                        toastMessage = AmityLocalizedStringSet.Chat.Archive.toastArchived.localizedString
                        toastStyle = .success
                        showToast = true
                    case .limitExceeded:
                        showArchiveLimitAlert = true
                    case .error:
                        toastMessage = AmityLocalizedStringSet.Chat.Archive.toastArchiveError.localizedString
                        toastStyle = .warning
                        showToast = true
                    }
                }
            },
            onCreateChat: {
                if tab == .group {
                    presentCreateGroup()
                } else {
                    presentCreateConversation()
                }
            }
        )
    }

    // MARK: - Navigation

    private func navigate(to channel: AmityChannel) {
        let destination: UIViewController
        switch channel.channelType {
        case .community:
            destination = AmitySwiftUIHostingController(rootView: AmityGroupChatPage(channelId: channel.channelId))
        case .live, .broadcast:
            destination = AmitySwiftUIHostingController(rootView: AmityLiveChatPage(channelId: channel.channelId))
        case .conversation, .standard:
            fallthrough
        @unknown default:
            destination = AmitySwiftUIHostingController(rootView: AmityChatPage(channelId: channel.channelId))
        }
        host.controller?.navigationController?.pushViewController(destination, animated: true)
    }

    // MARK: - Create channel button

    @ViewBuilder
    private var createChannelButton: some View {
        let enabled = AmityUIKitConfigController.shared.enabledChannelTypes()

        if enabled.count > 1 {
            Menu {
                Button(action: presentCreateConversation) {
                    Label {
                        Text(AmityLocalizedStringSet.Chat.Home.menuDirectChat.localizedString)
                    } icon: {
                        Image(AmityIcon.Chat.createButtonIcon.imageResource)
                            .renderingMode(.template)
                    }
                }
                Button(action: presentCreateGroup) {
                    Label {
                        Text(AmityLocalizedStringSet.Chat.Home.menuGroupChat.localizedString)
                    } icon: {
                        Image(AmityIcon.Chat.createGroupIcon.imageResource)
                            .renderingMode(.template)
                    }
                }
            } label: {
                circleIcon(image: AmityIcon.Chat.chatCreationButton.imageResource)
                    .padding(.trailing, 8)
            }
        } else if let only = enabled.first {
            Button {
                switch only {
                case .conversation: presentCreateConversation()
                case .community:    presentCreateGroup()
                }
            } label: {
                circleIcon(image: AmityIcon.Chat.chatCreationButton.imageResource)
                    .padding(.trailing, 8)
            }
            .buttonStyle(.plain)
        }
    }

    private func presentCreateConversation() {
        let page = AmityCreateConversationPage()
        let vc = AmitySwiftUIHostingController(rootView: page)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .coverVertical
        host.controller?.present(vc, animated: true)
    }

    private func presentCreateGroup() {
        let page = AmitySelectGroupMemberPage()
        let hosting: UIViewController = AmitySwiftUIHostingController(rootView: page)
        let nav = UINavigationController(rootViewController: hosting)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .coverVertical
        nav.setNavigationBarHidden(true, animated: false)
        host.controller?.present(nav, animated: true)
    }

    // MARK: - Helpers

    private func circleIconButton(image: ImageResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            circleIcon(image: image)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
    }

    private func circleIcon(image: ImageResource) -> some View {
        ZStack {
            Circle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 32, height: 32)

            Image(image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(Color(viewConfig.theme.baseColor))
        }
    }
}

#if DEBUG
#Preview {
    AmityChatHomePage()
}
#endif
