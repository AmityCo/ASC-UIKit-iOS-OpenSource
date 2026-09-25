//
//  AmityGroupMemberActionComponent.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

public struct AmityGroupMemberActionComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController

    public var pageId: PageId?
    public var id: ComponentId {
        return .groupMemberActionComponent
    }

    @Binding private var isPresented: Bool

    private let member: AmityChannelMember
    private let canPromote: Bool
    private let canMute: Bool
    private let canBan: Bool
    private let canRemove: Bool
    private let isFlaggedByMe: Bool
    private let onPromote: (() -> Void)?
    private let onDemote: (() -> Void)?
    private let onMute: (() -> Void)?
    private let onUnmute: (() -> Void)?
    private let onRemove: (() -> Void)?
    private let onBan: (() -> Void)?
    private let onReport: (() -> Void)?

    public init(
        member: AmityChannelMember,
        isPresented: Binding<Bool>,
        canPromote: Bool,
        canMute: Bool,
        canBan: Bool,
        canRemove: Bool,
        isFlaggedByMe: Bool = false,
        pageId: PageId? = nil,
        onPromote: (() -> Void)? = nil,
        onDemote: (() -> Void)? = nil,
        onMute: (() -> Void)? = nil,
        onUnmute: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil,
        onBan: (() -> Void)? = nil,
        onReport: (() -> Void)? = nil
    ) {
        self.member = member
        self._isPresented = isPresented
        self.canPromote = canPromote
        self.canMute = canMute
        self.canBan = canBan
        self.canRemove = canRemove
        self.isFlaggedByMe = isFlaggedByMe
        self.pageId = pageId
        self.onPromote = onPromote
        self.onDemote = onDemote
        self.onMute = onMute
        self.onUnmute = onUnmute
        self.onRemove = onRemove
        self.onBan = onBan
        self.onReport = onReport
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .groupMemberActionComponent))
    }

    // Whether the member holds the `channel-moderator` role specifically — used only to pick the
    // Promote vs Demote label (that button toggles this exact role). NOT an effective-moderator
    // check: a custom-role moderator returns false here yet can still moderate via permissions.
    private var hasChannelModeratorRole: Bool {
        member.roles.contains("channel-moderator")
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if canPromote {
                    if hasChannelModeratorRole {
                        if onDemote != nil {
                            actionRow(
                                id: AccessibilityID.Chat.GroupMemberAction.demote,
                                icon: AmityIcon.DesignSystem.userShieldR.imageResource,
                                label: AmityLocalizedStringSet.Chat.GroupMemberAction.demote.localizedString
                            ) {
                                onDemote?()
                            }
                        }
                    } else {
                        if onPromote != nil {
                            actionRow(
                                id: AccessibilityID.Chat.GroupMemberAction.promote,
                                icon: AmityIcon.DesignSystem.userShieldR.imageResource,
                                label: AmityLocalizedStringSet.Chat.GroupMemberAction.promote.localizedString
                            ) {
                                onPromote?()
                            }
                        }
                    }
                }

                if canMute {
                    if member.isMuted {
                        if onUnmute != nil {
                            actionRow(
                                id: AccessibilityID.Chat.GroupMemberAction.unmute,
                                icon: AmityIcon.DesignSystem.volumeR.imageResource,
                                label: AmityLocalizedStringSet.Chat.GroupMemberAction.unmute.localizedString
                            ) {
                                onUnmute?()
                            }
                        }
                    } else {
                        if onMute != nil {
                            actionRow(
                                id: AccessibilityID.Chat.GroupMemberAction.mute,
                                icon: AmityIcon.DesignSystem.volumeSlashR.imageResource,
                                label: AmityLocalizedStringSet.Chat.GroupMemberAction.mute.localizedString
                            ) {
                                onMute?()
                            }
                        }
                    }
                }

                if onReport != nil {
                    actionRow(
                        id: AccessibilityID.Chat.GroupMemberAction.report,
                        icon: isFlaggedByMe
                            ? AmityIcon.DesignSystem.flagSlashR.imageResource
                            : AmityIcon.DesignSystem.flagR.imageResource,
                        label: isFlaggedByMe
                            ? AmityLocalizedStringSet.Chat.GroupMemberAction.unreport.localizedString
                            : AmityLocalizedStringSet.Chat.GroupMemberAction.report.localizedString
                    ) {
                        onReport?()
                    }
                }

                if canBan, onBan != nil {
                    actionRow(
                        id: AccessibilityID.Chat.GroupMemberAction.ban,
                        icon: AmityIcon.DesignSystem.banR.imageResource,
                        label: AmityLocalizedStringSet.Chat.GroupMemberAction.ban.localizedString
                    ) {
                        onBan?()
                    }
                }

                if canRemove, onRemove != nil {
                    actionRow(
                        id: AccessibilityID.Chat.GroupMemberAction.remove,
                        icon: AmityIcon.DesignSystem.trashR.imageResource,
                        label: AmityLocalizedStringSet.Chat.GroupMemberAction.remove.localizedString,
                        isDestructive: true
                    ) {
                        onRemove?()
                    }
                }
            }
        }
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
        .updateTheme(with: viewConfig)
    }

    private func actionRow(id: String, icon: ImageResource, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.color(isDestructive ? .iconListLeadingDestructiveDefault : .iconListLeadingDefaultDefault)))
                Text(label)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(isDestructive ? .textListHeaderDestructiveDefault : .textListHeaderDefaultDefault))))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
