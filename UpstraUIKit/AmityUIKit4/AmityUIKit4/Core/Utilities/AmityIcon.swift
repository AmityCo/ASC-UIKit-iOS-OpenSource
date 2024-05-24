//
//  AmityIcon.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import UIKit

enum AmityIcon: String, ImageResourceProvider {
    case verifiedBadge = "verifiedBadge"
    case createStoryIcon = "createStoryIcon"
    case errorStoryIcon = "errorStoryIcon"
    case closeIcon = "closeIcon"
    case grayCloseIcon = "grayCloseIcon"
    case threeDotIcon = "threeDotIcon"
    case statusSuccessIcon = "statusSuccessIcon"
    case statusWarningIcon = "statusWarningIcon"
    case statusLoadingIcon = "statusLoadingIcon"
    case defaultCommunityAvatar = "defaultCommunityAvatar"
    case flagIcon = "flagIcon"
    case lockIcon = "lockIcon"
    case lockBlackIcon = "lockBlackIcon"
    
    // AmityCreateStoryPage Icons
    case backgroundedCloseIcon = "backgroundedCloseIcon"
    case galleryIcon = "galleryIcon"
    case flipCameraIcon = "flipCameraIcon"
    case flashOffIcon = "flashOffIcon"
    case flashOnIcon = "flashOnIcon"
    case cameraShutterIcon = "cameraShutterIcon"
    case videoShutterIcon = "videoShutterIcon"
    case videoShutterRecordingIcon = "videoShutterRecordingIcon"
    
    // AmityDraftStoryPage Icons
    case backArrowIcon = "backArrowIcon"
    case nextIcon = "nextIcon"
    case aspectRatioIcon = "aspectRatioIcon"
    case hyperLinkIcon = "hyperLinkIcon"
    case hyperLinkBlueIcon = "hyperLinkBlueIcon"
    case trashBinRedIcon = "trashBinRedIcon"
    case likeReactionIcon = "likeReactionIcon"
    
    // AmityViewStoryPage Icons
    case verifiedWhiteBadge = "verifiedWhiteBadge"
    case eyeIcon = "eyeIcon"
    case storyLikeIcon = "storyLikeIcon"
    case storyCommentIcon = "storyCommentIcon"
    case avatarPlaceholder = "avatarPlaceholder"
    case defaultCommunity = "defaultCommunity"
    case muteIcon = "muteIcon"
    case unmuteIcon = "unmuteIcon"
    case trashBinIcon = "trashBinIcon"
    
    
    // AmityCommentTrayComponent Icons
    case meetballIcon = "meetballIcon"
    case replyArrowIcon = "replyArrowIcon"
    case deletedMessageIcon = "deletedMessageIcon"
    case editCommentIcon = "editCommentIcon"
    case moderatorBadgeIcon = "moderatorBadgeIcon"
    case commentFailedIcon = "failedCommentIcon"
    
    // AmityTargetSelectionPage Icons
    case backIcon = "backIcon"
    // AmityMessageListBubble Icons
    case trashBinWhiteIcon = "trashBinWhiteIcon"
    
    case emptyReaction = "emptyReactionIcon"
    
    enum Chat: String, ImageResourceProvider {
        case sendMessage = "sendIconEnable"
        case closeReply = "grayCloseIcon"
        case membersCount = "membersCountIcon"
        
        case emptyStateMessage = "emptyStateMessage"
        case greyRetryIcon = "greyRetryIcon"
        case chatAvatarProfilePlaceholder = "chatAvatarProfilePlaceholder"
        case mentionAll = "mentionAll"
        case messageBubbleAddReactionIcon = "messageBubbleAddReactionIcon"
        case messageReactionNotFound = "messageReactionNotFound"
        case heartReactionIcon = "heartReactionIcon"
        case chatAvatarPlaceholder = "chatAvatarPlaceholder"
        case messageErrorIcon = "messageErrorIcon"
        
        case redTrashIcon = "redTrashIcon"
        case replyIcon = "replyIcon"
        case copyIcon = "copyIcon"
        case redFlagIcon = "redFlagIcon"
        case mutedIcon = "mutedIcon"
        case unknownReaction = "reactionUnknown"
    }
    
    func getURL() -> URL {
        let path = AmityUIKit4Manager.bundle.path(forResource: self.rawValue, ofType: ".svg")
        return URL(fileURLWithPath: path ?? "")
    }
    
    func getImage() -> UIImage? {
        return UIImage(named: self.rawValue, in: AmityUIKit4Manager.bundle, compatibleWith: nil)
    }
    
    func getImageResource() -> ImageResource {
        return ImageResource(name: self.rawValue, bundle: AmityUIKit4Manager.bundle)
    }
    
    static func getImage(named: String) -> UIImage? {
        return UIImage(named: named, in: AmityUIKit4Manager.bundle, compatibleWith: nil)
    }
    
    static func getImageResource(named: String) -> ImageResource {
        return ImageResource(name: named, bundle: AmityUIKit4Manager.bundle)
    }
    
}

protocol ImageResourceProvider: RawRepresentable {
    
    var imageResource: ImageResource { get }
}

extension ImageResourceProvider where Self.RawValue == String {
    
    var imageResource: ImageResource {
        ImageResource(name: self.rawValue, bundle: AmityUIKit4Manager.bundle)
    }
}
