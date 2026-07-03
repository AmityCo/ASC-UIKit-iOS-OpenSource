//
//  AmityEditGroupNotificationPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - Notification Mode

enum GroupNotificationMode: String, CaseIterable {
    case defaultMode = "default"
    case silent = "silent"
    case subscribe = "subscribe"

    var displayTitle: String {
        switch self {
        case .defaultMode: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeDefaultTitle.localizedString
        case .silent: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeSilentTitle.localizedString
        case .subscribe: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeSubscribeTitle.localizedString
        }
    }

    var displayDescription: String {
        switch self {
        case .defaultMode: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeDefaultDescription.localizedString
        case .silent: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeSilentDescription.localizedString
        case .subscribe: return AmityLocalizedStringSet.Chat.EditGroupNotification.modeSubscribeDescription.localizedString
        }
    }
}

// MARK: - Page

public struct AmityEditGroupNotificationPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .editGroupNotificationPage }

    private let channelId: String
    @State private var selectedMode: GroupNotificationMode
    private let originalMode: GroupNotificationMode
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var isSaving = false
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    public init(channelId: String, currentMode: String) {
        self.channelId = channelId
        let mode = GroupNotificationMode(rawValue: currentMode) ?? .defaultMode
        self._selectedMode = State(initialValue: mode)
        self.originalMode = mode
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .editGroupNotificationPage))
    }

    private var hasChanged: Bool { selectedMode != originalMode }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(GroupNotificationMode.allCases, id: \.rawValue) { mode in
                        notificationOption(mode)
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
            Text(AmityLocalizedStringSet.Chat.EditGroupNotification.navbarTitle.localizedString)
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
                        Text(AmityLocalizedStringSet.Chat.EditGroupNotification.save.localizedString)
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

    private func notificationOption(_ mode: GroupNotificationMode) -> some View {
        Button { selectedMode = mode } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayTitle)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    Text(mode.displayDescription)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(.gray)
                        .frame(width: 16, height: 16)
                        .opacity(selectedMode == mode ? 0 : 1)
                    
                    Image(AmityIcon.pollRadioIcon.imageResource)
                        .frame(width: 22, height: 22)
                        .opacity(selectedMode == mode ? 1 : 0)
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
            let sdkMode: AmityChannelNotificationMode
            switch selectedMode {
            case .silent: sdkMode = .silent
            case .subscribe: sdkMode = .subscribe
            case .defaultMode: sdkMode = .default
            }
            let options = AmityChannelUpdateOptions(channelId: channelId)
            options.setNotificationMode(sdkMode)
            try await channelManager.editChannel(with: options)

            toastStyle = .success
            toastMessage = AmityLocalizedStringSet.Chat.EditGroupNotification.toastSuccess.localizedString
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                host.controller?.navigationController?.popViewController(animated: true)
            }
        } catch {
            toastStyle = .warning
            toastMessage = AmityLocalizedStringSet.Chat.EditGroupNotification.toastFailed.localizedString
            showToast = true
        }
    }
}
