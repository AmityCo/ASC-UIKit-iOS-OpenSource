//
//  LoginConfigStore.swift
//  SampleApp
//

import Foundation
import Combine

final class LoginConfigStore: ObservableObject {

    enum DefaultsKey {
        static let config = "asc_sample_login_config"
        static let lastAppliedEnv = "asc_sample_last_applied_env"
        static let inAppPipTesting = "asc_sample_in_app_pip_testing"
        static let networkLogButtonVisible = "asc_sample_network_log_button_visible"
    }

    @Published var config: LoginConfigModel {
        didSet { persistConfig() }
    }

    @Published private(set) var lastAppliedEnv: AppliedEnvSnapshot? {
        didSet { persistLastAppliedEnv() }
    }

    /// QA-only switch. Deliberately kept out of `LoginConfigModel`: that model is decoded
    /// all-or-nothing, so a new key would make every config persisted by an older build
    /// fail to decode and silently reset the tester's saved environment.
    @Published var inAppPipTesting: Bool {
        didSet { defaults.set(inAppPipTesting, forKey: DefaultsKey.inAppPipTesting) }
    }

    /// QA-only switch for the network log beacon, kept out of `LoginConfigModel` for the same
    /// reason as `inAppPipTesting`.
    ///
    /// The setting persists on toggle rather than on login: a tester who flips it and backs
    /// out without logging in must not lose it, and the live overlay must never disagree with
    /// what is stored.
    @Published var networkLogButtonVisible: Bool {
        didSet { AmityNetworkLogOverlayController.shared.isButtonVisible = networkLogButtonVisible }
    }

    private let defaults: UserDefaults

    static let shared = LoginConfigStore()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let stagingDefault = EndpointManager.defaultConfig(for: .staging)
        var loaded = LoginConfigStore.loadConfig(from: defaults)
            ?? LoginConfigModel.makeDefault(
                stagingApiKey: stagingDefault.apiKey,
                stagingUploadURL: stagingDefault.uploadURL
            )
        if loaded.authSignatureExpiresAt <= Date() {
            loaded.authSignatureExpiresAt = Date().addingTimeInterval(3600)
        }
        self.config = loaded
        self.lastAppliedEnv = LoginConfigStore.loadAppliedEnv(from: defaults)
        self.inAppPipTesting = defaults.bool(forKey: DefaultsKey.inAppPipTesting)
        // Defaults to on, so bool(forKey:) returning false for a missing key is not usable.
        self.networkLogButtonVisible = defaults.object(forKey: DefaultsKey.networkLogButtonVisible) == nil
            ? true
            : defaults.bool(forKey: DefaultsKey.networkLogButtonVisible)
    }

    // MARK: - Derived

    var currentEnv: AppliedEnvSnapshot {
        AppliedEnvSnapshot(region: config.apiRegion, apiKey: config.apiKey, uploadURL: config.uploadURL)
    }

    var loginButtonLabel: String {
        guard let applied = lastAppliedEnv else { return "Apply & Log in" }
        return currentEnv == applied ? "Log in" : "Apply & Log in"
    }

    var resolvedUserId: String {
        let trimmed = config.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? LoginConfigModel.platformDefaultUserId : trimmed
    }

    var displayNameForLogin: String? {
        let trimmed = config.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Mutations

    func changeRegion(to region: ApiRegion) {
        let defaults = EndpointManager.defaultConfig(for: region)
        config.apiRegion = region
        config.apiKey = defaults.apiKey
        config.uploadURL = defaults.uploadURL
    }

    func markEnvironmentApplied() {
        lastAppliedEnv = currentEnv
    }

    // MARK: - Persistence

    private func persistConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: DefaultsKey.config)
    }

    private func persistLastAppliedEnv() {
        guard let env = lastAppliedEnv else {
            defaults.removeObject(forKey: DefaultsKey.lastAppliedEnv)
            return
        }
        if let data = try? JSONEncoder().encode(env) {
            defaults.set(data, forKey: DefaultsKey.lastAppliedEnv)
        }
    }

    private static func loadConfig(from defaults: UserDefaults) -> LoginConfigModel? {
        guard let data = defaults.data(forKey: DefaultsKey.config) else { return nil }
        return try? JSONDecoder().decode(LoginConfigModel.self, from: data)
    }

    private static func loadAppliedEnv(from defaults: UserDefaults) -> AppliedEnvSnapshot? {
        guard let data = defaults.data(forKey: DefaultsKey.lastAppliedEnv) else { return nil }
        return try? JSONDecoder().decode(AppliedEnvSnapshot.self, from: data)
    }
}
