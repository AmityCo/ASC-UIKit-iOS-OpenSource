//
//  AmityCommunityNotification+Extension.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 25/3/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import AmitySDK

extension AmityCommunityNotificationSettings {
    
    // A flag for checking if post event on community level is enabled
    var isPostNetworkEnabled: Bool {
        let postCreated = events.first(where: { $0.eventType == .postCreated })?.isNetworkEnabled ?? false
        let postReacted = events.first(where: { $0.eventType == .postReacted })?.isNetworkEnabled ?? false
        return postCreated || postReacted
    }
    
    // A flag for checking if comment event on community level is enabled
    var isCommentNetworkEnabled: Bool {
        let commentCreated = events.first(where: { $0.eventType == .commentCreated })?.isNetworkEnabled ?? false
        let commentReacted = events.first(where: { $0.eventType == .commentReacted })?.isNetworkEnabled ?? false
        let commentReplied = events.first(where: { $0.eventType == .commentReplied })?.isNetworkEnabled ?? false
        return commentCreated || commentReacted || commentReplied
    }
    
    // A flag for checking if story event on community level is enabled
    var isStoryNetworkEnabled: Bool {
        let storyCreated = events.first(where: { $0.eventType == .storyCreated })?.isNetworkEnabled ?? false
        let storyReacted = events.first(where: { $0.eventType == .storyReacted })?.isNetworkEnabled ?? false
        let storyCommentCreated = events.first(where: { $0.eventType == .storyCommentCreated })?.isNetworkEnabled ?? false
        return storyCreated || storyReacted || storyCommentCreated
    }
    
    // A flag for checking if social module on community level is enabled
    var isSocialNetworkEnabled: Bool {
        return isPostNetworkEnabled || isCommentNetworkEnabled
    }
    
}
