//
//  NotificationManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import Foundation
import AmitySDK

class NotificationManager {
    
    func getUserNotificationSetting(completion: @escaping ((AmityUserNotificationSettings?, AmityError?) -> Void)) {
        let notificationManager = AmityUIKitManagerInternal.shared.client.notificationManager
        notificationManager.getSettingsWithCompletion { settings, error in
            if let error {
                completion(nil, AmityError(error: error))
            } else {
                completion(settings, nil)
            }
        }
    }
    
    
    func getCommunityNotificationSetting(withId: String, completion: @escaping ((AmityCommunityNotificationSettings?, AmityError?) -> Void)) {
        let notificationManager: AmityCommunityNotificationsManager = AmityCommunityNotificationsManager(client: AmityUIKitManagerInternal.shared.client, communityId: withId)
        notificationManager.getSettingsWithCompletion { settings, error in
            if let error {
                completion(nil, AmityError(error: error))
            } else {
                completion(settings, nil)
            }
        }
    }
    
    func enableNotificaitonSetting(withId: String, events: [AmityCommunityNotificationEvent]?, completion: @escaping ((Bool, AmityError?) -> Void)) {
        let notificationManager: AmityCommunityNotificationsManager = AmityCommunityNotificationsManager(client: AmityUIKitManagerInternal.shared.client, communityId: withId)
        notificationManager.enable(for: events) { status, error in
            if let error {
                completion(false, AmityError(error: error))
                return
            }
            
            completion(true, nil)
        }
    }
    
    func disableNotificaitonSetting(withId: String, completion: @escaping ((Bool, AmityError?) -> Void)) {
        let notificationManager: AmityCommunityNotificationsManager = AmityCommunityNotificationsManager(client: AmityUIKitManagerInternal.shared.client, communityId: withId)
        notificationManager.disable() { status, error in
            if let error {
                completion(false, AmityError(error: error))
                return
            }
            
            completion(true, nil)
        }
    }
}
