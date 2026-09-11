//
//  SampleAppBackChevronStrip.swift
//  SampleApp
//
//  A thin back-chevron strip drawn above a framework page. AmityUIKit home pages
//  hide the native `UINavigationBar` on appear and have no built-in back
//  affordance, so the SampleApp supplies its own.
//

import SwiftUI

struct SampleAppBackChevronStrip: View {

    /// Mirrors the device appearance the framework reads
    /// (`UIScreen.main.traitCollection.userInterfaceStyle`) for the "Default"
    /// (system) theme option.
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(baseColor)
                .padding(.all, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)

            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea(edges: .top))
    }

    // MARK: - Theme-matched colours
    //
    // The framework pages paint themselves with the resolved AmityUIKit theme
    // (`Color(viewConfig.theme.backgroundColor)`), but that theme is internal to
    // AmityUIKit4 — the SampleApp can't read it. So mirror it here instead.
    //
    // The palette lives in `AmityUIKitConfig.json` and is fixed: the SampleApp's
    // Local Custom "theme" toggle only flips `preferred_theme`, never the palette
    // (see `LoginConfigJSONWriter`). The framework resolves the active style from
    // `preferred_theme` (`AmityUIKitConfigController.getCurrentThemeStyle`), where
    // `AmityThemeStyle.system` has rawValue "default":
    //   • "dark"    -> dark palette
    //   • "light"   -> light palette
    //   • "default" -> .system -> follows the device appearance
    // The SampleApp's `ThemeOption` maps 1:1 to those raw values, so mirror the
    // same resolution here.
    //
    // If the config palette values change, update these to match.

    private var isDarkTheme: Bool {
        switch LoginConfigStore.shared.config.theme {
        case .dark:    return true
        case .light:   return false
        case .default: return colorScheme == .dark
        }
    }

    /// Matches theme `background_color`: light `#FFFFFF` / dark `#191919`.
    private var backgroundColor: Color {
        isDarkTheme
            ? Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
            : Color.white
    }

    /// Matches theme `base_color` (nav text/icon): light `#292B32` / dark `#EBECEF`.
    private var baseColor: Color {
        isDarkTheme
            ? Color(red: 235 / 255, green: 236 / 255, blue: 239 / 255)
            : Color(red: 41 / 255, green: 43 / 255, blue: 50 / 255)
    }
}
