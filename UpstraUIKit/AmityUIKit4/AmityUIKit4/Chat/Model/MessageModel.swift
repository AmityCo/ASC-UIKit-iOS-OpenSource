//
//  MessageModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/2/2567 BE.
//

import Foundation
import AmitySDK
import AVFoundation

// MARK: - Local video thumbnail cache
enum LocalVideoThumbnailCache {
    private static let queue = DispatchQueue(label: "amityuikit.localVideoThumbnail",
                                             attributes: .concurrent)
    private static var storeByName: [String: URL] = [:]
    private static var storeByAbsolute: [String: URL] = [:]
    private static var storeById: [String: URL] = [:]

    @discardableResult
    static func generateAndCache(videoURL: URL) -> URL? {
        let nameKey = videoURL.lastPathComponent
        var existing: URL?
        queue.sync { existing = storeByName[nameKey] }
        if let existing { return existing }

        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        var actualTime = CMTime.zero
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: &actualTime) else { return nil }

        let image = UIImage(cgImage: cgImage)
        guard let data = image.jpegData(compressionQuality: 0.6) else { return nil }
        let tmpDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tmpDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)

        queue.async(flags: .barrier) {
            storeByName[nameKey] = fileURL
            storeByAbsolute[videoURL.absoluteString] = fileURL
        }
        return fileURL
    }

    static func associate(thumbnailURL: URL, withId id: String) {
        guard !id.isEmpty else { return }
        queue.async(flags: .barrier) {
            storeById[id] = thumbnailURL
        }
    }

    static func thumbnailURL(forId id: String) -> URL? {
        guard !id.isEmpty else { return nil }
        var result: URL?
        queue.sync { result = storeById[id] }
        return result
    }

    static func thumbnailURL(forFileURL fileURL: String) -> URL? {
        var result: URL?
        queue.sync {
            if let url = storeByAbsolute[fileURL] { result = url; return }
            let name = (fileURL as NSString).lastPathComponent
            if let url = storeByName[name] { result = url; return }
            for (key, url) in storeByName {
                if fileURL.contains(key) || name == key {
                    result = url; break
                }
            }
        }
        return result
    }
}

// MARK: - Local image thumbnail cache
enum LocalImageThumbnailCache {
    private static let queue = DispatchQueue(label: "amityuikit.localImageThumbnail",
                                             attributes: .concurrent)
    private static var storeByName: [String: URL] = [:]
    private static var storeByAbsolute: [String: URL] = [:]

    static func cache(imageURL: URL) {
        let nameKey = imageURL.lastPathComponent
        queue.async(flags: .barrier) {
            storeByName[nameKey] = imageURL
            storeByAbsolute[imageURL.absoluteString] = imageURL
        }
    }

    static func thumbnailURL(forFileURL fileURL: String) -> URL? {
        var result: URL?
        queue.sync {
            if let url = storeByAbsolute[fileURL] { result = url; return }
            let name = (fileURL as NSString).lastPathComponent
            if let url = storeByName[name] { result = url; return }
            for (key, url) in storeByName {
                if fileURL.contains(key) || name == key {
                    result = url; break
                }
            }
        }
        return result
    }
}

public struct MessageModel: Identifiable, CustomDebugStringConvertible {

    public let id: String
    public let uniqueId: String
    public let displayName: String
    public let text: String
    public let isEdited: Bool
    public let type: AmityMessageType
    public let parentId: String?
    public let hasReaction: Bool
    public let avatarURL: URL?
    public let createdAt: Date?
    public let user: AmityUser?
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

    public var isUploadCancelled: Bool = false

    public let isGroupChat: Bool

    public let isSenderModerator: Bool

    var message: AmityMessage?
    
    public var imageURL: URL? {
        guard let fileURLString = message?.getImageInfo()?.fileURL else { return nil }
        return URL(string: fileURLString)
    }

    public var mediumFileURL: URL? {
        if let fileURLString = message?.getImageInfo()?.fileURL,
           let local = LocalImageThumbnailCache.thumbnailURL(forFileURL: fileURLString) {
            return local
        }
        if let fileURLString = message?.getImageInfo()?.mediumFileURL,
           let url = URL(string: fileURLString) {
            return url
        }
        return nil
    }

    public var largeImageURL: URL? {
        guard let fileURLString = message?.getImageInfo()?.largeFileURL else { return nil }
        return URL(string: fileURLString)
    }

    public var videoThumbnailURL: URL? {
        if let m = message,
           let local = LocalVideoThumbnailCache.thumbnailURL(forId: m.uniqueId) {
            return local
        }
        if let m = message,
           let local = LocalVideoThumbnailCache.thumbnailURL(forId: m.messageId) {
            return local
        }
        if let videoFileURL = message?.getVideoInfo()?.fileURL,
           !videoFileURL.isEmpty,
           let local = LocalVideoThumbnailCache.thumbnailURL(forFileURL: videoFileURL) {
            return local
        }
        if let fileURLString = message?.getVideoThumbnailInfo()?.fileURL,
           !fileURLString.isEmpty,
           let url = URL(string: fileURLString) {
            return url
        }
        return nil
    }

    public var videoPlaybackURL: URL? {
        guard let info = message?.getVideoInfo() else { return nil }
        let preferred: [AmityVideoResolution] = [.res_1080p, .res_720p, .res_480p, .res_360p]
        for res in preferred {
            if let urlStr = info.getVideo(resolution: res), let url = URL(string: urlStr) {
                return url
            }
        }
        return URL(string: info.fileURL)
    }
    
    public init(message: AmityMessage, hasModeratorPermission: Bool = false, isGroupChat: Bool = false, isSenderModerator: Bool = false) {
        self.message = message
        self.id = message.messageId
        self.uniqueId = message.uniqueId
        self.type = message.messageType
        self.text = message.data?["text"] as? String ?? type.description
        self.hasReaction = message.reactionCount > 0
        self.reactionCount = message.reactionCount
        self.parentId = message.parentId
        let isUserDeleted = message.user?.isDeleted ?? false
        self.displayName = isUserDeleted
            ? AmityLocalizedStringSet.Chat.deletedUser.localizedString
            : (message.user?.displayName ?? "")
        self.avatarURL = message.user?.resolvedAvatarURL
        self.isEdited = message.isEdited
        self.createdAt = message.createdAt
        self.user = message.user
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
        self.isGroupChat = isGroupChat
        self.isSenderModerator = isSenderModerator
    }

    public var isOwner: Bool {
        return self.userId == AmityUIKit4Manager.client.currentUserId
    }
        
    public var debugDescription: String {
        return "Id: \(self.id) | Text: \(self.text) | Metadata: \(String(describing: self.metadata)) | Mentionees: \(self.mentionees)" // l10n:ok debug description not user-facing
    }
    
    // Replied message
    struct RepliedMessage {
        let displayName: String
        let userId: String
        let text: String
        let type: AmityMessageType
        let isDeleted: Bool
        let imageURL: URL?
        let videoThumbnailURL: URL?

        init(displayName: String, text: String) {
            self.displayName = displayName
            self.userId = ""
            self.text = text
            self.type = .text
            self.isDeleted = false
            self.imageURL = nil
            self.videoThumbnailURL = nil
        }

        init(displayName: String, userId: String, text: String, type: AmityMessageType, isDeleted: Bool, imageURL: URL?, videoThumbnailURL: URL?) {
            self.displayName = displayName
            self.userId = userId
            self.text = text
            self.type = type
            self.isDeleted = isDeleted
            self.imageURL = imageURL
            self.videoThumbnailURL = videoThumbnailURL
        }
    }
}

fileprivate extension AmityMessageType {

    var description: String {
        switch self {
        case .text:
            return ""
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
            return ""
        }
    }
}

// For Preview Purposes
extension MessageModel {
    
    internal init(id: String, text: String, type: AmityMessageType, hasReaction: Bool, parentId: String?) {
        self.id = id
        self.uniqueId = UUID().uuidString
        self.text = text
        self.type = type
        self.hasReaction = hasReaction
        self.parentId = parentId
        self.displayName = ""
        self.avatarURL = nil
        self.isEdited = false
        self.createdAt = Date()
        self.user = nil
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
        self.isGroupChat = false
        self.isSenderModerator = false
    }
    
    static let preview = MessageModel.init(id: UUID().uuidString, text: "Let's catch up!", type: .text, hasReaction: false, parentId: nil) // l10n:ok preview mock data
    static let previewWithParent = MessageModel.init(id: UUID().uuidString, text: "Let's catch up! Its been a long time since we met", type: .text, hasReaction: false, parentId: "1234") // l10n:ok preview mock data
}

extension MessageModel: Equatable {
    public static func == (lhs: MessageModel, rhs: MessageModel) -> Bool {
        return lhs.id == rhs.id
            && lhs.reactionCount == rhs.reactionCount
            && lhs.myReactions == rhs.myReactions
            && lhs.isEdited == rhs.isEdited
            && lhs.isDeleted == rhs.isDeleted
            && lhs.syncState == rhs.syncState
            && lhs.text == rhs.text
            && lhs.mediumFileURL == rhs.mediumFileURL
            && lhs.videoThumbnailURL == rhs.videoThumbnailURL
    }
}
