//
//  NotificationManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import Foundation
import AmitySDK

class NotificationManager {
    
    func getUserNotificationSetting() async throws -> AmityUserNotificationSettings {
        let notificationManager = AmityUIKitManagerInternal.shared.client.notificationManager
        return try await notificationManager.getSettings()
    }
    
    func getCommunityNotificationSetting(withId: String) async throws -> AmityCommunityNotificationSettings {
        let notificationManager = AmityCommunityNotificationsManager(communityId: withId)
        return try await notificationManager.getSettings()
    }
    
    func enableNotificationSetting(withId: String, events: [AmityCommunityNotificationEvent]) async throws {
        let notificationManager: AmityCommunityNotificationsManager = AmityCommunityNotificationsManager(communityId: withId)
        try await notificationManager.enable(events: events)
    }
    
    func disableNotificationSetting(withId: String) async throws {
        let notificationManager: AmityCommunityNotificationsManager = AmityCommunityNotificationsManager(communityId: withId)
        try await notificationManager.disable()
    }
}
