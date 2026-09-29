//
//  ModuleFlagsPage.swift
//  SampleApp
//
//  Phase 1 modules: the network's entitlements and each module's verdict.
//
//  Read-only. The backend's module settings are the only thing that turns a
//  module on or off, so there is nothing to switch here: to see a module
//  withheld, use a network whose plan withholds it.
//

import SwiftUI
import AmityUIKit4

struct ModuleFlagsPage: View {

    var onClose: () -> Void

    @State private var expanded: Set<String> = []

    private var offCount: Int {
        ModuleFlags.order.filter { !ModuleFlags.isAvailable($0) }.count
    }

    var body: some View {
        ZStack {
            LoginTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                LoginNavRow(title: "Phase 1 Modules", backAction: onClose)

                ScrollView {
                    VStack(spacing: 0) {
                        header

                        LoginGroupedCard {
                            ForEach(Array(ModuleFlags.order.enumerated()), id: \.element) { index, key in
                                ModuleFlagRow(
                                    key: key,
                                    isExpanded: expanded.contains(key),
                                    onExpand: {
                                        if expanded.contains(key) { expanded.remove(key) }
                                        else { expanded.insert(key) }
                                    }
                                )
                                if index != ModuleFlags.order.count - 1 {
                                    LoginRowDivider()
                                }
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The network's plan decides. A module it does not grant is withheld — "
                 + "and a module goes with the ones it is sold with. This screen shows "
                 + "the backend's module settings; nothing here changes them.")
                .font(LoginTheme.rowSubtitleFont)
                .foregroundColor(LoginTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text("NETWORK ENTITLEMENTS")
                    .font(.system(size: 11))
                    .foregroundColor(LoginTheme.fieldLabel)
                Text(ModuleFlags.entitlementSummary.0)
                    .font(.system(size: 13))
                    .foregroundColor(LoginTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let grants = ModuleFlags.entitlementSummary.1 {
                    Text(grants)
                        .font(.system(size: 11))
                        .foregroundColor(LoginTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !ModuleFlags.withheldByNetwork.isEmpty {
                    Text("Withheld: " + ModuleFlags.withheldByNetwork.joined(separator: ", ") + ".")
                        .font(.system(size: 11))
                        .foregroundColor(ModuleFlagsPalette.heldInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)

            Text(offCount == 0
                 ? "All \(ModuleFlags.order.count) available"
                 : "\(offCount) of \(ModuleFlags.order.count) withheld")
                .font(LoginTheme.rowSubtitleFont)
                .foregroundColor(LoginTheme.fieldLabel)
        }
        .padding(.horizontal, LoginTheme.cardSidePadding)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

private struct ModuleFlagRow: View {

    let key: String
    let isExpanded: Bool
    let onExpand: () -> Void

    // The gate's own answer.
    private var available: Bool { ModuleFlags.isAvailable(key) }
    private var reason: String? { ModuleFlags.reason(key) }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(available ? ModuleFlagsPalette.statusOn : ModuleFlagsPalette.statusOff)
                        .frame(width: 8, height: 8)
                    Text(ModuleFlags.label(key))
                        .font(LoginTheme.rowTitleFont)
                        .foregroundColor(available
                                         ? LoginTheme.primaryText
                                         : ModuleFlagsPalette.nameOff)
                    Text(isExpanded ? "▾" : "▸")
                        .font(.system(size: 11))
                        .foregroundColor(LoginTheme.fieldLabel)
                }
                if let reason {
                    subtitle(reason, color: ModuleFlagsPalette.heldInk)
                        .padding(.leading, 16)
                }
                if let requirement = ModuleFlags.requirementText(key) {
                    subtitle(requirement, color: LoginTheme.muted)
                        .padding(.leading, 16)
                }
                if isExpanded {
                    detail
                        .padding(.leading, 16)
                        .padding(.top, 5)
                }
            }
            Spacer()
            // The verdict, where the switch used to be: nothing on this
            // screen can change it.
            Text(available ? "Available" : "Withheld")
                .font(LoginTheme.rowSubtitleFont)
                .foregroundColor(available ? LoginTheme.fieldLabel : ModuleFlagsPalette.heldInk)
        }
        .contentShape(Rectangle())
        .onTapGesture { onExpand() }
        .padding(.horizontal, LoginTheme.rowHorizontalPadding)
        .padding(.vertical, LoginTheme.rowVerticalPadding)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 4) {
            detailRow("Network", ModuleFlags.networkValue(key))
            if let note = ModuleFlags.note(key) {
                detailRow("About", note)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(LoginTheme.fieldLabel)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .foregroundColor(LoginTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func subtitle(_ text: String, color: Color) -> some View {
        Text(text)
            .font(LoginTheme.rowSubtitleFont)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Warning tint for a module a bundle rule holds off. The sample is the host, so
/// literal colours here are the point — a customer app picks its own.
private enum ModuleFlagsPalette {
    static let heldInk = Color(red: 154 / 255, green: 91 / 255, blue: 0 / 255)
    static let statusOn = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let statusOff = Color(red: 199 / 255, green: 199 / 255, blue: 204 / 255)
    static let nameOff = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
}
