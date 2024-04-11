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
    case targetSelectionPage = "select_target_page"
    case liveChatPage = "live_chat"
}

public enum ComponentId: String {
    case storyTabComponent = "story_tab_component"
    case hyperLinkConfigComponent = "hyper_link_config_component"
    case messageComposer = "message_composer"
    case messageList = "message_list"
    case liveChatHeader = "live_chat_header"
    case commentTrayComponent = "comment_tray_component"
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
    case hyperLinkButtonElement = "story_hyperlink_button"
    case hyperLinkElement = "hyper_link"
    
    // Hyper Link Component
    case doneButtonElement = "done_button"
    case cancelButtonElement = "cancel_button"
    
    case sendButton = "send_button"
    case textField = "text_field"
    case theme = "theme"
    
    case senderMessageBubble = "sender_message_bubble"
    case receiverMessageBubble = "receiver_message_bubble"
    
    // Chat Elements
    case memberCount = "member_count"
    case connectivity = "conectivity"
    case avatar = "avatar"
}
