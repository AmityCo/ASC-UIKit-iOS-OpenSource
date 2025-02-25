//
//  NotificationSettingsType.swift
//  AmityUIKit
//
//  Created by Hamlet on 16.03.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import AmitySDK

enum CommunityNotificationEventType: String {
    case postReacted
    case postCreated
    case commentReacted
    case commentCreated
    case commentReplied
    case storyCreated
    case storyReacted
    case storyCommentCreated
    
    init?(eventType: AmityCommunityNotificationEventType) {
        switch eventType {
        case .postCreated: self = .postCreated
        case .postReacted: self = .postReacted
        case .commentReacted: self = .commentReacted
        case .commentReplied: self = .commentReplied
        case .commentCreated: self = .commentCreated
        case .storyCreated: self = .storyCreated
        case .storyReacted: self = .storyReacted
        case .storyCommentCreated: self = .storyCommentCreated
        @unknown default:
            return nil
        }
    }
    
    var eventType: AmityCommunityNotificationEventType {
        switch self {
        case .postCreated: return .postCreated
        case .postReacted: return .postReacted
        case .commentReacted: return .commentReacted
        case .commentReplied: return .commentReplied
        case .commentCreated: return .commentCreated
        case .storyCreated: return .storyCreated
        case .storyReacted: return .storyReacted
        case .storyCommentCreated: return .storyCommentCreated
        }
    }
    
    var title: String {
        switch self {
        case .postCreated: return AmityLocalizedStringSet.CommunityNotificationSettings.titleNewPosts.localizedString
        case .postReacted: return AmityLocalizedStringSet.CommunityNotificationSettings.titleReactsPosts.localizedString
        case .commentReacted: return AmityLocalizedStringSet.CommunityNotificationSettings.titleReactsComments.localizedString
        case .commentReplied: return AmityLocalizedStringSet.CommunityNotificationSettings.titleReplies.localizedString
        case .commentCreated: return AmityLocalizedStringSet.CommunityNotificationSettings.titleNewComments.localizedString
        case .storyCreated: return
            AmityLocalizedStringSet.CommunityNotificationSettings.titleNewStory.localizedString
        case .storyReacted: return
            AmityLocalizedStringSet.CommunityNotificationSettings.titleReactsStory.localizedString
        case .storyCommentCreated: return
            AmityLocalizedStringSet.CommunityNotificationSettings.titleNewStoryComment.localizedString
        }
    }
    
    var description: String {
        switch self {
        case .postCreated: return AmityLocalizedStringSet.CommunityNotificationSettings.descriptionNewPosts.localizedString
        case .postReacted: return AmityLocalizedStringSet.CommunityNotificationSettings.descriptionReactsPosts.localizedString
        case .commentReacted: return AmityLocalizedStringSet.CommunityNotificationSettings.descriptionReactsComments.localizedString
        case .commentReplied: return AmityLocalizedStringSet.CommunityNotificationSettings.descriptionReplies.localizedString
        case .commentCreated: return AmityLocalizedStringSet.CommunityNotificationSettings.descriptionNewComments.localizedString
        case .storyCreated: return
            AmityLocalizedStringSet.CommunityNotificationSettings.descriptionNewStory.localizedString
        case .storyReacted: return
            AmityLocalizedStringSet.CommunityNotificationSettings.descriptionReactsStory.localizedString
        case .storyCommentCreated: return
            AmityLocalizedStringSet.CommunityNotificationSettings.descriptionNewStoryComment.localizedString
        }
    }
    
}
