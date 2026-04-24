//
//  StoryPermissionManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/20/23.
//

import Foundation
import AmitySDK

public class StoryPermissionChecker {
    
    public static func checkUserHasManagePermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.manageStoryCommunity, forCommunity: communityId)
    }
}

class ChatPermissionChecker {
    
    static func hasModeratorPermission(for channel: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.muteChannel, forChannel: channel)
    }
}

class CommunityPermissionChecker {
    static func hasDeleteCommunityPostPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunityPost, forCommunity: communityId)
    }
    
    static func hasDeleteCommunityCommentPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunityComment, forCommunity: communityId)
    }
}
