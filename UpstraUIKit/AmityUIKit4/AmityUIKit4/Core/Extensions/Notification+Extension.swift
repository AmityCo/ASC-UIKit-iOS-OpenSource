//
//  Notification+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import Foundation

extension Notification.Name {
    public static let didPostCreated = Notification.Name("didPostCreated")
    public static let didPostDeleted = Notification.Name("didPostDeleted")
    public static let didPostLocallyDeleted = Notification.Name("didPostLocallyDeleted")
    public static let didPostImageUpdated = Notification.Name("didPostImageUpdated")
    public static let didPostReacted = Notification.Name("didPostReacted")
    public static let didLivestreamStatusUpdated = Notification.Name("didLivestreamStatusUpdated")
    public static let didPollUpdated = Notification.Name("didPollUpdated")
    static let configDidUpdate = Notification.Name("amityConfigDidUpdate")
}
