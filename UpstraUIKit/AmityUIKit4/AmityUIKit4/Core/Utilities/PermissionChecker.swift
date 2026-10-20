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

    static func hasPermission(_ permission: AmityPermission, channelId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(permission, forChannel: channelId)
    }
}

class CommentPermissionChecker {

    /// Whether a non-author can delete a comment: community comments need the community's
    /// delete permission, any other target needs the global user feed one.
    static func hasDeleteCommentPermission(communityId: String?) async -> Bool {
        guard let communityId else {
            return await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteUserFeedComment)
        }
        return await CommunityPermissionChecker.hasDeleteCommunityCommentPermission(communityId: communityId)
    }
}

class PostPermissionChecker {

    /// Whether a non-author can delete a post: community posts need the community's
    /// delete permission, any other target needs the global user feed one.
    static func hasDeletePostPermission(communityId: String?) async -> Bool {
        guard let communityId else {
            return await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteUserFeedPost)
        }
        return await CommunityPermissionChecker.hasDeleteCommunityPostPermission(communityId: communityId)
    }
}

class CommunityPermissionChecker {
    
    static func hasDeleteCommunityPostPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunityPost, forCommunity: communityId)
    }
    
    static func hasDeleteCommunityCommentPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunityComment, forCommunity: communityId)
    }
    
    static func hasAddCommunityUserPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.addCommunityUser, forCommunity: communityId)
    }

    static func hasReviewCommunityPostPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.reviewCommunityPost, forCommunity: communityId)
    }

    static func hasEditCommunityUserPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunityUser, forCommunity: communityId)
    }
    
    static func hasRemoveCommunityUserPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.removeCommunityUser, forCommunity: communityId)
    }

    static func hasEditCommunityPermission(communityId: String) async -> Bool {
        await AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: communityId)
    }
}
