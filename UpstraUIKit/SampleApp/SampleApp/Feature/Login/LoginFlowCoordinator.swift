//
//  LoginFlowCoordinator.swift
//  SampleApp
//

import SwiftUI

enum LoginFlowInitialDestination {
    case environmentSetup
    case selectModule
}

struct LoginFlowCoordinator: View {

    @StateObject private var store = LoginConfigStore.shared
    let initialDestination: LoginFlowInitialDestination

    init(initialDestination: LoginFlowInitialDestination = .environmentSetup) {
        self.initialDestination = initialDestination
    }

    var body: some View {
        Group {
            switch initialDestination {
            case .environmentSetup:
                UIKitEnvironmentSetupPage()
            case .selectModule:
                SelectModulePage()
            }
        }
        .environmentObject(store)
    }
}
