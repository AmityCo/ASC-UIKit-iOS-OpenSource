//
//  AmityIcon.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import UIKit

enum AmityIcon: String, ImageResourceProvider {
    // MARK: Story
    case verifiedBadge = "verifiedBadge"
    case verifiedBadgeWithBorder = "verifiedBadgeWithBorder"
    case createStoryIcon = "createStoryIcon"
    case errorStoryIcon = "errorStoryIcon"
    case closeIcon = "closeIcon"
    case grayCloseIcon = "grayCloseIcon"
    case threeDotIcon = "threeDotIcon"
    case statusSuccessIcon = "statusSuccessIcon"
    case statusWarningIcon = "statusWarningIcon"
    case statusLoadingIcon = "statusLoadingIcon"
    case toastStatusWarningIcon = "toastStatusWarningIcon"
    case defaultCommunityAvatar = "defaultCommunityAvatar"
    case flagIcon = "flagIcon"
    case unflagIcon = "unflagIcon"
    case lockIcon = "lockIcon"
    case lockBlackIcon = "lockBlackIcon"
    case settingIcon = "settingIcon"
    
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
    
    // MARK: Chat
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
        case sendActionIcon = "sendActionIcon"
    }
    
    // MARK: Social
    case searchIcon = "searchIcon"
    case plusIcon = "plusIcon"
    case emptyNewsFeedIcon = "emptyNewsFeedIcon"
    case exploreIcon = "exploreIcon"
    case arrowIcon = "arrowIcon"
    case likeActionIcon = "likeActionIcon"
    case commentActionIcon = "commentActionIcon"
    case shareActionIcon = "shareActionIcon"
    case videoControlIcon = "videoControlIcon"
    case circleCloseIcon = "circleCloseIcon"
    case previewLinkDefaultIcon = "previewLinkDefaultIcon"
    case triangleErrorIcon = "triangleErrorIcon"
    case createPostMenuIcon = "createPostMenuIcon"
    case createStoryMenuIcon = "createStoryMenuIcon"
    case createPollMenuIcon = "createPollMenuIcon"
    case createLivestreamMenuIcon = "createLivestreamMenuIcon"
    case createClipMenuIcon = "createClipMenuIcon"
    case createEventMenuIcon = "createEventMenuIcon"
    case cameraAttatchmentIcon = "cameraAttatchmentIcon"
    case photoAttatchmentIcon = "photoAttatchmentIcon"
    case videoAttatchmentIcon = "videoAttatchmentIcon"
    case attatchmentIcon = "attatchmentIcon"
    case downArrowIcon = "downArrowIcon"
    case noSearchableIcon = "noSearchableIcon"
    case defaultSearchIcon = "defaultSearchIcon"
    case mediaUploadErrorIcon = "mediaUploadErrorIcon"
    case starIcon = "starIcon"
    case infoIcon = "infoIcon"
    case adAvatarPlaceholder = "adAvatarPlaceholder"
    case upArrowIcon = "upArrowIcon"
    case communityProfilePlaceholder = "communityProfilePlaceholder"
    case communityFeedIcon = "communityFeedIcon"
    case communityPinIcon = "communityPinIcon"
    case communityImageFeedIcon = "imageFeedIcon"
    case communityVideoFeedIcon = "videoFeedIcon"
    case communityAnnouncementBadge = "communityAnnouncementBadge"
    case communityPinBadge = "communityPinBadge"
    case communityProfileEmptyPostIcon = "communityProfileEmptyPostIcon"
    case communityProfileEmptyImageIcon = "communityProfileEmptyImageIcon"
    case communityProfileEmptyVideoIcon = "communityProfileEmptyVideoIcon"
    case communityProfileEmptyClipIcon = "emptyClipIcon"
    case communityPendingPostIcon = "communityPendingPostIcon"
    case tickIcon = "tickIcon"
    case communityCategoryPlaceholder = "categoriesPlaceholder"
    case communityPlaceholder = "communityPlaceholder"
    case communityThumbnail = "communityThumbnail"
    case emptyStateExplore = "emptyStateExplore"
    case communityNotFoundIcon = "communityNotFoundIcon"
    case pendingInvitationIcon = "pendingInvitationIcon"
    case videoNotAvailableIcon = "videoNotAvailableIcon"
    case imageNotAvailableIcon = "imageNotAvailableIcon"
    case inviteUserIcon = "inviteUserIcon"

    case brandBadge = "brandBadgeIcon"
    case globeIcon = "globeIcon"
    case globePrivateIcon = "globePrivateIcon"
    case checkboxIcon = "checkBoxIcon"
    case penIcon = "penIcon"
    case memberIcon = "memberIcon"
    case notificationIcon = "notificationIcon"
    case postPermissionIcon = "postPermissionIcon"
    case cameraIcon = "cameraIcon"
    case communityMemberIcon = "communityMemberIcon"
    case communityModeratorIcon = "communityModeratorIcon"
    case postMenuIcon = "postMenuIcon"
    case commentMenuIcon = "commentMenuIcon"
    case emptyPendingPostIcon = "emptyPendingPostIcon"
    case livestreamPlaceholder = "livestreamPlaceholder"
    case livestreamPlaceholderGray = "livestreamPlaceholderGray"
    case livestreamErrorIcon = "livestreamErrorIcon"
    case livestreamPauseIcon = "livestreamPauseIcon"
    case livestreamReconnectingIcon = "livestreamReconnectingIcon"
    case livestreamImpressionIcon = "livestreamImpressionIcon"
    case pendingUserFollowRequestIcon = "pendingUserFollowRequestIcon"
    case followingUserIcon = "followingUserIcon"
    case unfollowingUserIcon = "unfollowingUserIcon"
    case blockUserIcon = "blockUserIcon"
    case unblockUserIcon = "unblockUserIcon"
    case privateFeedIcon = "privateFeedIcon"
    case blockedFeedIcon = "blockedFeedIcon"
    case listRadioIcon = "listRadioIcon"
    case pollRadioIcon = "pollRadioIcon"
    case pollCheckboxIcon = "pollCheckboxIcon"
    case pollImageExpandIcon = "pollImageExpandIcon"
    case checkMarkIcon = "checkMarkIcon"
    
    case bellIcon = "bellIcon"
    case emptyNotificationList = "notificationTrayEmptyIcon"
    case noInternetIcon = "noInternetIcon"
    case reportSuccessIcon = "reportSuccessIcon"
    
    case cancelRequestIcon = "cancelRequestIcon"
    case clipFlashIcon = "clipFlashButton"
    case clipThumbnailIcon = "clipThumbnailIcon"
    
    case clipVideoStartButton = "clipVideoStartButton"
    case clipVideoStopButton = "clipVideoStopButton"
    
    case rightArrowIcon = "rightArrowIcon"
    
    case emptyClipFeedIcon = "emptyClipFeedIcon"
    
    case clipCommentIcon = "clipCommentIcon"
    case clipMuteIcon = "clipMuteIcon"
    case clipReactionIcon = "clipReactionIcon"
    case clipReactIconLike = "clipReactIconLike"
    case clipUnmuteIcon = "clipUnmuteIcon"
    
    case viewPostIcon = "viewPostIcon"
    case clipLoadingErrorIcon = "clipLoadingErrorIcon"
    case clipFeedCameraIcon = "clipFeedCameraIcon"
    case clipDeletedIcon = "clipDeletedIcon"
    case clipGlobeIcon = "clipGlobeIcon"
    case blindIcon = "blindIcon"
    
    case shareToIcon = "shareToIcon"
    case copyLinkIcon = "copyLinkIcon"
    case communityInformationIcon = "communityInformationIcon"
    
    case textPollOption = "textPollOption"
    case textPollOptionSelected = "textPollOptionSelected"
    case imagePollOption = "imagePollOption"
    case imagePollOptionSelected = "imagePollOptionSelected"
    case pollImageNotAvailableIcon = "pollImageNotAvailableIcon"
    case externalPlatformIcon = "externalPlatformIcon"
    case eventLocationIcon = "eventLocationIcon"
    case mediaFeedIcon = "mediaFeedIcon"
    case eventEmptyStateIcon = "eventEmptyStateIcon"
    case eventImagePlaceholder = "eventImagePlaceholder"
    case eventHostBadge = "eventHostBadge"
    case eventDiscussionTabIcon = "eventDiscussionTabIcon"
    case copyTextIcon = "copyTextIcon"
    case eventAddToCalendarIcon = "eventAddToCalendarIcon"
    case addToCalendarButtonIcon = "addToCalendarButtonIcon"
    case communityPeopleIcon = "communityPeopleIcon"
    case eventAttendeeIcon = "eventAttendeeIcon"
    case eventRSVPBellIcon = "eventRSVPBellIcon"
    
    // Livestream icons
    enum LiveStream: String, ImageResourceProvider {
        case shutterButtonEnabled = "ic_stream_button"
        case shutterButtonDisabled = "ic_stream_button_disabled"
        case targetSelectionArrow = "ic_arrow_down"
        case close = "ic_close"
        case thumbnail = "ic_thumbnail"
        case switchCamera = "ic_camera_flip"
        case disabledChatIcon = "disabledChatIcon"
        case mic = "micIcon"
        case unmuteMic = "unmuteMicIcon"
        
        case terminatedPageStreamer = "livestream_terminated_streaming"
        case terminatedPageWatcher = "livestream_terminated_watching"
        case terminatedContentViewer = "livestream_terminated_trash"
        case terminatedContentPlayback = "livestream_terminated_block"
        case menu = "livestreamMenuIcon"
        case hostIcon = "streamHostIcon"
        case leaveIcon = "leaveIcon"
    }
    
    enum Reaction: String, ImageResourceProvider {
        case like = "messageReactionLike"
        case love = "messageReactionHeart"
        case grinning = "messageReactionGrinning"
        case fire = "messageReactionFire"
        case sad = "messageReactionSad"
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
    
    var image: UIImage? {
        UIImage(named: self.rawValue, in: AmityUIKit4Manager.bundle, compatibleWith: nil)
    }
}
