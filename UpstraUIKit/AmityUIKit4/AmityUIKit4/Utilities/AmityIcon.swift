//
//  AmityIcon.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import UIKit

enum AmityIcon: String {
    case verifiedBadge = "verifiedBadge"
    case createStoryIcon = "createStoryIcon"
    case errorStoryIcon = "errorStoryIcon"
    case closeIcon = "closeIcon"
    case threeDotIcon = "threeDotIcon"
    case statusSuccessIcon = "statusSuccessIcon"
    case statusWarningIcon = "statusWarningIcon"
    
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
    case backIcon = "backIcon"
    case nextIcon = "nextIcon"
    case aspectRatioIcon = "aspectRatioIcon"
    
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
