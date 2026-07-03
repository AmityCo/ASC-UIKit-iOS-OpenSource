//
//  AppManager.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 21/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import AmitySDK
import AmityUIKit4
import SwiftUI
import UIKit

class AppManager {

    static let shared = AppManager()
    private init() {}

    private enum UserDefaultsKey {
        static let userId = "userId"
        static let userIds = "userIds"
        static let deviceToken = "deviceToken"
    }

    private var isUserRegistered: Bool {
        guard let userId = UserDefaults.standard.value(forKey: UserDefaultsKey.userId) as? String else { return false }
        // Visitors are not auto-restored on relaunch — they must re-enter via the register screen.
        return !userId.hasPrefix("visitor")
    }

    // MARK: - AmityUIKit setup

    func setupAmityUIKit() {
        let endpointConfig = EndpointManager.shared.currentEndpointConfig

        AmityUIKit4Manager.setup(
            apiKey: endpointConfig.apiKey,
            endpoint: AmityEndpoint(httpUrl: endpointConfig.httpEndpoint, mqttHost: endpointConfig.mqttEndpoint, uploadUrl: endpointConfig.uploadURL)
        )

        if let filePath = Bundle.main.path(forResource: "AmityUIKitConfig", ofType: "json") {
            AmityUIKit4Manager.setConfigFile(filePath)
        }

        AmityUIKit4Manager.setCustomAssetBundle(bundle: .main)

        AmityUIKit4Manager.behaviour.globalBehavior = CustomV4GlobalBehavior()

        // If a non-visitor user has logged in previously, register them automatically.
        // Visitors are intentionally NOT auto-restored — they must re-enter via the register screen.
        if isUserRegistered, let currentUserId = UserDefaults.standard.value(forKey: UserDefaultsKey.userId) as? String {
            register(withUserId: currentUserId)
        }
    }

    func register(withUserId userId: String) {
        AmityUIKit4Manager.registerDevice(withUserId: userId, displayName: nil, sessionHandler: SampleSessionHandler()) { [weak self] success, error in
            print("[Sample App] register device with userId '\(userId)' \(success ? "successfully" : "failed") \(String(describing: error))")
            if let error = error {
                Toast.showToast(style: .warning, message: "Could not register user: \(error.localizedDescription)")
                return
            }

            self?.registerDevicePushNotification()
        }
        UserDefaults.standard.setValue(userId, forKey: UserDefaultsKey.userId)

        UIApplication.shared.windows.first?.rootViewController = TabbarViewController()
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    func registerVisitor(authSignature: String?, authSignatureExpiryAt: Date?) {
        Task { @MainActor in
            do {
                try await AmityUIKit4Manager.registerDeviceAsVisitor(authSignature: authSignature, authSignatureExpiresAt: authSignatureExpiryAt, sessionHandler: SampleSessionHandler())

                let guestUserId = AmityUIKit4Manager.client.currentUserId
                print("UIKit Guest User Id: \(String(describing: guestUserId))")

                UserDefaults.standard.setValue(guestUserId, forKey: UserDefaultsKey.userId)
                UIApplication.shared.windows.first?.rootViewController = TabbarViewController()
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            } catch {
                print("Could not register user \(error.localizedDescription)")
                Toast.showToast(style: .warning, message: "Could not register user: \(error.localizedDescription)")
            }
        }
    }

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

    func unregister() {
        AmityUIKit4Manager.unregisterDevicePushNotification { success, error in
            if let error = error {
                Toast.showToast(style: .warning, message: "Unregister failed with error \(error.localizedDescription)")
            }

            AmityUIKit4Manager.unregisterDevice()
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.deviceToken)
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.userId)

            UIApplication.shared.windows.first?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegisterNavigationController")
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func unregisterDevicePushNotification(completion: AmityRequestCompletion?) {
        AmityUIKit4Manager.unregisterDevicePushNotification(completion: completion)
    }

    func registerDeviceToken(_ token: Data) {
        AmityUIKit4Manager.unregisterDevicePushNotification()

        let tokenParts: [String] = token.map { data in String(format: "%02.2hhx", data) }
        let tokenString: String = tokenParts.joined()

        UserDefaults.standard.setValue(tokenString, forKey: UserDefaultsKey.deviceToken)
        AmityUIKit4Manager.registerDeviceForPushNotification(tokenString)
    }

    // MARK: - Login user list

    func getUsers() -> [String] {
        return UserDefaults.standard.value(forKey: UserDefaultsKey.userIds) as? [String] ?? []
    }

    func updateUsers(withUserIds userIds: [String]) {
        UserDefaults.standard.set(userIds, forKey: UserDefaultsKey.userIds)
    }

    // MARK: - Helpers

    func getDeviceToken() -> String {
        return UserDefaults.standard.value(forKey: UserDefaultsKey.deviceToken) as? String ?? ""
    }

    func startingPage() -> UIViewController {
        if isUserRegistered {
            return TabbarViewController()
        } else {
            return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegisterNavigationController")
        }
    }
}


class CustomV4GlobalBehavior: AmityGlobalBehavior {

    override func handleVisitorUsageLimitSignIn() {
        Toast.showToast(style: .info, message: "Create an account or sign in to continue.")
        // Tear down the visitor session and route the user to the starting page
        // (RegisterNavigationController). `AppManager.unregister()` already does
        // logout, clears UserDefaults, and swaps the rootViewController.
        AppManager.shared.unregister()
    }
}

extension DateFormatter {

    // Note:
    // Our backend supports ISO8601 / RFC3309 Format but ios date formatter does not support it out of the box.
    //
    // The `.withFractionalSeconds` format options for `ISO8601DateFormatter` requires the date format to have
    // fractional seconds. This date format cannot be used alone.
    // - If this format option is used alone, then it returns wrong date for any date input 2000-01-01 00:00:00 +0000
    // - If this format option is used with other option, but the input doesn't contain fractional seconds, it will return nil
    // so we use two date formatters to support both usecases.
    static func ascDateFromISO8601String(_ dateString: String?) -> Date? {
        guard let dateInput = dateString else { return nil }

        // Note: Most of the dates in backend contains fractional seconds
        let date = ascISO8601FractionalSecondsFormatter.date(from: dateInput) ?? ascISO8601RFC3309Formatter.date(from: dateInput)
        return date
    }

    /// Supports date with fractional seconds like "2023-02-07T22:06:04.830Z".
    /// For date format like "2024-06-16T20:51:21Z", this will return nil
    static var ascISO8601FractionalSecondsFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }()

    /// Supports date without fractional seconds like "2024-06-16T20:51:21Z"
    /// For date format like "2023-02-07T22:06:04.830Z", this will return nil.
    static var ascISO8601RFC3309Formatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()
}
