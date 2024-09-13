//
//  AmityCommunityModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/6/24.
//

import UIKit
import AmitySDK

public struct AmityCommunityModel {
    let communityId: String
    let description: String
    let displayName: String
    let isPublic: Bool
    let isOfficial: Bool
    var isJoined: Bool = false
    let channelId: String
    let postsCount: Int
    var membersCount: Int
    let createdAt: Date
    let metadata: [String: Any]?
    let userId: String
    let tags: [String]
    let category: String
    let categories: [String]
    var categoryId: String?
    let avatarURL: String
    let largeAvatarURL: String
    let isPostReviewEnabled: Bool
    let isStoryCommentsAllowed: Bool
    let participation: AmityCommunityMembership
    let isBrand: Bool
    
    public var object: AmityCommunity
    
    init(object: AmityCommunity) {
        self.object = object
        self.communityId = object.communityId
        self.description = object.communityDescription
        self.displayName = object.displayName
        self.isPublic = object.isPublic
        self.isOfficial = object.isOfficial
        self.isJoined = object.isJoined
        self.channelId = object.channelId
        self.postsCount = Int(object.postsCount)
        self.membersCount = Int(object.membersCount)
        self.createdAt = object.createdAt
        self.metadata = object.metadata as? [String : String]
        self.userId = object.userId
        self.tags = object.tags ?? []
        self.category = object.categories.first?.name ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.categories = object.categories.map { $0.name }
        self.categoryId = object.categoryIds.first
        self.avatarURL = object.avatar?.fileURL ?? ""
        self.largeAvatarURL = object.avatar?.largeFileURL ?? ""
        self.participation = object.membership
        self.isPostReviewEnabled = object.isPostReviewEnabled
        self.isStoryCommentsAllowed = object.storySettings.allowComment
        self.isBrand = object.user?.isBrand ?? false
    }
    
    /// Returns pending post count.
    var pendingPostCount: Int {
        return object.getPostCount(feedType: .reviewing)
    }
    
    /// Returns published post count
    var publishedPostCount: Int {
        return object.getPostCount(feedType: .published)
    }
    
    /// Returns declined post count.
    var declinedPostCount: Int {
        return object.getPostCount(feedType: .declined)
    }
    
    var hasModeratorRole: Bool {
        if let communityMember = object.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId) {
            return communityMember.hasModeratorRole
        }
        return false
    }
}
