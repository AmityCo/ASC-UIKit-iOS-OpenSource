//
//  AmityArchivedChatPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmityArchivedChatPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .archivedChatPage }

    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = AmityArchivedChatViewModel()
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    public init() {
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .archivedChatPage)
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Nav bar
            navBar

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)

            // MARK: Content
            if viewModel.isLoading {
                skeletonList
            } else if viewModel.channels.isEmpty {
                emptyState
            } else {
                channelList
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.Archived.navbarTitle.localizedString)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))

            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.Chat.backButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Channel list

    private var channelList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.channels, id: \.channelId) { channel in
                    ChatListSwipeAction(
                        icon: AmityIcon.Chat.channelUnarchiveIcon.imageResource,
                        label: AmityLocalizedStringSet.Chat.Archive.unarchive.localizedString,
                        theme: viewConfig.theme,
                        action: {
                            Task {
                                let success = await viewModel.unarchiveChannel(channel.channelId)
                                if success {
                                    toastMessage = AmityLocalizedStringSet.Chat.Archive.toastUnarchived.localizedString
                                    toastStyle = .success
                                } else {
                                    toastMessage = AmityLocalizedStringSet.Chat.Archive.toastUnarchiveError.localizedString
                                    toastStyle = .warning
                                }
                                showToast = true
                            }
                        }
                    ) {
                        AmityChatListItemView(channel: channel, theme: viewConfig.theme)
                            .contentShape(Rectangle())
                            .onTapGesture { navigate(to: channel) }
                    }

                    if channel.channelId == viewModel.channels.last?.channelId {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { viewModel.loadMore() }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    skeletonRow
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(width: 200, height: 12)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(AmityIcon.Chat.archivedEmptyIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                .frame(width: 48, height: 48)

            Text(AmityLocalizedStringSet.Chat.Archived.emptyTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Navigation

    private func navigate(to channel: AmityChannel) {
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
}
