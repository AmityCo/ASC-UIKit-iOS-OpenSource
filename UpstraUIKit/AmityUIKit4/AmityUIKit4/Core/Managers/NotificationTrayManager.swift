//
//  NotificationTrayManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/4/25.
//

import AmitySDK

class NotificationTrayManager {
    
    let notificationManager = AmityUIKitManagerInternal.shared.client.notificationTray
    
    func getNotificationTrayItems() -> AmityCollection<AmityNotificationTrayItem> {
        return notificationManager.getNotificationTrayItems()
    }
    
    func getNotificationTraySeenInfo() -> AmityObject<AmityNotificationTraySeen> {
        return notificationManager.getNotificationTraySeen()
    }
    
    @MainActor
    func markTrayAsSeen() async throws {
        try await notificationManager.markSeen()
    }
    
    @MainActor
    func markTrayItemAsSeen(item: AmityNotificationTrayItem) async throws {
        try await item.markSeen()
    }
}
