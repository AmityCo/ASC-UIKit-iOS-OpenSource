//
//  AmityChatListComponent.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Swipe-to-action wrapper

struct ChatListSwipeAction<Content: View>: View {
    let icon: ImageResource
    let label: String
    let theme: AmityThemeColor
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var offset: CGFloat = 0
    
    private let threshold: CGFloat = 100
    private let actionWidth: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 4) {
                Spacer()
                VStack(spacing: 4) {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.white)
                    Text(label)
                        .applyTextStyle(.captionBold(.white))
                }
                .frame(width: actionWidth)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(theme.baseColorShade2))
            
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
    let theme: AmityThemeColor
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
        HStack(spacing: 4) {
            Image(AmityIcon.Chat.muteIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundColor(Color(theme.baseColorShade1))
            Text(AmityLocalizedStringSet.Chat.Home.notificationsDisabled.localizedString)
                .applyTextStyle(.caption(Color(theme.baseColorShade1)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(theme.baseColorShade4))
    }

    // MARK: - Channel list

    private var channelList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(channels, id: \.channelId) { channel in
                    ChatListSwipeAction(
                        icon: AmityIcon.Chat.channelArchiveIcon.imageResource,
                        label: AmityLocalizedStringSet.Chat.Archive.archive.localizedString,
                        theme: theme,
                        action: { onArchive?(channel.channelId) }
                    ) {
                        AmityChatListItemView(channel: channel, theme: theme)
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
        .background(Color(theme.backgroundColor))
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
        .background(Color(theme.backgroundColor))
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(theme.baseColorShade4))
                .frame(width: 48, height: 48)
                .shimmering()

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(theme.baseColorShade4))
                    .frame(width: 140, height: 14)
                    .shimmering()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(theme.baseColorShade4))
                    .frame(width: 200, height: 12)
                    .shimmering()
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(AmityIcon.Chat.emptyStateIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 140)

            Spacer().frame(height: 16)

            Text(AmityLocalizedStringSet.Chat.Home.emptyTitle.localizedString)
                .applyTextStyle(.titleBold(Color(theme.baseColorShade3)))

            Text(AmityLocalizedStringSet.Chat.modalEmptyDescription.localizedString)
                .applyTextStyle(.caption(Color(theme.baseColorShade3)))

            Spacer().frame(height: 16)

            Button {
                onCreateChat?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(AmityTextStyle.custom(14, .bold, .clear).getFont())
                        .foregroundColor(.white)
                    Text(AmityLocalizedStringSet.Chat.Home.createNew.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(theme.primaryColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(theme.backgroundColor))
    }
}
