//
//  HostedChatHomePage.swift
//  SampleApp
//
//  A thin SwiftUI shim around `AmityChatHomePage` that adds a back chevron
//  above the page. `AmityChatHomePage` hides the native `UINavigationBar`
//  on appear and has no built-in back button, so the SampleApp adds its own
//  affordance here. Tapping the chevron routes the window back to the
//  Select Module screen via `AppManager.routeToSelectModule()`.
//

import SwiftUI
import AmityUIKit4

struct HostedChatHomePage: View {

    /// Mirrors the device appearance the framework reads
    /// (`UIScreen.main.traitCollection.userInterfaceStyle`) for the "Default"
    /// (system) theme option.
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            backChevronStrip
            AmityChatHomePage()
        }
    }

    private var backChevronStrip: some View {
        HStack {
            Button {
                AppManager.shared.routeToSelectModule()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(chatBaseColor)
                .padding(.all, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)

            Spacer()
        }
        .background(chatBackgroundColor.ignoresSafeArea(edges: .top))
    }

    // MARK: - Theme-matched colours
    //
    // `AmityChatHomePage` paints itself with the resolved AmityUIKit theme
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
    private var chatBackgroundColor: Color {
        isDarkTheme
            ? Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
            : Color.white
    }

    /// Matches theme `base_color` (nav text/icon): light `#292B32` / dark `#EBECEF`.
    private var chatBaseColor: Color {
        isDarkTheme
            ? Color(red: 235 / 255, green: 236 / 255, blue: 239 / 255)
            : Color(red: 41 / 255, green: 43 / 255, blue: 50 / 255)
    }
}
