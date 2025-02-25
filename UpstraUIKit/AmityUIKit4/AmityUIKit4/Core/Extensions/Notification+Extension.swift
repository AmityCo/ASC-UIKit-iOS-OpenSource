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
    public static let didPostReacted = Notification.Name("didPostReacted")
    public static let didVotePoll = Notification.Name("didVotePoll")
    public static let didLivestreamStatusUpdated = Notification.Name("didLivestreamStatusUpdated")
}
