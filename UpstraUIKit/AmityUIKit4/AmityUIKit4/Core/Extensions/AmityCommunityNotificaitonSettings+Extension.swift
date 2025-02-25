//
//  AmityCommunityNotificaitonSettings+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import Foundation
import AmitySDK

enum CommunityNotificationSettingOption {
    case everyone, onlyModerator, off
}

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
        return isPostNetworkEnabled || isCommentNetworkEnabled || isStoryNetworkEnabled
    }
    
    func mapToSettingOptionMap() -> [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] {
        var settingMap: [AmityCommunityNotificationEventType: CommunityNotificationSettingOption] = [:]
        
        events
            .forEach { event in
                let selectedOption: CommunityNotificationSettingOption
                if event.isEnabled, let filterType = event.roleFilter?.filterType {
                    switch filterType {
                    case .only:
                        selectedOption = .onlyModerator
                    case .all:
                        selectedOption = .everyone
                    default:
                        selectedOption = .everyone
                    }
                } else {
                    selectedOption = .off
                }
                
                if event.isNetworkEnabled {
                    settingMap[event.eventType] = selectedOption
                }
            }
        
        return settingMap
    }
}


extension Dictionary where Key == AmityCommunityNotificationEventType, Value == CommunityNotificationSettingOption {
    func mapToNotificationEvents() -> [AmityCommunityNotificationEvent] {
        var events: [AmityCommunityNotificationEvent] = []
        
        for (eventType, setitngOption) in self {
            var roleFilter: AmityRoleFilter?
            var isEnabled = false
            switch setitngOption {
            case .everyone:
                roleFilter = AmityRoleFilter.allFilter()
                isEnabled = true
            case .onlyModerator:
                roleFilter = AmityRoleFilter.onlyFilter(withRoleIds: [AmityCommunityRole.moderator.rawValue, AmityCommunityRole.communityModerator.rawValue])
                isEnabled = true
            case .off:
                roleFilter = nil
                isEnabled = false
            }
            events.append(AmityCommunityNotificationEvent(eventType: eventType, isEnabled: isEnabled, roleFilter: roleFilter))
        }
        
        return events
    }
}

