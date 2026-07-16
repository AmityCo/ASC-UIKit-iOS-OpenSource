//
//  AdvancedPage.swift
//  SampleApp
//
//  Screen 2 — `Advanced`. Matches `login-ui-kit-design.html` /
//  ImplementationPlan/30-login-ui-kit.md §Screen 2.
//

import SwiftUI

struct AdvancedPage: View {

    @EnvironmentObject var store: LoginConfigStore

    var onClose: () -> Void
    var onLoginRequested: () -> Void

    var body: some View {
        ZStack {
            LoginTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                LoginNavRow(title: "Advanced", backAction: onClose)

                ScrollView {
                    VStack(spacing: 0) {
                        LoginSectionHeader(title: "Security")
                        securityCard
                        if !store.config.secureMode {
                            secureModeHint
                        }

                        LoginSectionHeader(title: "Behaviour")
                        behaviourCard

                        LoginSectionHeader(title: "Appearance")
                        appearanceCard

                        Spacer().frame(height: 16)
                    }
                }

                footer
            }
        }
    }

    // MARK: - Security

    private var securityCard: some View {
        LoginGroupedCard {
            LoginToggleCardRow(title: "Secure Mode", isOn: $store.config.secureMode)

            if store.config.secureMode {
                LoginRowDivider()
                LoginInlineField("Auth Signature URL") {
                    TextField("https://my-server/auth-signature", text: $store.config.authSignatureURL)
                        .font(LoginTheme.fieldMonoFont)
                        .foregroundColor(LoginTheme.primaryText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                }

                if store.config.userType == .visitor {
                    LoginRowDivider()
                    LoginInlineField("Auth Signature Expires At") {
                        DatePicker(
                            "",
                            selection: $store.config.authSignatureExpiresAt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .accentColor(LoginTheme.primary)
                    }
                }
            }
        }
    }

    private var secureModeHint: some View {
        Text("Auth Signature URL & Expires-At appear here when Secure Mode is ON")
            .font(LoginTheme.rowSubtitleFont)
            .foregroundColor(LoginTheme.placeholder)
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Behaviour

    private var behaviourCard: some View {
        LoginGroupedCard {
            LoginToggleCardRow(title: "Visitor Can View Clip", isOn: $store.config.visitorCanViewClip)
            LoginRowDivider()
            LoginToggleCardRow(title: "Hide Explore", isOn: $store.config.hideExplore)
            LoginRowDivider()
            LoginToggleCardRow(title: "Social Community Creation Button", isOn: $store.config.socialCommunityCreationButtonVisible)
        }
    }

    // MARK: - Appearance

    private var appearanceCard: some View {
        LoginGroupedCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Theme")
                    .font(LoginTheme.segLabelFont)
                    .foregroundColor(LoginTheme.fieldLabel)
                    .padding(.horizontal, LoginTheme.rowHorizontalPadding)
                    .padding(.top, 11)
                ThemeSegmentedControl(selection: $store.config.theme)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }

            LoginRowDivider()

            LoginToggleCardRow(
                title: "Sync Network Config",
                subtitle: "Applied after login — overrides settings above when ON",
                isOn: $store.config.syncNetworkConfig
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            LoginPrimaryButton(store.loginButtonLabel + " →", action: onLoginRequested)
            LoginButtonCaption(text: "Becomes “Apply & Log in →” when the environment changes")
        }
        .padding(.horizontal, LoginTheme.cardSidePadding)
        .padding(.top, LoginTheme.footerTopPadding)
        .padding(.bottom, LoginTheme.footerBottomPadding)
        .background(LoginTheme.background)
    }
}
