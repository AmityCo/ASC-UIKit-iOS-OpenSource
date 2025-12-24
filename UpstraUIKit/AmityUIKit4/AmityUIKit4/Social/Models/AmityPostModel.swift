//
//  AmityPostModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/7/24.
//
import Foundation
import AmitySDK
import UIKit
import SwiftUI

public class AmityPostModel: Identifiable {
    
    /// The unique identifier for the post
    public let postId: String
    
    /// The unique identifier for the post user id
    public let postedUserId: String
    
    /// The data type of the post
    public let dataType: String
    
    /// The structure type of the post
    public let structureType: String
    
    /// Id of the target this post belongs to.
    public let targetId: String
    
    /// The custom data of the post
    public let data: [String: Any]
    
    /// Media data of the post
    public var medias: [AmityMedia] = []
    
    /// The post target community
    public var targetCommunity: AmityCommunity?
    
    /// The post metadata
    public let metadata: [String: Any]?
    
    /// The post mentionees
    public let mentionees: [AmityMentionees]?
    
    /// The post target type
    public var postTargetType: AmityPostTargetType {
        return targetCommunity == nil ? .user : .community
    }
    
    /// The post is owner flag
    public var isOwner: Bool {
        return postedUserId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    public var isEdited: Bool
    
    /// The post commentable flag
    public var isCommentable: Bool {
        if let targetCommunity = self.targetCommunity {
            // Community feed requires membership before commenting.
            return targetCommunity.isJoined
        }
        // All user feeds are commentable.
        return true
    }
    
    /// The post is group member flag
    public var isGroupMember: Bool {
        return targetCommunity?.isJoined ?? false
    }
    
    /// The post user data of the post
    public var postedUser: AmityPostModel.Author?
    
    /// Posted user display name
    public var displayName: String {
        return postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
    }
    
    /// Timestamp string of the post
    public let timestamp: String
        
    /// A comment count of post
    public let allCommentCount: Int
    
    /// A share count of post
    public let sharedCount: Int
        
    public var poll: AmityPostModel.PollModel?
    
    public var isPinned: Bool
    
    public let analytic: AmityPostAnalytics
    
    public let impression: Int
    
    public var links: [AmityLink] = []
    
    var commentExpandedIds: Set<String> = []
    
    // MARK: - Internal variables
    
    var dataTypeInternal: DataType = .unknown
    var isModerator: Bool = false
    var hasModeratorPermission: Bool = false
    let parentPostId: String?
    let latestComments: [AmityCommentModel]
    let postAsModerator: Bool = false
    private(set) var text: String = ""
    private(set) var title: String = ""
    private(set) var liveStream: AmityStream?
    private(set) var livestreamState: LivestreamState = .none
    
    var room: AmityRoom?
    var event: AmityEvent?
    
    let object: AmityPost
    private let childrenPosts: [AmityPost]
    
    // Maps fileId to PostId for child post
    private var fileMap = [String: String]()
    
    let isFromBrand: Bool
    let isTargetPublicCommunity: Bool
    let isTargetOfficialCommunity: Bool
    
    // Owner of the feed if targetType is user
    var targetUser: AmityUser?
    
    private(set) var feedType: AmityFeedType = .published
    
    var isDeleted: Bool
    
    // Note:
    // Used only in clip & text post as the moment
    var content: PostContent = .text(value: "")
    
    // Computed property to get the latest comment that is not flagged or deleted
    var inlineComment: AmityCommentModel? {
        return latestComments.last { comment in
            !comment.isDeleted && comment.flagCount == 0
        }
    }
    
    /// Reaction data of the post
    
    /// All reactions of the post includes multiple types
    /// e.g. ["like", "love", "haha"]
    public let allReactions: [String]
    
    /// Current user's reaction to the post
    var myReaction: AmityReactionType? {
        guard let reaction = object.myReactions.last else { return nil }
        return SocialReactionConfiguration.shared.getReaction(withName: reaction)
    }
    
    /// All reaction count of the post
    var reactionsCount: Int
    
    // MARK: - Initializer
    
    public init(post: AmityPost, isPinned: Bool = false) {
        self.object = post
        postId = post.postId
        latestComments = post.latestComments.map(AmityCommentModel.init)
        dataType = post.dataType
        structureType = post.structureType
        targetId = post.targetId
        targetCommunity = post.targetCommunity
        childrenPosts = post.childrenPosts
        parentPostId = post.parentPostId
        postedUser = Author(
            avatarURL: post.postedUser?.getAvatarInfo()?.fileURL,
            displayName: post.postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, isGlobalBan: post.postedUser?.isGlobalBanned ?? false, isBrand: post.postedUser?.isBrand ?? false)
        isFromBrand = post.postedUser?.isBrand ?? false
        timestamp = post.createdAt.relativeTime
        postedUserId = post.postedUserId
        sharedCount = Int(post.sharedCount)
        allCommentCount = Int(post.commentsCount)
        links = post.links
        
        // reactions are ordered by the count. if the count is equal, order by alphabet
        // if the count is 1 and the reaction is the same as current user's first reaction, remove it from the list
        // as current user already added a new reaction.
        var sortedReactions = post.reactions?.compactMap({ key, value in
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
        .filter { !($0.count == 1 && post.myReactions.count > 1 && $0.key == post.myReactions.first) }
        
        // if the count is more than 1 and the reaction is the same as current user's first reaction, reduce count 1
        // as current user already added a new reaction.
        if post.myReactions.count > 1 {
            if let index = sortedReactions?.firstIndex(where: { $0.key == post.myReactions.first }) {
                sortedReactions?[index].count -= 1
            }
        }
        
        allReactions = sortedReactions?.map { $0.key } ?? []
        reactionsCount = sortedReactions?.reduce(0) { $0 + $1.count } ?? 0
        
        feedType = post.getFeedType()
        data = post.data ?? [:]
        metadata = post.metadata
        mentionees = post.mentionees
        isEdited = post.isEdited
        analytic = post.analytics
        impression = post.impression
        
        if let pollInfo = post.getPollInfo() {
            poll = PollModel(poll: pollInfo)
            text = poll?.question ?? ""
        }

        self.isPinned = isPinned
        isTargetPublicCommunity = post.targetCommunity?.isPublic ?? false
        isTargetOfficialCommunity = post.targetCommunity?.isOfficial ?? false
        if let communityMember = targetCommunity?.membership.getMember(withId: postedUserId) {
            isModerator = communityMember.hasModeratorRole
        }
        
        if let communityMember = targetCommunity?.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId) {
            hasModeratorPermission = communityMember.hasModeratorRole
        }
        
        if post.targetType == "user" {
            self.targetUser = post.targetUser
        }
        
        self.isDeleted = post.isDeleted
        
        extractPostData()
    }
        
    // Each post has a property called childrenPosts. This contains an array of AmityPost object.
    // If a post contains files or images, those are present as children posts. So we need
    // to go through that array to determine the post type.
    private func extractPostData() {
        
        text = data[DataType.text.rawValue] as? String ?? ""
        title = data["title"] as? String ?? ""
        dataTypeInternal = DataType(rawValue: dataType) ?? .unknown
        
        content = .text(value: text)
        
        // Get media data if parent post itself is not text type.
        // If the posts are queried with a specific data type, parent post is the post of data type and it does not have any child posts.
        if childrenPosts.isEmpty && object.dataType != "text" {
            prepareData(object)
        }
        
        for childPost in childrenPosts {
            prepareData(childPost)
        }
    }
    
    private func prepareData(_ post: AmityPost) {
        switch post.dataType {
        case "image":
            // Create a media object regardless of whether imageData can be retrieved
            let imageData = post.getImageInfo()
            
            // If we have image data, use it
            if let imageData = imageData {
                let state = AmityMediaState.downloadableImage(
                    imageData: imageData,
                    placeholder: UIImage()
                )
                let media = AmityMedia(state: state, type: .image)
                media.image = imageData
                media.parentPostId = post.parentPostId
                medias.append(media)
                fileMap[imageData.fileId] = post.postId
            } else {
                // Still create a media object with placeholder state when image data is missing
                // This ensures the UI can show something (gray placeholder) for the missing image
                let media = AmityMedia(state: .none, type: .image)
                media.parentPostId = post.parentPostId
                medias.append(media)
            }
            
            dataTypeInternal = .image
            
        case "video":
            // Similar approach for video - create media even if data is missing
            let videoData = post.getVideoInfo()
            let thumbnail = post.getVideoThumbnailInfo()
            
            if let videoData = videoData {
                let state = AmityMediaState.downloadableVideo(
                    videoData: videoData,
                    thumbnailUrl: thumbnail?.fileURL
                )
                let media = AmityMedia(state: state, type: .video)
                media.video = videoData
                media.parentPostId = post.parentPostId
                medias.append(media)
                fileMap[videoData.fileId] = post.postId
            } else {
                // Create placeholder for missing video
                let media = AmityMedia(state: .none, type: .video)
                media.parentPostId = post.parentPostId
                medias.append(media)
            }
            
            dataTypeInternal = .video
            
        case "file": break
//                if let fileData = aChild.getFileInfo() {
//                    let tempFile = AmityFile(state: .downloadable(fileData: fileData))
//                    files.append(tempFile)
//                    fileMap[fileData.fileId] = aChild.postId
//                    dataTypeInternal = .file
//                }
        case "poll":
                dataTypeInternal = .poll
        case "liveStream":
            if let liveStreamData = post.getLiveStreamInfo() {
                liveStream = liveStreamData
                dataTypeInternal = .liveStream
                
                if !(liveStreamData.moderation?.terminateLabels.isEmpty ?? true) {
                    livestreamState = .terminated
                } else if liveStreamData.status == AmityStreamStatus.ended {
                    livestreamState = .ended
                } else if liveStreamData.status == AmityStreamStatus.live {
                    livestreamState = .live
                } else if liveStreamData.status == AmityStreamStatus.recorded {
                    livestreamState = .recorded
                } else {
                    livestreamState = .idle
                }
                
                // If stream is deleted but post is still there (due to be bug), show this stream is currently unavailable text.
                if liveStreamData.isDeleted {
                    livestreamState = .idle
                }
            }
            
        case "room":
            if let roomData = post.getRoomInfo() {
                room = roomData
                dataTypeInternal = .room
                
                if !(roomData.moderation?.terminateLabels.isEmpty ?? true) {
                    livestreamState = .terminated
                } else if roomData.status == AmityRoomStatus.ended {
                    livestreamState = .ended
                } else if roomData.status == AmityRoomStatus.live || roomData.status == AmityRoomStatus.waitingReconnect {
                    livestreamState = .live
                } else if roomData.status == AmityRoomStatus.recorded {
                    livestreamState = .recorded
                } else {
                    livestreamState = .idle
                }
                
                // If stream is deleted but post is still there (due to be bug), show this stream is currently unavailable text.
                if roomData.isDeleted {
                    livestreamState = .idle
                }
            }
            
        case "clip":
            
            let isMuted = post.data?["isMuted"] as? Bool ?? false
            let displayMode = AmityClipDisplayMode(rawValue: post.data?["displayMode"] as? String ?? "") ?? .fit
            
            let clipData = post.getClipInfo()
            let thumbnail = post.getVideoThumbnailInfo()
            
            
            let clipMetadata = clipData?.attributes["metadata"] as? [String: Any]
            let clipVideoMetadata = clipMetadata?["video"] as? [String: Any]
            let duration = clipVideoMetadata?["duration"] as? TimeInterval
            
            self.content = PostContent.clip(data: ClipContent(text: self.text, url: clipData?.fileURL ?? "", thumbnailUrl: thumbnail?.fileURL ?? "", isMuted: isMuted, displayMode: displayMode, duration: duration ?? 0))
            
            if let clipData {
                let state = AmityMediaState.downloadableClip(
                    clipData: clipData,
                    thumbnailUrl: thumbnail?.fileURL
                )
                let media = AmityMedia(state: state, type: .video)
                media.clip = clipData
                media.parentPostId = post.parentPostId
                medias.append(media)
                fileMap[clipData.fileId] = post.postId
            } else {
                // Create placeholder for missing video
                let media = AmityMedia(state: .none, type: .video)
                media.parentPostId = post.parentPostId
                medias.append(media)
            }
            
            dataTypeInternal = .clip
            
        default:
            dataTypeInternal = .unknown
        }
    }
}

enum PostContent {
    case text(value: String)
    case clip(data: AmityPostModel.ClipContent)
}

extension AmityPostModel {
    
    struct ClipContent {
        let text: String
        let url: String
        let thumbnailUrl: String
        let isMuted: Bool
        let displayMode: AmityClipDisplayMode
        let duration: TimeInterval
        
        init(text: String, url: String, thumbnailUrl: String, isMuted: Bool, displayMode: AmityClipDisplayMode, duration: TimeInterval = 0) {
            self.text = text
            self.url = url
            self.thumbnailUrl = thumbnailUrl
            self.isMuted = isMuted
            self.displayMode = displayMode
            self.duration = duration
        }
    }
}

extension AmityClipDisplayMode {
    
    // SwiftUI content mode mapped with display mode
    var contentMode: ContentMode {
        switch self {
        case .fill:
            return .fill
        default:
            return .fit
        }
    }
}
