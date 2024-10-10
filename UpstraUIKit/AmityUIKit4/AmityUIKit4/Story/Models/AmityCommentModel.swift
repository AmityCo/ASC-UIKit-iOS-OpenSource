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
    private let myReactions: [String]
    var metadata: [String: Any]?
    var mentioneeBuilder: AmityMentioneesBuilder?
    let mentionees: [AmityMentionees]?
    let reactions: [String: Int]
    var isModerator: Bool = false
    let syncState: AmitySyncState
    var communityId: String?
    
    // Due to AmityChat 4.0.0 requires comment object for editing and deleting
    // So, this is a workaroud for passing the original object.
    let comment: AmityComment
    
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
        myReactions = comment.myReactions
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
    }
    
    var isChildrenExisted: Bool {
        return comment.childrenNumber > 0
    }
    
    var reactionsCount: Int {
        return Int(comment.reactionsCount)
    }
    
    var isLiked: Bool {
        return myReactions.contains("like")
    }
    
    var isOwner: Bool {
        return userId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    var isParent: Bool {
        return parentId == nil
    }
    
}
