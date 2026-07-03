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
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

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
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .padding(.bottom, 8)

                    ForEach(GroupMessagingPermission.allCases, id: \.rawValue) { perm in
                        permissionOption(perm)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
    }

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.EditGroupMemberPermission.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

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

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).scaleEffect(0.8)
                    } else {
                        Text(AmityLocalizedStringSet.Chat.EditGroupMemberPermission.save.localizedString)
                            .applyTextStyle(.body(hasChanged
                                             ? Color(viewConfig.theme.primaryColor)
                                             : Color(viewConfig.theme.primaryColor.blend(.shade2))))
                    }
                }
                .buttonStyle(.plain)
                .disabled(!hasChanged || isSaving)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func permissionOption(_ perm: GroupMessagingPermission) -> some View {
        Button { selectedPermission = perm } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(perm.displayTitle)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    Text(perm.displayDescription)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .opacity(selectedPermission == perm ? 0 : 1)
                    
                    Image(AmityIcon.pollRadioIcon.imageResource)
                        .frame(width: 22, height: 22)
                        .opacity(selectedPermission == perm ? 1 : 0)
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 8)
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
            toastStyle = .success
            toastMessage = AmityLocalizedStringSet.Chat.EditGroupMemberPermission.toastSuccess.localizedString
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                host.controller?.navigationController?.popViewController(animated: true)
            }
        } catch {
            toastStyle = .warning
            toastMessage = AmityLocalizedStringSet.Chat.EditGroupMemberPermission.toastFailed.localizedString
            showToast = true
        }
    }
}
