//
//  AmityGroupNotificationPreferencePage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK

// MARK: - ViewModel

@MainActor
final class AmityGroupNotificationPreferenceViewModel: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var isLoading: Bool = true
    @Published var isSaving: Bool = false

    var hasChanges: Bool { isEnabled != originalEnabled }
    private var originalEnabled: Bool = true

    private let channelId: String
    private let channelManager = ChannelManager()
    private var notificationManager: AmityChannelNotificationsManager?

    init(channelId: String) {
        self.channelId = channelId
    }

    func loadSettings() {
        isLoading = true
        let manager = channelManager.notificationManager(channelId: channelId)
        self.notificationManager = manager
        Task {
            do {
                let settings = try await manager.getSettings()
                self.isEnabled = settings.isEnabled
                self.originalEnabled = self.isEnabled
            } catch {
                self.isEnabled = true
                self.originalEnabled = true
            }
            self.isLoading = false
        }
    }

    func savePreference() async throws {
        isSaving = true
        defer { isSaving = false }
        guard let manager = notificationManager else { return }
        if isEnabled {
            try await manager.enable()
        } else {
            try await manager.disable()
        }
        originalEnabled = isEnabled
    }
}

// MARK: - Page

public struct AmityGroupNotificationPreferencePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .groupNotificationPreferencePage }

    @StateObject private var viewModel: AmityGroupNotificationPreferenceViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    private let isSilentByModerator: Bool

    public init(channelId: String, isSilentByModerator: Bool) {
        self.isSilentByModerator = isSilentByModerator
        self._viewModel = StateObject(wrappedValue: AmityGroupNotificationPreferenceViewModel(channelId: channelId))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .groupNotificationPreferencePage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                content
            }
        }
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
        .navigationBarHidden(true)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
        .onAppear { viewModel.loadSettings() }
    }

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.GroupNotificationPreference.navbarTitle.localizedString)
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

    private var content: some View {
        VStack(spacing: 0) {
            if isSilentByModerator {
                HStack {
                    Text(AmityLocalizedStringSet.Chat.GroupNotificationPreference.moderatorBanner.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.color(.textBannerSubdueSubheadGeneral))))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(16)
                .background(Color(viewConfig.color(.surfaceBannerSubdueGeneral)))
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AmityLocalizedStringSet.Chat.GroupNotificationPreference.toggleTitle.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(isSilentByModerator
                                         ? .textListHeaderDefaultDisabled
                                         : .textListHeaderDefaultDefault))))
                    Text(AmityLocalizedStringSet.Chat.GroupNotificationPreference.toggleDescription.localizedString)
                        .applyTextStyle(.caption(Color(viewConfig.color(isSilentByModerator
                                         ? .textListTextDescriptionDefaultDisabled
                                         : .textListTextDescriptionDefaultDefault))))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                AmityToggle(isOn: viewModel.isEnabled,
                            isDisabled: isSilentByModerator || viewModel.isSaving,
                            viewConfig: viewConfig) { newValue in
                    viewModel.isEnabled = newValue
                    Task {
                        do {
                            try await viewModel.savePreference()
                        } catch {
                            viewModel.isEnabled = !newValue
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(viewConfig.color(.surfaceListDefaultDefault)))

            Spacer()
        }
    }
}
