//
//  AmityEditGroupMemberPermissionsPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Enum

enum GroupMessagingPermission: String, CaseIterable {
    case everyone = "everyone"
    case moderatorsOnly = "moderators_only"

    var displayTitle: String {
        switch self {
        case .everyone: return AmityLocalizedStringSet.Chat.EditGroupMemberPermission.optionEveryoneTitle.localizedString
        case .moderatorsOnly: return AmityLocalizedStringSet.Chat.EditGroupMemberPermission.optionModeratorsTitle.localizedString
        }
    }

    var displayDescription: String {
        switch self {
        case .everyone: return AmityLocalizedStringSet.Chat.EditGroupMemberPermission.optionEveryoneDescription.localizedString
        case .moderatorsOnly: return AmityLocalizedStringSet.Chat.EditGroupMemberPermission.optionModeratorsDescription.localizedString
        }
    }
}

// MARK: - Page

public struct AmityEditGroupMemberPermissionsPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .editGroupMemberPermissionPage }

    private let channelId: String
    @State private var selectedPermission: GroupMessagingPermission
    private let originalPermission: GroupMessagingPermission
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var isSaving = false

    public init(channelId: String, isMuted: Bool) {
        self.channelId = channelId
        let perm: GroupMessagingPermission = isMuted ? .moderatorsOnly : .everyone
        self._selectedPermission = State(initialValue: perm)
        self.originalPermission = perm
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .editGroupMemberPermissionPage))
    }

    private var hasChanged: Bool { selectedPermission != originalPermission }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AmityLocalizedStringSet.Chat.EditGroupMemberPermission.sectionMessaging.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))
                        .padding(.bottom, 8)

                    ForEach(GroupMessagingPermission.allCases, id: \.rawValue) { perm in
                        permissionOption(perm)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.EditGroupMemberPermission.navbarTitle.localizedString)
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

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).scaleEffect(0.8)
                    } else {
                        Text(AmityLocalizedStringSet.Chat.EditGroupMemberPermission.save.localizedString)
                            .applyTextStyle(.body(Color(viewConfig.color(hasChanged
                                             ? .textMainButtonDefaultGhostPrimaryEnabled
                                             : .textMainButtonDefaultGhostPrimaryDisabled))))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!hasChanged || isSaving)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
    }

    private func permissionOption(_ perm: GroupMessagingPermission) -> some View {
        Button { selectedPermission = perm } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(perm.displayTitle)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))
                    Text(perm.displayDescription)
                        .applyTextStyle(.caption(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                AmitySelection(variant: .radio,
                               isSelected: selectedPermission == perm,
                               viewConfig: viewConfig) { _, _ in }
                    .allowsHitTesting(false)
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let channelManager = ChannelManager()
        do {
            switch selectedPermission {
            case .moderatorsOnly:
                try await channelManager.muteChannel(channelId: channelId, mutePeriod: -1)
            case .everyone:
                try await channelManager.unmuteChannel(channelId: channelId)
            }
            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Chat.EditGroupMemberPermission.toastSuccess.localizedString)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                host.controller?.navigationController?.popViewController(animated: true)
            }
        } catch {
            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Chat.EditGroupMemberPermission.toastFailed.localizedString)
        }
    }
}
