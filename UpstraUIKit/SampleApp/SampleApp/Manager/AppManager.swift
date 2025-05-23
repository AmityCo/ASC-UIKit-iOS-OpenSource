//
//  AppManager.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 21/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import AmitySDK
import AmityUIKit
#if canImport(AmityUIKit4)
import AmityUIKit4
#endif
import SwiftUI
import UIKit
#if canImport(AmityUIKitLiveStream)
import AmityUIKitLiveStream
#endif

class AppManager {
    
    static let shared = AppManager()
    private init() {}
    
    private enum UserDefaultsKey {
        static let userId = "userId"
        static let userIds = "userIds"
        static let deviceToken = "deviceToken"
    }
    
    private var isUserRegistered: Bool {
        return UserDefaults.standard.value(forKey: UserDefaultsKey.userId) != nil
    }
    
    // MARK: - AmityUIKit setup
    
    func setupAmityUIKit() {
        // setup api key
        let endpointConfig = EndpointManager.shared.currentEndpointConfig
        AmityUIKitManager.setup(apiKey: endpointConfig.apiKey, endpoint: AmityEndpoint(httpUrl: endpointConfig.httpEndpoint, mqttHost: endpointConfig.mqttEndpoint, uploadUrl: endpointConfig.uploadURL))
        
        // setup event handlers and page settings
        AmityUIKitManager.set(eventHandler: CustomEventHandler())
        AmityUIKitManager.set(channelEventHandler: CustomChannelEventHandler())
        AmityUIKitManager.feedUISettings.eventHandler = CustomFeedEventHandler()
        AmityUIKitManager.feedUISettings.setPostSharingSettings(settings: AmityPostSharingSettings())
        
        // setup default theme
        if let preset = Preset(rawValue: UserDefaults.standard.theme ?? 0) {
            AmityUIKitManager.set(theme: preset.theme)
        }
        
        // if user has logged in previosly, register the user automatically.
        if let currentUserId = UserDefaults.standard.value(forKey: UserDefaultsKey.userId) as? String {
            register(withUserId: currentUserId)
        }
        
        // Share client to the new UIKit
        #if canImport(AmityUIKit4)
        RemoteConfig.setup(apiKey: endpointConfig.apiKey, httpEndpoint: endpointConfig.httpEndpoint)
                
        AmityUIKit4Manager.setup(client: AmityUIKitManager.client)
        
        let livestreamBehavior = CustomV4LivestreamBehavior()
        AmityUIKit4Manager.behaviour.livestreamBehavior = livestreamBehavior
        #endif

        // Disable swipe to back gesture behavior
        // AmityUIKit4Manager.behaviour.swipeToBackGestureBehaviour = nil
    }
    
    func register(withUserId userId: String) {
        AmityUIKitManager.registerDevice(withUserId: userId, displayName: nil, sessionHandler: SampleSessionHandler()) { [weak self] success, error in
            print("[Sample App] register device with userId '\(userId)' \(success ? "successfully" : "failed")")
            if let error = error {
                AmityHUD.show(.error(message: "Could not register user: \(error.localizedDescription)"))
                return
            }
            
            self?.registerDevicePushNotification()
        }
        UserDefaults.standard.setValue(userId, forKey: UserDefaultsKey.userId)
        
        UIApplication.shared.windows.first?.rootViewController = TabbarViewController()
        UIApplication.shared.windows.first?.makeKeyAndVisible()
        
    }
    
    private func registerDevicePushNotification() {
        
        guard let deviceToken = UserDefaults.standard.value(forKey: UserDefaultsKey.deviceToken) as? String else { return }
        
        AmityUIKitManager.registerDeviceForPushNotification(deviceToken) { success, error in
            if success {
                AmityHUD.show(.success(message: "Successfully registered push notification for device \(deviceToken)"))
            } else {
                AmityHUD.show(.error(message: "Failed to register push notification. Error: \(error?.localizedDescription ?? "")"))
            }
        }
    }
    
    func unregister() {
        // 1. unregister push notification
        AmityUIKitManager.unregisterDevicePushNotification() { success, error in
            if let error = error {
                AmityHUD.show(.error(message: "Unregister failed with error \(error.localizedDescription)"))
            }
            
            // 2. unregister user
            //    wether it success or failed, we execute unregister to not breaking logout flow.
            AmityUIKitManager.unregisterDevice()
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.deviceToken)
            UserDefaults.standard.setValue(nil, forKey: UserDefaultsKey.userId)
            
            UIApplication.shared.windows.first?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegisterNavigationController")
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            UIApplication.shared.applicationIconBadgeNumber = 0  // reset badge counter
        }
    }
    
    func unregisterDevicePushNotification(completion: AmityRequestCompletion?) {
        AmityUIKitManager.unregisterDevicePushNotification(completion: completion)
    }
    
    func registerDeviceToken(_ token: Data) {
        // Revoke old device token
        AmityUIKitManager.unregisterDevicePushNotification()
        
        // Transform deviceToken into a raw string, before sending to AmitySDK server.
        let tokenParts: [String] = token.map { data in String(format: "%02.2hhx", data) }
        let tokenString: String = tokenParts.joined()
        
        UserDefaults.standard.setValue(tokenString, forKey: UserDefaultsKey.deviceToken)
        AmityUIKitManager.registerDeviceForPushNotification(tokenString)
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


#if canImport(AmityUIKit4)

class CustomV4LivestreamBehavior: AmityLivestreamBehavior {
    
    override func createRecordedPlayer(stream: AmityStream, client: AmityClient) -> any View {
        #if canImport(AmityUIKitLiveStream)
        return AmityUIKit4.RecordedStreamPlayerView(livestream: stream, client: client)
        #else
        print("AmityUIKit4 supports playing recorded stream from the same framework")
        return AmityUIKit4.RecordedStreamPlayerView(livestream: stream, client: client)
        #endif
    }
    
    override func createLivestreamPlayer(stream: AmityStream, client: AmityClient, isPlaying: Bool) -> any View {
        #if canImport(AmityUIKitLiveStream)
        return AmityUIKit4.LivestreamPlayerView(stream: stream, client: client, isPlaying: isPlaying)
        #else
        print("AmityUIKit4 supports watching live stream from the same framework")
        return AmityUIKit4.LivestreamPlayerView(stream: stream, client: client, isPlaying: isPlaying)
        #endif
    }
}
#endif
