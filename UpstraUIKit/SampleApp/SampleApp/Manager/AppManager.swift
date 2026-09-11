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
        
        registerPushNotification()
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

    // MARK: - in-app PiP testing

    /// Forces an in-app navigation to the Social home page on top of whatever is on
    /// screen. This is the action behind the "In-app PiP Testing" QA switch, which makes
    /// a product-tag tap inside the livestream player open the home screen instead of the
    /// product URL, so a tester can check the livestream hands off to the in-app PiP
    /// window without leaving the app.
    ///
    /// The framework starts in-app PiP from its own navigation hooks —
    /// `AmitySwiftUIHostingNavigationController.pushViewController`, and
    /// `AmitySwiftUIHostingController.present` for full-screen presentations. (`PiPState`
    /// is internal to AmityUIKit4, so the SampleApp cannot ask for PiP directly.) So push
    /// onto the livestream's own navigation controller when there is one, and fall back to
    /// a full-screen present otherwise: the livestream player is presented both ways
    /// depending on where it was opened from. The player's own hosting controller is the
    /// topmost controller while the stream is on screen, so it is the presenter — the
    /// behaviour `Context` cannot supply it (its `host` is internal to AmityUIKit4).
    func openHomeForInAppPiPTest() {
        DispatchQueue.main.async {
            guard let presenter = AppManager.topmostViewController() else { return }

            // Pushed: the framework's own back button pops back to the livestream.
            // Presented: it would call `popViewController` on a controller that has no
            // navigation stack, so it is left off rather than shown dead — the tester
            // returns by expanding the PiP window, which is the thing being tested.
            let nav = presenter.navigationController
            let host = AmitySwiftUIHostingController(
                rootView: AmitySocialHomePage(showBackButton: nav != nil)
            )

            if let nav {
                nav.pushViewController(host, animated: true)
            } else {
                // `.fullScreen` matters: the framework only starts PiP for a full-screen
                // or over-full-screen presentation.
                host.modalPresentationStyle = .fullScreen
                presenter.present(host, animated: true)
            }
        }
    }

    /// AmityUIKit4 has its own `UIApplication.topViewController()` but it is internal to
    /// the framework, so the SampleApp resolves the topmost controller itself.
    private static func topmostViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?
            .rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topmostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topmostViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topmostViewController(base: presented)
        }
        return base
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
    
    
    // MARK: - Register Push Notification
    func registerPushNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
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
