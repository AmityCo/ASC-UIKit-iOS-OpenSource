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

    var body: some View {
        VStack(spacing: 0) {
            SampleAppBackChevronStrip {
                AppManager.shared.routeToSelectModule()
            }
            AmityChatHomePage()
        }
    }
}
