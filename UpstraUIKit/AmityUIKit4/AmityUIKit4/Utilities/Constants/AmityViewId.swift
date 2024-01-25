//
//  AmityViewId.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

public enum PageId: String {
    case storyCreationPage = "create_story_page"
    case storyPage = "story_page"
    case cameraPage = "camera_page"
}

public enum ComponentId: String {
    case mock = "mock"
    case storyTabComponent = "story_tab_component"
}

public enum ElementId: String {
    // Story Tab Component
    case storyRingElement = "story_ring"
    case createNewStoryButtonElement = "create_new_story_button"
    
    // View Story Page
    case progressBarElement = "progress_bar"
    case closeButtonElement = "close_button"
    case overflowMenuElement = "overflow_menu"
    case impressionIconElement = "story_impression_button"
    case storyCommentButtonElement = "story_comment_button"
    case storyReactionButtonElement = "story_reaction_button"
    case muteUnmuteButtonElement = "speaker_button"
    
    // Draft Story Page
    case backButtonElement = "back_button"
    case aspectRatioButtonElement = "aspect_ratio_button"
    case shareStoryButtonElement = "share_story_button"
}
