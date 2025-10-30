//
//  Notification+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import Foundation

extension Notification.Name {
    static let didPostCreated = Notification.Name("didPostCreated")
    static let didPostDeleted = Notification.Name("didPostDeleted")
    static let didPostLocallyDeleted = Notification.Name("didPostLocallyDeleted")
    static let didPostImageUpdated = Notification.Name("didPostImageUpdated")
    static let didPostReacted = Notification.Name("didPostReacted")
    static let didVotePoll = Notification.Name("didVotePoll")
    static let didLivestreamStatusUpdated = Notification.Name("didLivestreamStatusUpdated")
    static let configDidUpdate = Notification.Name("amityConfigDidUpdate")
}
