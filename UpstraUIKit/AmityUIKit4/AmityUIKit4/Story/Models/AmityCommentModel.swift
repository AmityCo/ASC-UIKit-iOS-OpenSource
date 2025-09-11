//
//  AmityCommentModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import Foundation
import AmitySDK

public struct AmityCommentModel: Identifiable, Equatable  {
    
    public static func == (lhs: AmityCommentModel, rhs: AmityCommentModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var id: String {
        return commentId
    }
    
    let commentId: String
    let displayName: String
    let avatarURL: String
    var text: String
    let isDeleted: Bool
    let isEdited: Bool
    var createdAt: Date
    var updatedAt: Date
    let childrenNumber: Int
    let childrenComment: [AmityCommentModel]
    let parentId: String?
    let userId: String
    let isAuthorGlobalBanned: Bool
    let isAuthorBrand: Bool
    var metadata: [String: Any]?
    var mentioneeBuilder: AmityMentioneesBuilder?
    let mentionees: [AmityMentionees]?
    let reactions: [String: Int]
    var isModerator: Bool = false
    let syncState: AmitySyncState
    var communityId: String?
    let flagCount: Int
    
    // Due to AmityChat 4.0.0 requires comment object for editing and deleting
    // So, this is a workaroud for passing the original object.
    let comment: AmityComment
    
    /// Reaction data of the comment
    
    /// All reactions of the post includes multiple types
    /// e.g. ["like", "love", "haha"]
    public let allReactions: [String]
    
    /// Current user's reaction to the comment
    var myReaction: AmityReactionType? {
        guard let reaction = comment.myReactions.last else { return nil }
        return SocialReactionConfiguration.shared.getReaction(withName: reaction)
    }
    
    /// All reaction count of the comment
    var reactionsCount: Int

    init(comment: AmityComment) {
        commentId = comment.commentId
        displayName = comment.user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        isAuthorBrand = comment.user?.isBrand ?? false
        avatarURL = comment.user?.getAvatarInfo()?.fileURL ?? ""
        text = comment.data?["text"] as? String ?? ""
        isDeleted = comment.isDeleted
        isEdited = comment.isEdited
        createdAt = comment.createdAt
        updatedAt = comment.updatedAt
        childrenNumber = comment.childrenNumber
        parentId = comment.parentId
        userId = comment.userId
        childrenComment = comment.childrenComments.map { AmityCommentModel(comment: $0) }
        self.comment = comment
        isAuthorGlobalBanned = comment.user?.isGlobalBanned ?? false
        metadata = comment.metadata
        mentionees = comment.mentionees
        reactions = comment.reactions as? [String: Int] ?? [:]
        switch comment.target {
        case .community(let communityId, let communityMember):
            self.communityId = communityId
            if let communityMember {
                isModerator = communityMember.hasModeratorRole
            }
        default:
            break
        }
        
        syncState = comment.syncState
        flagCount = comment.flagCount
        
        // reactions are ordered by the count. if the count is equal, order by alphabet
        // if the count is 1 and the reaction is the same as current user's first reaction, remove it from the list
        // as current user already added a new reaction.
        var sortedReactions = comment.reactions?.compactMap({ key, value in
            if (value as? Int) ?? 0 > 0 {
                return (key: key, count: (value as? Int) ?? 0)
            }
            return nil
        })
        .sorted { first, second in
            if first.count != second.count {
                return first.count > second.count
            }
            return first.key < second.key
        }
        .filter { !($0.count == 1 && comment.myReactions.count > 1 && $0.key == comment.myReactions.first) }
        
        // if the count is more than 1 and the reaction is the same as current user's first reaction, reduce count 1
        // as current user already added a new reaction.
        if comment.myReactions.count > 1 {
            if let index = sortedReactions?.firstIndex(where: { $0.key == comment.myReactions.first }) {
                sortedReactions?[index].count -= 1
            }
        }
        
        allReactions = sortedReactions?.map { $0.key } ?? []
        reactionsCount = sortedReactions?.reduce(0) { $0 + $1.count } ?? 0
    }
    
    var isChildrenExisted: Bool {
        return comment.childrenNumber > 0
    }
    
    var isOwner: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    var isParent: Bool {
        return parentId == nil
    }
}
