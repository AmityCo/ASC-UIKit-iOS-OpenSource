//
//  AmitySearchChannelPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmitySearchChannelPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .searchChannelPage }

    @StateObject private var viewModel = AmitySearchChannelViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success
    @State private var showArchiveLimitAlert = false

    public init() {
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .searchChannelPage)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(viewConfig.color(.surfacePageBackgroundDefault)))

            tabBar

            Rectangle()
                .fill(Color(viewConfig.color(.lineDividerPostDefault)))
                .frame(height: 1)

            content
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
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

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(AmityIcon.DesignSystem.searchR.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.color(.iconInputTextInputDefault)))
                    .frame(width: 20, height: 20)

                Group {
                    if #available(iOS 15.0, *) {
                        TextField(AmityLocalizedStringSet.Chat.Search.placeholder.localizedString, text: $viewModel.searchKeyword)
                            .applyTextStyle(.body(Color(viewConfig.color(.textInputTextInputPlaceholderEnabledFilled))))
                            .submitLabel(.search)
                    } else {
                        TextField(AmityLocalizedStringSet.Chat.Search.placeholder.localizedString, text: $viewModel.searchKeyword)
                            .applyTextStyle(.body(Color(viewConfig.color(.textInputTextInputPlaceholderEnabledFilled))))
                    }
                }

                if !viewModel.searchKeyword.isEmpty {
                    Button { viewModel.searchKeyword = "" } label: {
                        Image(AmityIcon.DesignSystem.clearR.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.color(.iconInputTextInputDefault)))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(viewConfig.color(.surfaceInputBoxedInputDefault)))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                host.controller?.dismiss(animated: true)
            } label: {
                Text(AmityLocalizedStringSet.General.cancel.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.color(.textMainButtonDefaultGhostPrimaryEnabled))))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 16) {
            ForEach(AmitySearchChannelViewModel.SearchTab.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    private func tabButton(_ tab: AmitySearchChannelViewModel.SearchTab) -> some View {
        let isSelected = viewModel.activeTab == tab
        return Button {
            viewModel.changeTab(tab)
        } label: {
            VStack(spacing: 0) {
                Text(tab.title)
                    .applyTextStyle(.titleBold(isSelected
                        ? Color(viewConfig.color(.textTabUnderlinedActive))
                        : Color(viewConfig.color(.textTabUnderlinedDefault))))
                    .padding(.vertical, 12)

                Rectangle()
                    .fill(isSelected ? Color(viewConfig.color(.lineTabUnderlinedActive)) : Color.clear)
                    .frame(height: 2)
            }
        }
        .fixedSize()
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        let trimmed = viewModel.searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < 3 {
            minimumCharsView
        } else if viewModel.activeTab == .chats && viewModel.isLoading && viewModel.channels.isEmpty {
            skeletonList
        } else if viewModel.activeTab == .messages && (viewModel.isLoading || !viewModel.hasResolvedMessageChannels) {
            skeletonList
        } else if viewModel.activeTab == .chats && viewModel.channels.isEmpty && !viewModel.isLoading {
            noResultsView
        } else if viewModel.activeTab == .messages && viewModel.messages.isEmpty && !viewModel.isLoading {
            noResultsView
        } else if viewModel.activeTab == .chats {
            channelResultsList
        } else {
            messageResultsList
        }
    }

    // MARK: - Channel results

    private var channelResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.channels.indices, id: \.self) { index in
                    let channel = viewModel.channels[index]
                    let isArchived = viewModel.archivedChannelIds.contains(channel.channelId)
                    ChatListSwipeAction(
                        icon: isArchived ? AmityIcon.DesignSystem.unarchiveR : AmityIcon.DesignSystem.archiveR,
                        label: isArchived ? AmityLocalizedStringSet.Chat.Archive.unarchive.localizedString : AmityLocalizedStringSet.Chat.Archive.archive.localizedString,
                        viewConfig: viewConfig,
                        action: { handleArchiveAction(channelId: channel.channelId, isArchived: isArchived) }
                    ) {
                        AmityChatListItemView(
                            channel: channel,
                            searchQuery: viewModel.searchKeyword,
                            isArchived: isArchived,
                            viewConfig: viewConfig
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { navigateToChannel(channel) }
                    }

                    if index == viewModel.channels.count - 1 {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { viewModel.loadMore() }
                    }
                }

                if viewModel.isLoadingMore {
                    searchSkeletonRows
                }
            }
        }
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    // MARK: - Message results

    private var messageResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.messages.indices, id: \.self) { index in
                    let message = viewModel.messages[index]
                    let isArchived = viewModel.archivedChannelIds.contains(message.channelId)

                    ChatListSwipeAction(
                        icon: isArchived ? AmityIcon.DesignSystem.unarchiveR : AmityIcon.DesignSystem.archiveR,
                        label: isArchived ? AmityLocalizedStringSet.Chat.Archive.unarchive.localizedString : AmityLocalizedStringSet.Chat.Archive.archive.localizedString,
                        viewConfig: viewConfig,
                        action: { handleArchiveAction(channelId: message.channelId, isArchived: isArchived) }
                    ) {
                        if let ch = viewModel.messageChannelMap[message.channelId] {
                            AmityChatListItemView(
                                channel: ch,
                                searchQuery: viewModel.searchKeyword,
                                isArchived: isArchived,
                                searchMessage: message,
                                viewConfig: viewConfig
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { navigateToMessage(message) }
                        }
                    }

                    if index == viewModel.messages.count - 1 {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { viewModel.loadMore() }
                    }
                }

                if viewModel.isLoadingMore {
                    searchSkeletonRows
                }
            }
        }
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    // MARK: - Minimum chars view

    private var minimumCharsView: some View {
        VStack {
            Spacer()
            AmityEmptyState(
                variant: .icon,
                image: AmityIcon.DesignSystem.searchL.imageResource,
                title: AmityLocalizedStringSet.Chat.Search.minimumChars.localizedString,
                viewConfig: viewConfig
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No results

    private var noResultsView: some View {
        VStack {
            Spacer().frame(height: 114)
            AmityEmptyState(
                variant: .icon,
                image: AmityIcon.DesignSystem.searchCrossL.imageResource,
                title: AmityLocalizedStringSet.Chat.Search.emptyTitle.localizedString,
                viewConfig: viewConfig
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    searchSkeletonRow
                }
            }
        }
        .background(Color(viewConfig.color(.surfaceListSkeletonSkeleton)))
    }

    private var searchSkeletonRows: some View {
        ForEach(0..<3, id: \.self) { _ in
            searchSkeletonRow
        }
    }

    private var searchSkeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 200, height: 12)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .shimmering()
    }

    // MARK: - Archive action handler

    private func handleArchiveAction(channelId: String, isArchived: Bool) {
        Task {
            if isArchived {
                let success = await viewModel.unarchiveChannel(channelId)
                if success {
                    viewModel.markUnarchived(channelId)
                    toastMessage = AmityLocalizedStringSet.Chat.Archive.toastUnarchived.localizedString
                    toastStyle = .success
                } else {
                    toastMessage = AmityLocalizedStringSet.Chat.Archive.toastUnarchiveError.localizedString
                    toastStyle = .warning
                }
                showToast = true
            } else {
                let result = await viewModel.archiveChannel(channelId)
                switch result {
                case .success:
                    viewModel.markArchived(channelId)
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
        }
    }

    // MARK: - Navigation

    private func navigateToChannel(_ channel: AmityChannel) {
        let destination: UIViewController
        switch channel.channelType {
        case .community:
            destination = AmitySwiftUIHostingController(rootView: AmityGroupChatPage(channelId: channel.channelId))
        case .conversation, .standard:
            fallthrough
        @unknown default:
            destination = AmitySwiftUIHostingController(rootView: AmityChatPage(channelId: channel.channelId))
        }
        host.controller?.navigationController?.pushViewController(destination, animated: true)
    }

    private func navigateToMessage(_ message: AmityMessage) {
        let channel = viewModel.messageChannelMap[message.channelId]
        let channelType = channel?.channelType ?? .conversation
        let destination: UIViewController
        switch channelType {
        case .community:
            destination = AmitySwiftUIHostingController(rootView: AmityGroupChatPage(channelId: message.channelId, jumpToMessageId: message.messageId))
        case .conversation, .standard:
            fallthrough
        @unknown default:
            destination = AmitySwiftUIHostingController(rootView: AmityChatPage(channelId: message.channelId, jumpToMessageId: message.messageId))
        }
        host.controller?.navigationController?.pushViewController(destination, animated: true)
    }
}
