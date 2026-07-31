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

            // MARK: Content
            if viewModel.isLoading {
                skeletonList
            } else if viewModel.channels.isEmpty {
                emptyState
            } else {
                channelList
            }
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 40)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.Archived.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))

            HStack(spacing: 0) {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
    }

    // MARK: - Channel list

    private var channelList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.channels, id: \.channelId) { channel in
                    ChatListSwipeAction(
                        icon: AmityIcon.DesignSystem.unarchiveR,
                        label: AmityLocalizedStringSet.Chat.Archive.unarchive.localizedString,
                        viewConfig: viewConfig,
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
                        AmityChatListItemView(channel: channel, viewConfig: viewConfig)
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
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
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
        .background(Color(viewConfig.color(.surfaceListSkeletonSkeleton)))
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 140, height: 10)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 200, height: 10)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            AmityEmptyState(
                variant: .icon,
                image: AmityIcon.DesignSystem.inboxL.imageResource,
                title: AmityLocalizedStringSet.Chat.Archived.emptyTitle.localizedString,
                viewConfig: viewConfig
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)))
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
