//
//  AmityPostModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/7/24.
//

import Foundation
import AmitySDK
import UIKit

extension AmityPostModel {
    
    public class PollModel {
        
        // Public
        public let id: String
        public let question: String
        public let answers: [Answer]
        public let canVoteMultipleOptions: Bool
        public let status: String
        public let isClosed: Bool
        public let isVoted: Bool
        public let closedIn: UInt64 // This time is in milliseconds.
        public let voteCount: Int
        public let createdAt: Date
        
        public let isOpen: Bool
        
        public init(poll: AmityPoll) {
            self.id = poll.pollId
            self.question = poll.question
            self.canVoteMultipleOptions = poll.isMultipleVote
            self.status = poll.status
            self.isClosed = poll.isClosed
            self.isVoted = poll.isVoted
            self.closedIn = UInt64(poll.closedIn)
            self.voteCount = Int(poll.voteCount)
            self.answers = poll.answers.map { Answer(answer: $0) }
            self.createdAt = poll.createdAt
            self.isOpen = !poll.isClosed || !poll.isVoted
        }
        
        public class Answer: Identifiable {
            public let id: String
            public let dataType: String
            public let text: String
            public let isVotedByUser: Bool
            public let voteCount: Int
            
            public init(answer: AmityPollAnswer) {
                self.id = answer.answerId
                self.dataType = answer.dataType
                self.text = answer.text
                self.isVotedByUser = answer.isVotedByUser
                self.voteCount = Int(answer.voteCount)
            }
        }
    }

}

extension AmityPostModel {
    
    public enum PostDisplayType {
        case feed
        case postDetail
    }
    
    
    public enum LivestreamState {
        case live
        case ended
        case terminated
        case recorded
        case idle
        case none
    }
    
    
    public class Author {
        public let avatarURL: String?
        public let displayName: String?
        public let isGlobalBan: Bool
        public let isBrand: Bool
        
        public init( avatarURL: String?, displayName: String?, isGlobalBan: Bool, isBrand: Bool) {
            self.avatarURL = avatarURL
            self.displayName = displayName
            self.isGlobalBan = isGlobalBan
            self.isBrand = isBrand
        }
    }
    
    open class AmityPostAppearance {
        
        public init () { }
        
        /**
         * The displayType of view `Feed/PostDetail`
         */
        public var displayType: PostDisplayType = .feed
        
        /**
         * The flag for showing comunity name
         */
        public var shouldShowCommunityName: Bool = true
        
        /**
         * The flag marking a post for how it will display
         *  - true : display a full content
         *  - false : display a partial content with read more button
         */
        public var isExpanding: Bool = false
        
        /**
         * The flag for handling content expansion state
         */
        public var shouldContentExpand: Bool {
            switch displayType {
            case .feed:
                return isExpanding
            case .postDetail:
                return true
            }
        }
        
        /**
         * The flag for showing option
         */
        public var shouldShowOption: Bool {
            switch displayType {
            case .feed:
                return true
            case .postDetail:
                return false
            }
        }
    }
    
}

public class AmityPostModel: Identifiable {
    
    enum DataType: String {
        case text
        case image
        case file
        case video
        case poll
        case liveStream
        case unknown
    }
    
    // MARK: - Public variables
    
    /**
     * The unique identifier for the post
     */
    public let postId: String
    
    /**
     * The unique identifier for the post user id
     */
    public let postedUserId: String
    
    /**
     * The data type of the post
     */
    public let dataType: String
    
    /**
     * The reactions of the post
     */
    public let myReactions: [ReactionType]
    
    /**
     * All reactions of the post includes unsupported types
     */
    public let allReactions: [String]
    
    /// List of all reactions in this post with count.
    public let reactions: [String: Int]
    
    /**
     * Id of the target this post belongs to.
     */
    public let targetId: String
    
    /**
     * The custom data of the post
     */
    public let data: [String: Any]
    
    /**
      Media data of the post
     */
    public var medias: [AmityMedia] = []
    
    /**
     * The post target community
     */
    public let targetCommunity: AmityCommunity?
    
    /**
     * The post metadata
     */
    public let metadata: [String: Any]?
    
    /**
     * The post mentionees
     */
    public let mentionees: [AmityMentionees]?
    
    /**
     * The post target type
     */
    public var postTargetType: AmityPostTargetType {
        return targetCommunity == nil ? .user : .community
    }
    
    /**
     * The post is owner flag
     */
    public var isOwner: Bool {
        return postedUserId == AmityUIKitManagerInternal.shared.client.currentUserId
    }
    
    public var isEdited: Bool
    
    /**
     * The post commentable flag
     */
    public var isCommentable: Bool {
        if let targetCommunity = self.targetCommunity {
            // Community feed requires membership before commenting.
            return targetCommunity.isJoined
        }
        // All user feeds are commentable.
        return true
    }
    
    /**
     * The post is group member flag
     */
    public var isGroupMember: Bool {
        return targetCommunity?.isJoined ?? false
    }
    
    /**
     * The post user data of the post
     */
    public var postedUser: AmityPostModel.Author?
    
    /**
     * Posted user display name
     */
    public var displayName: String {
        return postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
    }
    
    /**
     Timestamp string of the post
     */
    public let timestamp: String
        
    /**
     * A reaction count of post
     */
    public let reactionsCount: Int
    
    /**
     * A comment count of post
     */
    public let allCommentCount: Int
    
    /**
     * A share count of post
     */
    public let sharedCount: Int
    
    /**
     * The post appearance settings
     */
    public var appearance: AmityPostAppearance
    
    public var poll: AmityPostModel.PollModel?
    
    public var isPinned: Bool
    
    public let analytic: AmityPostAnalytics
    
    public let impression: Int
    
    var commentExpandedIds: Set<String> = []
    
    // MARK: - Internal variables
    
    var dataTypeInternal: DataType = .unknown
    var isModerator: Bool = false
    var hasModeratorPermission: Bool = false
    let parentPostId: String?
    let latestComments: [AmityCommentModel]
    let postAsModerator: Bool = false
    private(set) var text: String = ""
    private(set) var liveStream: AmityStream?
    private(set) var livestreamState: LivestreamState = .none
    let object: AmityPost
    private let childrenPosts: [AmityPost]
    
    // Maps fileId to PostId for child post
    private var fileMap = [String: String]()
    
    let isFromBrand: Bool
    let isTargetPublicCommunity: Bool
    let isTargetOfficialCommunity: Bool
    
    // Owner of the feed if targetType is user
    var targetUser: AmityUser?
    
    var isLiked: Bool {
        return myReactions.contains(.like)
    }
    
    private(set) var feedType: AmityFeedType = .published
    
    // MARK: - Initializer
    
    public init(post: AmityPost, isPinned: Bool = false) {
        self.object = post
        postId = post.postId
        latestComments = post.latestComments.map(AmityCommentModel.init)
        dataType = post.dataType
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
        reactionsCount = Int(post.reactionsCount)
        reactions = post.reactions as? [String: Int] ?? [:]
        allCommentCount = Int(post.commentsCount)
        allReactions = post.myReactions
        myReactions = allReactions.compactMap(ReactionType.init)
        feedType = post.getFeedType()
        data = post.data ?? [:]
        appearance = AmityPostAppearance()
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
        
        extractPostData()
    }
    
    // MARK: - Helper methods
    
    public var maximumLastestComments: Int {
        return min(2, latestComments.count)
    }
    
    public var viewAllCommentSection: Int {
        return latestComments.count > 2 ? 1 : 0
    }
    
    // Comment will show below last component
    public func getComment(at indexPath: IndexPath, totalComponent index: Int) -> AmityCommentModel? {
        let comments = Array(latestComments.suffix(maximumLastestComments).reversed())
        return comments.count > 0 ? comments[indexPath.row - index] : nil
    }
    
    // Returns post id for file id
    func getPostId(forFileId fileId: String) -> String? {
        guard let postId = fileMap[fileId] else {
            assertionFailure("A fileId must exist")
            return nil
        }
        return postId
    }
    
    // Each post has a property called childrenPosts. This contains an array of AmityPost object.
    // If a post contains files or images, those are present as children posts. So we need
    // to go through that array to determine the post type.
    private func extractPostData() {
        
        text = data[DataType.text.rawValue] as? String ?? ""
        dataTypeInternal = DataType(rawValue: dataType) ?? .unknown
        
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
            if let imageData = post.getImageInfo() {
                let state = AmityMediaState.downloadableImage(
                    imageData: imageData,
                    placeholder: UIImage()
                )
                let media = AmityMedia(state: state, type: .image)
                media.image = imageData
                medias.append(media)
                fileMap[imageData.fileId] = post.postId
                dataTypeInternal = .image
            }
        case "file": break
//                if let fileData = aChild.getFileInfo() {
//                    let tempFile = AmityFile(state: .downloadable(fileData: fileData))
//                    files.append(tempFile)
//                    fileMap[fileData.fileId] = aChild.postId
//                    dataTypeInternal = .file
//                }
        case "video":
            if let videoData = post.getVideoInfo() {
                let thumbnail = post.getVideoThumbnailInfo()
                let state = AmityMediaState.downloadableVideo(
                    videoData: videoData,
                    thumbnailUrl: thumbnail?.fileURL
                )
                let media = AmityMedia(state: state, type: .video)
                media.video = videoData
                medias.append(media)
                fileMap[videoData.fileId] = post.postId
                dataTypeInternal = .video
            }
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
            }
        default:
            dataTypeInternal = .unknown
        }
    }
}


class PollStatus {
    var statusInfo: String = ""

    init(poll: AmityPostModel.PollModel) {
        if poll.isClosed {
            statusInfo = AmityLocalizedStringSet.Social.pollStatusEnded.localizedString
        } else {
            let closedInDate = poll.createdAt.addingTimeInterval(Double(poll.closedIn) / 1000)
            computeRemainingTime(closedInDate: closedInDate)
        }
    }
    
    private func computeRemainingTime(closedInDate: Date) {
        let currentDate = Date()
        
        if closedInDate > currentDate {
            let difference = Calendar.current.dateComponents([.day,.hour,.minute], from: currentDate, to: closedInDate)
            
            if let remainingDays = difference.day, remainingDays > 0 {
                // In case of 3 days, 22 hour, we will display 4 days
                let remainingHours = difference.hour ?? 0
                let roundUpValue = remainingHours > 0 ? 1 : 0
                statusInfo = RemainingTime.days(count: remainingDays + roundUpValue).info
                return
            }
            
            if let remainingHours = difference.hour, remainingHours > 0 {
                statusInfo = RemainingTime.hours(count: remainingHours).info
                return
            }
            
            if let remainingMinutes = difference.minute, remainingMinutes > 0 {
                statusInfo = RemainingTime.minutes(count: remainingMinutes).info
                return
            } else {
                // We don't want to show remaining time in seconds. So we just show `1 minute`
                statusInfo = RemainingTime.minutes(count: 1).info
                return
            }
            
        } else {
            statusInfo = AmityLocalizedStringSet.Social.pollStatusEnded.localizedString
        }
    }
}

extension PollStatus {
    
    private enum RemainingTime {
        case days(count: Int)
        case hours(count: Int)
        case minutes(count: Int)
        
        var info: String {
            switch self {
            case .days(let remainingDays):
                return "\(remainingDays)" + AmityLocalizedStringSet.Social.pollRemainingDaysLeft.localizedString
                
            case .hours(let remainingHours):
                return "\(remainingHours)" + AmityLocalizedStringSet.Social.pollRemainingHoursLeft.localizedString
                
            case .minutes(let remainingMinutes):
                return "\(remainingMinutes)" + AmityLocalizedStringSet.Social.pollRemainingMinutesLeft.localizedString
            }
        }
    }
}
