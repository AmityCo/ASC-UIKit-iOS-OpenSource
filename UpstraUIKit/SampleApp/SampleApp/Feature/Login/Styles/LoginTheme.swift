//
//  LoginTheme.swift
//  SampleApp
//
//  Shared visual tokens and building blocks for the SampleApp login flow.
//  Matches `login-ui-kit-design.html` (cleverden/front-end-tech-specs/assets/).
//  Pixel-perfect colours, type sizes, and metrics live here so the pages and
//  components stay in sync.
//

import SwiftUI

enum LoginTheme {

    // MARK: - Colours (match CSS variables in login-ui-kit-design.html)

    /// Page background `--page-bg: #F2F2F7`.
    static let background = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    /// Cards `--card: #FFFFFF`.
    static let card = Color.white
    /// Primary ink (`--ink: #1C1C1E`).
    static let primaryText = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    /// Muted text (`--muted: #8E8E93`).
    static let muted = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    /// Field labels (`--label: #6D6D72`).
    static let fieldLabel = Color(red: 109 / 255, green: 109 / 255, blue: 114 / 255)
    /// Row dividers (`--divider: #E5E5EA`).
    static let divider = Color(red: 229 / 255, green: 229 / 255, blue: 234 / 255)
    /// Primary accent (`--accent: #1C1C1E` — same as ink).
    static let primary = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    /// Toggle OFF (`--toggle-off: #E3E3E8`).
    static let toggleOff = Color(red: 227 / 255, green: 227 / 255, blue: 232 / 255)
    /// Clear button background (`--clear: #C7C7CC`).
    static let clearButton = Color(red: 199 / 255, green: 199 / 255, blue: 204 / 255)
    /// Env badge dot / success (`--green: #34C759`).
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    /// Back-link blue (`--link: #2F6FED`).
    static let link = Color(red: 47 / 255, green: 111 / 255, blue: 237 / 255)
    /// Destructive (`--danger: #E5484D`).
    static let danger = Color(red: 229 / 255, green: 72 / 255, blue: 77 / 255)
    /// Chevron-right (#C0C0C6).
    static let chevronRight = Color(red: 192 / 255, green: 192 / 255, blue: 198 / 255)
    /// Light grey used for module icon backgrounds + segment OFF (`#F0F0F3`).
    static let neutralFill = Color(red: 240 / 255, green: 240 / 255, blue: 243 / 255)
    /// Placeholder text (`#B8B8BE`).
    static let placeholder = Color(red: 184 / 255, green: 184 / 255, blue: 190 / 255)
    /// Env badge background (`#E3F6E8`).
    static let envBadgeBackground = Color(red: 227 / 255, green: 246 / 255, blue: 232 / 255)
    /// Env badge text (`#1F7A3D`).
    static let envBadgeText = Color(red: 31 / 255, green: 122 / 255, blue: 61 / 255)
    /// Build footer text (`#AEB4BD`).
    static let buildFooter = Color(red: 174 / 255, green: 180 / 255, blue: 189 / 255)

    // MARK: - Metrics

    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 12
    static let cardSidePadding: CGFloat = 14       // outer margin around cards
    static let groupLabelTopPadding: CGFloat = 14
    static let groupLabelBottomPadding: CGFloat = 7
    static let rowHorizontalPadding: CGFloat = 14
    static let rowVerticalPadding: CGFloat = 11
    static let footerTopPadding: CGFloat = 8
    static let footerBottomPadding: CGFloat = 18
    static let largeTitleSize: CGFloat = 26
    static let dividerInset: CGFloat = 14

    // MARK: - Type

    static let largeTitleFont = Font.system(size: 26, weight: .bold)
    static let navTitleFont = Font.system(size: 16, weight: .semibold)
    static let backLinkFont = Font.system(size: 15, weight: .regular)
    static let groupLabelFont = Font.system(size: 12, weight: .semibold)
    static let fieldLabelFont = Font.system(size: 12, weight: .regular)
    static let fieldValueFont = Font.system(size: 15, weight: .regular)
    static let fieldMonoFont = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let rowTitleFont = Font.system(size: 15, weight: .regular)
    static let rowSubtitleFont = Font.system(size: 11, weight: .regular)
    static let primaryButtonFont = Font.system(size: 15, weight: .bold)
    static let secondaryButtonFont = Font.system(size: 15, weight: .semibold)
    static let buttonCaptionFont = Font.system(size: 11, weight: .regular)
    static let buildFont = Font.system(size: 11, weight: .regular)
    static let segLabelFont = Font.system(size: 12, weight: .regular)
    static let segFont = Font.system(size: 14, weight: .regular)
    static let badgeFont = Font.system(size: 12, weight: .semibold)
    static let moduleTitleFont = Font.system(size: 15, weight: .semibold)
    static let moduleSubtitleFont = Font.system(size: 12, weight: .regular)
    static let greetingFont = Font.system(size: 15, weight: .regular)
    static let greetingBoldFont = Font.system(size: 15, weight: .bold)
}

// MARK: - Section header (uppercase group label above a card)

struct LoginSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(LoginTheme.groupLabelFont)
            .foregroundColor(LoginTheme.fieldLabel)
            .tracking(0.4)
            .padding(.horizontal, 18)
            .padding(.top, LoginTheme.groupLabelTopPadding)
            .padding(.bottom, LoginTheme.groupLabelBottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inline page large title (used inside the scroll area on Screens 1 & 3)

struct LoginLargeTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LoginTheme.largeTitleFont)
            .foregroundColor(LoginTheme.primaryText)
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Small nav row (used on Screen 2)

struct LoginNavRow: View {
    let title: String
    let backAction: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(LoginTheme.navTitleFont)
                .foregroundColor(LoginTheme.primaryText)
            HStack {
                Button(action: backAction) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(LoginTheme.backLinkFont)
                    }
                    .foregroundColor(LoginTheme.link)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

// MARK: - Grouped card (one card per section, multiple rows inside)

struct LoginGroupedCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoginTheme.card)
        .cornerRadius(LoginTheme.cardCornerRadius)
        .padding(.horizontal, LoginTheme.cardSidePadding)
    }
}

// MARK: - Divider between rows inside a grouped card

struct LoginRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(LoginTheme.divider)
            .frame(height: 0.5)
            .padding(.leading, LoginTheme.dividerInset)
    }
}

// MARK: - Inline field row (small label above value)

struct LoginInlineField<Content: View>: View {
    let label: String
    let content: () -> Content

    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(LoginTheme.fieldLabelFont)
                .foregroundColor(LoginTheme.fieldLabel)
            content()
        }
        .padding(.horizontal, LoginTheme.rowHorizontalPadding)
        .padding(.vertical, LoginTheme.rowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Toggle row used inside a grouped card

struct LoginToggleCardRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LoginTheme.rowTitleFont)
                    .foregroundColor(LoginTheme.primaryText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(LoginTheme.rowSubtitleFont)
                        .foregroundColor(LoginTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: LoginTheme.primary))
        }
        .padding(.horizontal, LoginTheme.rowHorizontalPadding)
        .padding(.vertical, LoginTheme.rowVerticalPadding)
    }
}

// MARK: - Tappable row with chevron-right (for navigation rows in a card)

struct LoginChevronRow: View {
    let title: String
    let subtitle: String?
    var leading: AnyView? = nil
    var trailingText: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        leading: AnyView? = nil,
        trailingText: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailingText = trailingText
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let leading = leading {
                    leading
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(LoginTheme.rowTitleFont)
                        .foregroundColor(LoginTheme.primaryText)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(LoginTheme.rowSubtitleFont)
                            .foregroundColor(LoginTheme.muted)
                    }
                }
                Spacer()
                if let trailingText = trailingText {
                    Text(trailingText)
                        .font(LoginTheme.rowSubtitleFont)
                        .foregroundColor(LoginTheme.muted)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LoginTheme.chevronRight)
            }
            .padding(.horizontal, LoginTheme.rowHorizontalPadding)
            .padding(.vertical, LoginTheme.rowVerticalPadding)
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Primary filled button (Log in / Apply & Log in / Secure log out)

struct LoginPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer()
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(title)
                    .font(LoginTheme.primaryButtonFont)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 15)
            .background(isEnabled ? LoginTheme.primary : LoginTheme.primary.opacity(0.5))
            .cornerRadius(LoginTheme.buttonCornerRadius)
        }
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Secondary outlined button (Log out)

struct LoginSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(LoginTheme.secondaryButtonFont)
                    .foregroundColor(LoginTheme.primaryText)
                Spacer()
            }
            .padding(.vertical, 15)
            .background(LoginTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: LoginTheme.buttonCornerRadius)
                    .stroke(LoginTheme.divider, lineWidth: 1)
            )
            .cornerRadius(LoginTheme.buttonCornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small caption under buttons

struct LoginButtonCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LoginTheme.buttonCaptionFont)
            .foregroundColor(LoginTheme.muted)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

// MARK: - Build version footer

struct LoginBuildFooter: View {
    let region: ApiRegion

    var body: some View {
        let info = Bundle.main.infoDictionary
        let short = (info?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info?["CFBundleVersion"] as? String) ?? "?"
        VStack(spacing: 2) {
            Text("Build \(short) (\(build)) · \(region.rawValue)")
                .font(LoginTheme.buildFont)
                .foregroundColor(LoginTheme.buildFooter)
            Text("Build: \(BuildInfo.gitHash)")
                .font(LoginTheme.buildFont)
                .foregroundColor(LoginTheme.buildFooter)
        }
        .padding(.top, 5)
    }
}
