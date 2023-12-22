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
    case closeIcon = "closeIcon"
    case threeDotIcon = "threeDotIcon"
    
    // AmityCameraPage Icons
    case backgroundedCloseIcon = "backgroundedCloseIcon"
    case galleryIcon = "galleryIcon"
    case flipCameraIcon = "flipCameraIcon"
    case flashOffIcon = "flashOffIcon"
    case flashOnIcon = "flashOnIcon"
    case cameraShutterIcon = "cameraShutterIcon"
    case videoShutterIcon = "videoShutterIcon"
    case videoShutterRecordingIcon = "videoShutterRecordingIcon"
    
    // AmityStoryCreationPage Icons
    case backIcon = "backIcon"
    case nextIcon = "nextIcon"
    
    case verifiedWhiteBadge = "verifiedWhiteBadge"
    case eyeIcon = "eyeIcon"
    case storyLikeIcon = "storyLikeIcon"
    case storyCommentIcon = "storyCommentIcon"
    case avatarPlaceholder = "avatarPlaceholder"
    case defaultCommunity = "defaultCommunity"
    
    case demoImage1 = "demoImage1"
    case demoImage2 = "demoImage2"
    case demoImage3 = "demoImage3"
    case demoImage4 = "demoImage4"
    
    case demoCat1 = "demoCat1"
    case demoCat2 = "demoCat2"
    case demoCat3 = "demoCat3"
    
    case demoColor1 = "demoColor1"
    case demoColor2 = "demoColor2"
    
    
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
