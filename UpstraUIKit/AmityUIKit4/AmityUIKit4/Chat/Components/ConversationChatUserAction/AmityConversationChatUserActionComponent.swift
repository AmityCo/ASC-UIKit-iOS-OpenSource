//
//  AmityConversationChatUserActionComponent.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmityConversationChatUserActionComponent: AmityComponentView {

    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController

    public var pageId: PageId?
    public var id: ComponentId { .conversationChatUserActionComponent }

    private let isMuted: Bool
    private let isReportedByMe: Bool
    private let isBlocked: Bool
    private let onMuteUnmute: () -> Void
    private let onReportUnreport: () -> Void
    private let onBlockUnblock: () -> Void

    public init(
        isMuted: Bool,
        isReportedByMe: Bool,
        isBlocked: Bool,
        pageId: PageId? = nil,
        onMuteUnmute: @escaping () -> Void,
        onReportUnreport: @escaping () -> Void,
        onBlockUnblock: @escaping () -> Void
    ) {
        self.isMuted = isMuted
        self.isReportedByMe = isReportedByMe
        self.isBlocked = isBlocked
        self.pageId = pageId
        self.onMuteUnmute = onMuteUnmute
        self.onReportUnreport = onReportUnreport
        self.onBlockUnblock = onBlockUnblock
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(
                pageId: pageId,
                componentId: .conversationChatUserActionComponent
            )
        )
    }

    public var body: some View {
        let config = AmityUIKitConfigController.shared

        return VStack(spacing: 0) {
            if config.isChatUserActionEnabled("mute") {
                actionRow(
                    iconResource: isMuted
                        ? AmityIcon.Chat.unmuteIcon.imageResource
                        : AmityIcon.Chat.muteIcon.imageResource,
                    title: isMuted
                        ? AmityLocalizedStringSet.Chat.DMAction.turnOnNotifications.localizedString
                        : AmityLocalizedStringSet.Chat.DMAction.turnOffNotifications.localizedString,
                    action: onMuteUnmute
                )
            }

            if config.isChatUserActionEnabled("report") {
                actionRow(
                    iconResource: isReportedByMe
                        ? AmityIcon.Chat.unreportUserButtonIcon.imageResource
                        : AmityIcon.Chat.reportUserButtonIcon.imageResource,
                    title: isReportedByMe
                        ? AmityLocalizedStringSet.Chat.DMAction.unreportUser.localizedString
                        : AmityLocalizedStringSet.Chat.DMAction.reportUser.localizedString,
                    action: onReportUnreport
                )
            }

            if config.isChatUserActionEnabled("block") {
                actionRow(
                    iconResource: AmityIcon.Chat.blockUserIcon.imageResource,
                    title: isBlocked
                        ? AmityLocalizedStringSet.Chat.DMAction.unblockUser.localizedString
                        : AmityLocalizedStringSet.Chat.DMAction.blockUser.localizedString,
                    action: onBlockUnblock
                )
            }

            Color.clear.frame(height: 16)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }

    // MARK: - Row builder

    private func actionRow(iconResource: ImageResource,
                           title: String,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(iconResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                Text(title)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}
