//
//  AppManager.swift
//  SampleApp
//

import AmitySDK
import AmityUIKit4
import SwiftUI
import UIKit

final class AppManager {

    static let shared = AppManager()
    private init() {}

    private enum UserDefaultsKey {
        static let userId = "userId"
        static let userIds = "userIds"
        static let deviceToken = "deviceToken"
    }

    var isUserRegistered: Bool {
        guard let userId = UserDefaults.standard.value(forKey: UserDefaultsKey.userId) as? String else { return false }
        return !userId.hasPrefix("visitor")
    }

    // MARK: - Setup

    func setupAmityUIKit() {
        let endpointConfig = EndpointManager.shared.currentEndpointConfig
        AmityUIKit4Manager.setup(
            apiKey: endpointConfig.apiKey,
            endpoint: AmityEndpoint(
                httpUrl: endpointConfig.httpEndpoint,
                mqttHost: endpointConfig.mqttEndpoint,
                uploadUrl: endpointConfig.uploadURL
            )
        )

        RemoteConfig.setup(apiKey: endpointConfig.apiKey, httpEndpoint: endpointConfig.httpEndpoint)

        // Apply the Local Custom toggles (theme, excludes, feature flags) by writing a
        // runtime UIKit config to Caches and pointing the framework at it. Falls back to
        // the bundled JSON if the writer fails for any reason.
        if let runtimeURL = LoginConfigJSONWriter.writeRuntimeConfig(from: LoginConfigStore.shared) {
            AmityUIKit4Manager.setConfigFile(runtimeURL.path)
        } else if let filePath = Bundle.main.path(forResource: "AmityUIKitConfig", ofType: "json") {
            AmityUIKit4Manager.setConfigFile(filePath)
        }

        AmityUIKit4Manager.setCustomAssetBundle(bundle: .main)

        AmityUIKit4Manager.behaviour.globalBehavior = CustomV4GlobalBehavior()

        if isUserRegistered, let currentUserId = UserDefaults.standard.value(forKey: UserDefaultsKey.userId) as? String {
            register(withUserId: currentUserId, displayName: nil)
        }
    }

    func applyEnvironment(region: ApiRegion, apiKey: String, uploadURL: String) {
        EndpointManager.shared.setCurrentRegion(region)
        let regionDefault = EndpointManager.defaultConfig(for: region)
        if apiKey == regionDefault.apiKey && uploadURL == regionDefault.uploadURL {
            // User didn't override — clear any prior override and use the region default.
            EndpointManager.shared.clearOverride(for: region)
        } else {
            EndpointManager.shared.applyOverride(region: region, apiKey: apiKey, uploadURL: uploadURL)
        }
        setupAmityUIKit()
    }

    // MARK: - Login

    func register(withUserId userId: String, displayName: String?) {
        refreshUIKitConfigFile()
        AmityUIKit4Manager.registerDevice(
            withUserId: userId,
            displayName: displayName,
            sessionHandler: SampleSessionHandler()
        ) { [weak self] success, error in
            print("[Sample App] register device with userId '\(userId)' \(success ? "successfully" : "failed") \(String(describing: error))")
            if let error = error {
                Toast.showToast(style: .warning, message: "Could not register user: \(error.localizedDescription)")
                return
            }
            self?.registerDevicePushNotification()
            self?.syncNetworkConfigIfEnabled()
        }
        UserDefaults.standard.setValue(userId, forKey: UserDefaultsKey.userId)
        swapWindowRoot(to: .selectModule)
    }

    func registerVisitor(authSignature: String?, authSignatureExpiryAt: Date?) {
        refreshUIKitConfigFile()
        Task { @MainActor in
            do {
                try await AmityUIKit4Manager.registerDeviceAsVisitor(
                    authSignature: authSignature,
                    authSignatureExpiresAt: authSignatureExpiryAt,
                    sessionHandler: SampleSessionHandler()
                )

                let guestUserId = AmityUIKit4Manager.client.currentUserId
                print("UIKit Guest User Id: \(String(describing: guestUserId))")

                UserDefaults.standard.setValue(guestUserId, forKey: UserDefaultsKey.userId)
                self.syncNetworkConfigIfEnabled()
                swapWindowRoot(to: .selectModule)
            } catch {
                Toast.showToast(style: .warning, message: "Could not register user: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Logout

    func unregister() {
        AmityUIKit4Manager.unregisterDevicePushNotification { [weak self] success, error in
            if let error = error {
                Toast.showToast(style: .warning, message: "Unregister failed with error \(error.localizedDescription)")
            }
            AmityUIKit4Manager.unregisterDevice()
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.deviceToken)
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.userId)
            self?.swapWindowRoot(to: .environmentSetup)
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    /// Same path as unregister() today — the iOS SDK does not yet expose secureLogout().
    /// TODO: route to client.secureLogout() once available; this wrapper exists so the call site doesn't change.
    func secureUnregister() {
        unregister()
    }

    /// Re-writes the runtime UIKit config from the latest Local Custom toggles and points
    /// `AmityUIKit4Manager` at the new file. Called before every login attempt so theme,
    /// excludes, and feature flags take effect even when the env hasn't changed (the
    /// "Log in" path, which skips `setupAmityUIKit`).
    private func refreshUIKitConfigFile() {
        guard let runtimeURL = LoginConfigJSONWriter.writeRuntimeConfig(from: LoginConfigStore.shared) else { return }
        AmityUIKit4Manager.setConfigFile(runtimeURL.path)
    }

    /// Fires `AmityUIKit4Manager.syncNetworkConfig()` post-login when the Local Custom
    /// "Sync Network Config" toggle is ON. The remote fetch may override local theme /
    /// excludes / feature_flags — that's the documented behavior of the toggle.
    private func syncNetworkConfigIfEnabled() {
        guard LoginConfigStore.shared.config.syncNetworkConfig else { return }
        Task { @MainActor in
            do {
                try await AmityUIKit4Manager.syncNetworkConfig()
            } catch {
                print("[Sample App] syncNetworkConfig failed: \(error.localizedDescription)")
            }
        }
    }

    func unregisterDevicePushNotification(completion: AmityRequestCompletion?) {
        AmityUIKit4Manager.unregisterDevicePushNotification(completion: completion)
    }

    // MARK: - Routing helpers

    func routeToEnvironmentSetup() {
        swapWindowRoot(to: .environmentSetup)
    }

    func routeToSelectModule() {
        swapWindowRoot(to: .selectModule)
    }

    /// Present the Social module by swapping the window root to a `ModuleNavigationController`
    /// hosting `AmitySocialHomePage`. Uses `AmitySwiftUIHostingController` so the page's
    /// `@EnvironmentObject host: AmitySwiftUIHostWrapper` is injected and `host.controller`
    /// resolves to the hosting controller. `showBackButton: true` renders the framework's own
    /// back button inside the page (the page hides the native nav bar, so a `UIBarButtonItem`
    /// would be invisible). `ModuleNavigationController` intercepts the root-pop that the
    /// back button triggers and routes back to Select Module.
    func openSocialModule() {
        let host = AmitySwiftUIHostingController(rootView: AmitySocialHomePage(showBackButton: true))
        presentModule(host, title: "Social", showCustomBackBarButton: false)
    }

    /// Present the Chat module by swapping the window root to a `ModuleNavigationController`
    /// hosting `AmityChatHomePage`. The page draws its own internal nav bar and hides the
    /// native `UINavigationBar` on appear, so a `UIBarButtonItem` would be invisible and the
    /// page has no built-in back affordance. Wrap it in `HostedChatHomePage` which adds a
    /// thin back chevron strip above the page — tapping routes back to Select Module.
    func openChatModule() {
        let host = AmitySwiftUIHostingController(rootView: HostedChatHomePage())
        presentModule(host, title: "Chat", showCustomBackBarButton: false)
    }

    private func presentModule(_ root: UIViewController, title: String, showCustomBackBarButton: Bool) {
        DispatchQueue.main.async {
            root.title = title
            if showCustomBackBarButton {
                root.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.backward"),
                    primaryAction: UIAction { _ in
                        AppManager.shared.routeToSelectModule()
                    }
                )
            }
            let nav = ModuleNavigationController(rootViewController: root)
            UIApplication.shared.windows.first?.rootViewController = nav
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }

    private func swapWindowRoot(to destination: LoginFlowInitialDestination) {
        DispatchQueue.main.async {
            let root = UIHostingController(rootView: LoginFlowCoordinator(initialDestination: destination))
            UIApplication.shared.windows.first?.rootViewController = root
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }

    // MARK: - Push token

    private func registerDevicePushNotification() {
        guard let deviceToken = UserDefaults.standard.value(forKey: UserDefaultsKey.deviceToken) as? String else { return }
        AmityUIKit4Manager.registerDeviceForPushNotification(deviceToken) { success, error in
            if success {
                Toast.showToast(style: .success, message: "Successfully registered push notification for device \(deviceToken)")
            } else {
                Toast.showToast(style: .warning, message: "Failed to register push notification. Error: \(error?.localizedDescription ?? "")")
            }
        }
    }

    func registerDeviceToken(_ token: Data) {
        AmityUIKit4Manager.unregisterDevicePushNotification()
        let tokenParts: [String] = token.map { data in String(format: "%02.2hhx", data) }
        let tokenString: String = tokenParts.joined()
        UserDefaults.standard.setValue(tokenString, forKey: UserDefaultsKey.deviceToken)
        AmityUIKit4Manager.registerDeviceForPushNotification(tokenString)
    }

    // MARK: - Recent users

    func getUsers() -> [String] {
        UserDefaults.standard.value(forKey: UserDefaultsKey.userIds) as? [String] ?? []
    }

    func updateUsers(withUserIds userIds: [String]) {
        UserDefaults.standard.set(userIds, forKey: UserDefaultsKey.userIds)
    }

    // MARK: - Helpers

    func getDeviceToken() -> String {
        UserDefaults.standard.value(forKey: UserDefaultsKey.deviceToken) as? String ?? ""
    }
}

/// UINavigationController that hosts a single module (Chat / Social). When the user taps the
/// page's built-in back button, the framework calls `popViewController(animated:)` on this
/// controller — but the module is the only thing on the stack, so the default behaviour is a
/// no-op. Override the pop to route back to the Select Module screen instead.
final class ModuleNavigationController: UINavigationController {
    override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count <= 1 {
            AppManager.shared.routeToSelectModule()
            return nil
        }
        return super.popViewController(animated: animated)
    }
}

class CustomV4GlobalBehavior: AmityGlobalBehavior {
    override func handleVisitorUsageLimitSignIn() {
        Toast.showToast(style: .warning, message: "Create an account or sign in to continue.")
        AppManager.shared.unregister()
    }
}

extension DateFormatter {
    static func ascDateFromISO8601String(_ dateString: String?) -> Date? {
        guard let dateInput = dateString else { return nil }
        return ascISO8601FractionalSecondsFormatter.date(from: dateInput) ?? ascISO8601RFC3309Formatter.date(from: dateInput)
    }

    static var ascISO8601FractionalSecondsFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static var ascISO8601RFC3309Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
