//
//  MessageModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import Foundation
import AmitySDK

public struct MessageModel: Identifiable, CustomDebugStringConvertible {
    
    public let id: String
    public let displayName: String
    public let text: String
    public let isEdited: Bool
    public let type: AmityMessageType
    public let parentId: String?
    public let hasReaction: Bool
    public let avatarURL: URL?
    public let createdAt: Date
    public let userId: String
    public let isDeleted: Bool
    public let metadata: [String: Any]?
    public let mentionees: [AmityMentionees]
    public let reactions: [String: Int]?
    public let myReactions: [String]
    public let syncState: AmitySyncState
    public let hasModeratorPermissionInChannel: Bool
    public let flagCount: Int
    public var isFlaggedByMe: Bool?
    public var reactionCount: Int
    
    var message: AmityMessage?
    
    public init(message: AmityMessage, hasModeratorPermission: Bool = false) {
        self.message = message
        self.id = message.messageId
        self.type = message.messageType
        self.text = message.data?["text"] as? String ?? type.description
        self.hasReaction = message.reactionCount > 0
        self.reactionCount = message.reactionCount
        self.parentId = message.parentId
        self.displayName = message.user?.displayName ?? ""
        self.avatarURL = URL(string: message.user?.getAvatarInfo()?.fileURL ?? "")
        self.isEdited = message.isEdited
        self.createdAt = message.createdAt
        self.userId = message.userId
        self.isDeleted = message.isDeleted
        self.metadata = message.metadata
        self.mentionees = message.mentionees ?? []
        self.reactions = message.reactions as? [String: Int]
        self.myReactions = message.myReactions
        self.syncState = message.syncState
        self.hasModeratorPermissionInChannel = hasModeratorPermission
        self.flagCount = message.flagCount
        self.isFlaggedByMe = message.flagCount > 0 ? MessageCache.shared.isFlaggedByMe(messageId: message.messageId) : false
    }
    
    public var isOwner: Bool {
        return self.userId == AmityUIKit4Manager.client.currentUserId
    }
        
    public var debugDescription: String {
        return "Id: \(self.id) | Text: \(self.text) | Metadata: \(String(describing: self.metadata)) | Mentionees: \(self.mentionees)"
    }
    
    // Replied message
    struct RepliedMessage {
        let displayName: String
        let text: String
    }
}

fileprivate extension AmityMessageType {
    
    var description: String {
        switch self {
        case .audio:
            return "Audio Message"
        case .file:
            return "File Message"
        case .image:
            return "Image Message"
        case .video:
            return "Video Message"
        case .custom:
            return "Custom Message"
        default:
            return "-"
        }
    }
}

// For Preview Purposes
extension MessageModel {
    
    internal init(id: String, text: String, type: AmityMessageType, hasReaction: Bool, parentId: String?) {
        self.id = id
        self.text = text
        self.type = type
        self.hasReaction = hasReaction
        self.parentId = parentId
        self.displayName = ""
        self.avatarURL = nil
        self.isEdited = false
        self.createdAt = Date()
        self.userId = ""
        self.isDeleted = false
        self.metadata = [:]
        self.mentionees = []
        self.reactions = [:]
        self.syncState = .default
        self.hasModeratorPermissionInChannel = false
        self.flagCount = 0
        self.isFlaggedByMe = false
        self.myReactions = []
        self.reactionCount = 0
    }
    
    static let preview = MessageModel.init(id: UUID().uuidString, text: "Let's catch up!", type: .text, hasReaction: false, parentId: nil)
    static let previewWithParent = MessageModel.init(id: UUID().uuidString, text: "Let's catch up! Its been a long time since we met", type: .text, hasReaction: false, parentId: "1234")
}
