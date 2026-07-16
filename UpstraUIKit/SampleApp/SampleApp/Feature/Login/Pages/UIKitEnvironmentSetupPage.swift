//
//  UIKitEnvironmentSetupPage.swift
//  SampleApp
//
//  Screen 1 — `{PLATFORM_NAME} UI-Kit` (iOS shows "iOS UI-Kit").
//  Matches `login-ui-kit-design.html` / ImplementationPlan/30-login-ui-kit.md §Screen 1.
//

import SwiftUI

struct UIKitEnvironmentSetupPage: View {

    @EnvironmentObject var store: LoginConfigStore
    @State private var isAdvancedShown = false
    @State private var loginErrorMessage: String?
    @State private var isSubmitting = false
    @State private var recentUsers: [String] = AppManager.shared.getUsers()

    var body: some View {
        ZStack {
            LoginTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        LoginLargeTitle(text: "iOS UI-Kit")

                        LoginSectionHeader(title: "User")
                        userCard

                        if !recentUsers.isEmpty {
                            LoginSectionHeader(title: "Recent Users")
                            recentUsersCard
                        }

                        LoginSectionHeader(title: "Network")
                        networkCard

                        Spacer().frame(height: 16)
                        advancedOptionsCard

                        if let error = loginErrorMessage {
                            Text(error)
                                .font(LoginTheme.rowSubtitleFont)
                                .foregroundColor(LoginTheme.danger)
                                .padding(.horizontal, LoginTheme.cardSidePadding)
                                .padding(.top, 8)
                        }

                        Spacer().frame(height: 12)
                    }
                }

                footer
            }
        }
        .fullScreenCover(isPresented: $isAdvancedShown) {
            AdvancedPage(
                onClose: { isAdvancedShown = false },
                onLoginRequested: {
                    isAdvancedShown = false
                    submit()
                }
            )
            .environmentObject(store)
        }
    }

    // MARK: - USER card

    private var userCard: some View {
        LoginGroupedCard {
            LoginInlineField("User ID") {
                HStack {
                    TextField(LoginConfigModel.platformDefaultUserId, text: $store.config.userId)
                        .font(LoginTheme.fieldValueFont)
                        .foregroundColor(LoginTheme.primaryText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !store.config.userId.isEmpty {
                        clearButton { store.config.userId = "" }
                    }
                }
            }

            LoginRowDivider()

            LoginInlineField("Display Name (Optional)") {
                TextField("Optional — leave blank to omit", text: $store.config.displayName)
                    .font(LoginTheme.fieldValueFont)
                    .foregroundColor(LoginTheme.primaryText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            LoginRowDivider()

            LoginInlineField("User Type") {
                UserTypePicker(selection: $store.config.userType)
            }
        }
    }

    // MARK: - Recent Users card

    private var recentUsersCard: some View {
        LoginGroupedCard {
            ForEach(Array(recentUsers.enumerated()), id: \.element) { index, user in
                if index > 0 { LoginRowDivider() }
                recentUserRow(user)
            }
        }
    }

    private func recentUserRow(_ user: String) -> some View {
        Button {
            store.config.userId = user
        } label: {
            HStack {
                Text(user)
                    .font(LoginTheme.rowTitleFont)
                    .foregroundColor(LoginTheme.primaryText)
                Spacer()
            }
            .padding(.horizontal, LoginTheme.rowHorizontalPadding)
            .padding(.vertical, LoginTheme.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                removeRecentUser(user)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func removeRecentUser(_ user: String) {
        recentUsers.removeAll { $0 == user }
        AppManager.shared.updateUsers(withUserIds: recentUsers)
    }

    // MARK: - NETWORK card

    private var networkCard: some View {
        LoginGroupedCard {
            LoginInlineField("API Region") {
                RegionPicker(selection: $store.config.apiRegion) { newRegion in
                    store.changeRegion(to: newRegion)
                }
            }

            LoginRowDivider()

            LoginInlineField("API Key (linked to region)") {
                MaskedAPIKeyField(text: $store.config.apiKey) {
                    let defaults = EndpointManager.defaultConfig(for: store.config.apiRegion)
                    store.config.apiKey = defaults.apiKey
                }
            }

            LoginRowDivider()

            LoginInlineField("Upload URL (linked to region)") {
                TextField("https://upload.example.amity.co", text: $store.config.uploadURL)
                    .font(LoginTheme.fieldMonoFont)
                    .foregroundColor(LoginTheme.primaryText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
            }
        }
    }

    // MARK: - Advanced options card

    private var advancedOptionsCard: some View {
        LoginGroupedCard {
            Button {
                isAdvancedShown = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(LoginTheme.neutralFill)
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(LoginTheme.primaryText)
                    }
                    .frame(width: 26, height: 26)

                    Text("Advanced options…")
                        .font(LoginTheme.rowTitleFont)
                        .foregroundColor(LoginTheme.primaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LoginTheme.chevronRight)
                }
                .padding(.horizontal, LoginTheme.rowHorizontalPadding)
                .padding(.vertical, LoginTheme.rowVerticalPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            LoginPrimaryButton(
                store.loginButtonLabel + " →",
                isEnabled: isFormValid,
                isLoading: isSubmitting,
                action: submit
            )
            LoginButtonCaption(text: "Becomes “Apply & Log in →” when the environment changes")
            LoginBuildFooter(region: store.config.apiRegion)
        }
        .padding(.horizontal, LoginTheme.cardSidePadding)
        .padding(.top, LoginTheme.footerTopPadding)
        .padding(.bottom, LoginTheme.footerBottomPadding)
        .background(LoginTheme.background)
    }

    // MARK: - Helpers

    private func clearButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LoginTheme.clearButton)
                    .frame(width: 22, height: 22)
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.borderless)
    }

    private var isFormValid: Bool {
        guard !store.config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let upload = store.config.uploadURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return !upload.isEmpty && !upload.contains(" ")
    }

    // MARK: - Submit

    private func submit() {
        loginErrorMessage = nil
        isSubmitting = true
        let label = store.loginButtonLabel

        if label == "Apply & Log in" {
            AppManager.shared.applyEnvironment(
                region: store.config.apiRegion,
                apiKey: store.config.apiKey,
                uploadURL: store.config.uploadURL
            )
            store.markEnvironmentApplied()
        }

        let resolvedId = store.resolvedUserId
        switch store.config.userType {
        case .signedIn:
            AppManager.shared.register(
                withUserId: resolvedId,
                displayName: store.displayNameForLogin
            )
            persistRecentUserIfNew(resolvedId)
        case .visitor:
            AppManager.shared.registerVisitor(authSignature: nil, authSignatureExpiryAt: nil)
        }

        isSubmitting = false
    }

    private func persistRecentUserIfNew(_ userId: String) {
        var list = AppManager.shared.getUsers()
        if !list.contains(userId) {
            list.append(userId)
            AppManager.shared.updateUsers(withUserIds: list)
            recentUsers = list
        }
    }
}
