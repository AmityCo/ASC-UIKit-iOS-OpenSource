//
//  AmityChatListComponent.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Swipe-to-action wrapper

struct ChatListSwipeAction<Content: View>: View {
    let icon: AmityIcon.DesignSystem
    let label: String
    let viewConfig: AmityViewConfigController
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0

    private let threshold: CGFloat = 100

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Spacer()
                AmityButton(variant: .square,
                            hierarchy: .secondary,
                            label: label,
                            icon: icon,
                            viewConfig: viewConfig,
                            onClick: action)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(viewConfig.color(.surfaceSquareButtonDefaultSecondaryDefault)))

            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if -offset > threshold {
                                action()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                )
        }
        .clipped()
    }
}

struct AmityChatListComponent: View {

    let channels: [AmityChannel]
    let isLoading: Bool
    let tab: ChatHomeTab
    let viewConfig: AmityViewConfigController
    let isPushNotificationEnabled: Bool
    let onChannelTap: (AmityChannel) -> Void
    let onLoadMore: () -> Void
    var onArchive: ((String) -> Void)? = nil
    var onCreateChat: (() -> Void)? = nil

    var body: some View {
        if isLoading {
            skeletonList
        } else if channels.isEmpty {
            VStack(spacing: 0) {
                if !isPushNotificationEnabled {
                    pushNotificationsBanner
                }
                emptyState
            }
        } else {
            VStack(spacing: 0) {
                if !isPushNotificationEnabled {
                    pushNotificationsBanner
                }
                channelList
            }
        }
    }

    // MARK: - Push notifications disabled banner

    private var pushNotificationsBanner: some View {
        HStack(spacing: 2) {
            Image(AmityIcon.DesignSystem.bellSlashR.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(Color(viewConfig.color(.iconBannerSubdueDescriptionGeneral)))
            Text(AmityLocalizedStringSet.Chat.Home.notificationsDisabled.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.color(.textBannerSubdueTextDescriptionGeneral))))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(viewConfig.color(.surfaceBannerSubdueGeneral)))
    }

    // MARK: - Channel list

    private var channelList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(channels, id: \.channelId) { channel in
                    ChatListSwipeAction(
                        icon: .archiveR,
                        label: AmityLocalizedStringSet.Chat.Archive.archive.localizedString,
                        viewConfig: viewConfig,
                        action: { onArchive?(channel.channelId) }
                    ) {
                        AmityChatListItemView(channel: channel, viewConfig: viewConfig)
                            .contentShape(Rectangle())
                            .onTapGesture { onChannelTap(channel) }
                    }

                    if channel.channelId == channels.last?.channelId {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { onLoadMore() }
                    }
                }
            }
            .animation(.default, value: channels.map(\.channelId))
        }
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { _ in
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
                .shimmering()

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 140, height: 10)
                    .shimmering()

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                    .frame(width: 200, height: 10)
                    .shimmering()
            }

            Spacer()
        }
        // 40 pt avatar + 12 pt top/bottom padding = 64 pt row (Figma node 12041:242258).
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack {
            Spacer()

            AmityEmptyState(
                variant: .illustration,
                image: AmityIcon.Chat.emptyStateIcon.imageResource,
                title: AmityLocalizedStringSet.Chat.Home.emptyTitle.localizedString,
                description: AmityLocalizedStringSet.Chat.modalEmptyDescription.localizedString,
                primaryAction: AmityEmptyStateAction(
                    label: AmityLocalizedStringSet.Chat.Home.createNew.localizedString,
                    icon: .plusR
                ) { onCreateChat?() },
                viewConfig: viewConfig
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)))
    }
}
