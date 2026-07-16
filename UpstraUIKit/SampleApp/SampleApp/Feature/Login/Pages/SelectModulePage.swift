//
//  SelectModulePage.swift
//  SampleApp
//
//  Screen 3 — `Select Module`. Matches `login-ui-kit-design.html` /
//  ImplementationPlan/30-login-ui-kit.md §Screen 3.
//

import SwiftUI
import AmityUIKit4

struct SelectModulePage: View {

    @EnvironmentObject var store: LoginConfigStore
    @State private var isSyncing = false
    @State private var syncMessage: SyncMessage?

    var body: some View {
        ZStack {
            LoginTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        LoginLargeTitle(text: "Select Module")
                        greetingCard
                            .padding(.horizontal, LoginTheme.cardSidePadding)
                            .padding(.top, 6)

                        LoginSectionHeader(title: "Available Modules")
                        modulesCard

                        LoginSectionHeader(title: "Debug")
                        debugCard

                        Spacer().frame(height: 16)
                        changeUserCard

                        if let message = syncMessage {
                            Text(message.text)
                                .font(LoginTheme.rowSubtitleFont)
                                .foregroundColor(message.isError ? LoginTheme.danger : LoginTheme.muted)
                                .padding(.horizontal, LoginTheme.cardSidePadding)
                                .padding(.top, 8)
                        }

                        Spacer().frame(height: 12)
                    }
                }

                footer
            }
        }
    }

    // MARK: - Greeting (with env badge)

    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            (
                Text("Logged in as ")
                    .font(LoginTheme.greetingFont)
                    .foregroundColor(LoginTheme.primaryText.opacity(0.8))
                + Text(loggedInName)
                    .font(LoginTheme.greetingBoldFont)
                    .foregroundColor(LoginTheme.primaryText)
            )

            Button {
                AppManager.shared.routeToEnvironmentSetup()
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LoginTheme.success)
                        .frame(width: 8, height: 8)
                    Text(store.config.apiRegion.title)
                        .font(LoginTheme.badgeFont)
                        .foregroundColor(LoginTheme.envBadgeText)
                    Text("› edit")
                        .font(LoginTheme.rowSubtitleFont)
                        .foregroundColor(LoginTheme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(LoginTheme.envBadgeBackground)
                .cornerRadius(7)
            }
            .buttonStyle(.borderless)
            .padding(.top, 10)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoginTheme.card)
        .cornerRadius(LoginTheme.cardCornerRadius)
    }

    // MARK: - Modules

    private var modulesCard: some View {
        LoginGroupedCard {
            moduleRow(
                title: "Chat",
                iconSystemName: "bubble.left.and.bubble.right.fill",
                action: { AppManager.shared.openChatModule() }
            )
            LoginRowDivider()
            moduleRow(
                title: "Social",
                iconSystemName: "person.2.fill",
                action: { AppManager.shared.openSocialModule() }
            )
        }
    }

    private func moduleRow(title: String, iconSystemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LoginTheme.neutralFill)
                    Image(systemName: iconSystemName)
                        .font(.system(size: 17))
                        .foregroundColor(LoginTheme.primaryText)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LoginTheme.moduleTitleFont)
                        .foregroundColor(LoginTheme.primaryText)
                    Text("Tap to enter →")
                        .font(LoginTheme.moduleSubtitleFont)
                        .foregroundColor(LoginTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(LoginTheme.chevronRight)
            }
            .padding(.horizontal, LoginTheme.rowHorizontalPadding)
            .padding(.vertical, LoginTheme.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - DEBUG (Re-sync Network Config)

    private var debugCard: some View {
        LoginGroupedCard {
            Button(action: resyncNetworkConfig) {
                HStack {
                    Text("Re-sync Network Config")
                        .font(LoginTheme.rowTitleFont)
                        .foregroundColor(LoginTheme.primaryText)
                    Spacer()
                    if isSyncing {
                        ProgressView()
                    } else {
                        Text(store.config.syncNetworkConfig ? "Tap to fetch" : "Enabled when Sync = ON")
                            .font(LoginTheme.rowSubtitleFont)
                            .foregroundColor(LoginTheme.muted)
                    }
                }
                .padding(.horizontal, LoginTheme.rowHorizontalPadding)
                .padding(.vertical, LoginTheme.rowVerticalPadding)
                .contentShape(Rectangle())
                .opacity(store.config.syncNetworkConfig ? 1.0 : 0.4)
            }
            .buttonStyle(.plain)
            .disabled(!store.config.syncNetworkConfig || isSyncing)
        }
    }

    // MARK: - Change User

    private var changeUserCard: some View {
        LoginGroupedCard {
            LoginChevronRow(title: "Change User") {
                AppManager.shared.routeToEnvironmentSetup()
            }
        }
    }

    // MARK: - Footer (Log out + Secure log out)

    private var footer: some View {
        HStack(spacing: 10) {
            LoginSecondaryButton(title: "Log out") {
                AppManager.shared.unregister()
            }
            // TODO: route to secureLogout() once the iOS SDK exposes it.
            LoginPrimaryButton("Secure log out") {
                AppManager.shared.secureUnregister()
            }
        }
        .padding(.horizontal, LoginTheme.cardSidePadding)
        .padding(.top, LoginTheme.footerTopPadding)
        .padding(.bottom, LoginTheme.footerBottomPadding)
        .background(LoginTheme.background)
    }

    // MARK: - Helpers

    private var loggedInName: String {
        if let name = store.displayNameForLogin {
            return name
        }
        return store.resolvedUserId
    }

    private func resyncNetworkConfig() {
        guard store.config.syncNetworkConfig else { return }
        isSyncing = true
        syncMessage = nil
        Task { @MainActor in
            do {
                try await AmityUIKit4Manager.syncNetworkConfig()
                syncMessage = SyncMessage(text: "Network config synced.", isError: false)
            } catch {
                syncMessage = SyncMessage(text: "Sync failed: \(error.localizedDescription)", isError: true)
            }
            isSyncing = false
        }
    }

    private struct SyncMessage: Equatable {
        let text: String
        let isError: Bool
    }
}
