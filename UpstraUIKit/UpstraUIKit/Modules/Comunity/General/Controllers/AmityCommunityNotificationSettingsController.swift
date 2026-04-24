//
//  AmityCommunityNotificationSettingsController.swift
//  AmityUIKit
//
//  Created by Hamlet on 05.03.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import AmitySDK
import UIKit

protocol AmityUserNotificationSettingsControllerProtocol {
    func retrieveNotificationSettings(completion: ((Result<AmityUserNotificationSettings, Error>) -> Void)?)
    func enableNotificationSettings(modules: [AmityUserNotificationModule]?)
    func disableNotificationSettings()
}

class AmityUserNotificationSettingsController: AmityUserNotificationSettingsControllerProtocol {
    
    private let notificationManager = AmityUIKitManagerInternal.shared.client.notificationManager
    
    func retrieveNotificationSettings(completion: ((Result<AmityUserNotificationSettings, Error>) -> Void)?) {
        Task { @MainActor in
            do {
                let settings = try await notificationManager.getSettings()
                completion?(.success(settings))
            } catch let error {
                completion?(.failure(error))
            }
        }
    }
    
    func enableNotificationSettings(modules: [AmityUserNotificationModule]?) {
        Task { @MainActor in
            do {
                let _ = try await notificationManager.enable(for: modules)
            } catch let error {
                Log.warn("Failed to enable notification settings")
            }
        }
    }
    
    func disableNotificationSettings() {
        Task { @MainActor in
            do {
                try await notificationManager.disableAllNotifications()
            } catch let error {
                Log.warn("Failed to disable notification settings")
            }
        }
    }
    
}

protocol AmityCommunityNotificationSettingsControllerProtocol {
    func retrieveNotificationSettings(completion: ((Result<AmityCommunityNotificationSettings, Error>) -> Void)?)
    func enableNotificationSettings(events: [AmityCommunityNotificationEvent]?, completion: AmityRequestCompletion?)
    func disableNotificationSettings(completion: AmityRequestCompletion?)
}

final class AmityCommunityNotificationSettingsController: AmityCommunityNotificationSettingsControllerProtocol {
    
    private let repository: AmityCommunityRepository
    private let communityId: String
    private let notificationManager: AmityCommunityNotificationsManager
    
    init(withCommunityId _communityId: String) {
        communityId = _communityId
        repository = AmityCommunityRepository()
        notificationManager = repository.notificationManager(forCommunityId: communityId)
    }
    
    func retrieveNotificationSettings(completion: ((Result<AmityCommunityNotificationSettings, Error>) -> Void)?) {
        Task {
            do {
                let settings = try await notificationManager.getSettings()
                completion?(.success(settings))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    func enableNotificationSettings(events: [AmityCommunityNotificationEvent]?, completion: AmityRequestCompletion?) {
        Task {
            do {
                try await notificationManager.enable(events: events ?? [])
                completion?(true, nil)
            } catch {
                completion?(false, error)
            }
        }
    }
    
    func disableNotificationSettings(completion: AmityRequestCompletion?) {
        Task {
            do {
                try await notificationManager.disable()
                completion?(true, nil)
            } catch {
                completion?(false, error)
            }
        }
    }
    
}
