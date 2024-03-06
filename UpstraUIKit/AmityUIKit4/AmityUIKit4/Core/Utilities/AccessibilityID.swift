//
//  AccessibilityID.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/23/24.
//

import Foundation

struct AccessibilityID {
    
    struct Story {
        struct AmityStoryTabComponent {
            static let storyRingView = "story_target_list/target_ring_view"
            static let avatarImageView = "story_target_list/target_avatar"
            static let createStoryButton = "story_target_list/target_create_story_icon"
            static let targetNameTextView = "story_target_list/target_display_name"
        }
        
        struct AmityCreateStoryPage {
            static let closeButton = "close_button"
            static let flashLightButton = "flash_light_button"
            static let mediaPickerButton = "media_picker_button"
            static let switchCameraButton = "switch_camera_button"
            static let cameraShutterButton = "camera_shutter_button"
            static let cameraPreviewView = "camera_view"
            static let switchPhotoButton = "switch_mode_photo_button"
            static let switchVideoButton = "switch_mode_video_button"
        }
        
        struct AmityDraftStoryPage {
            static let backButton = "back_button"
            static let aspectRatioButton = "aspect_ratio_button"
            static let hyperLinkButton = "story_hyperlink_button"
            static let shareStoryButton = "share_story_button"
            static let shareStoryButtonAvatar = "share_story_button_image_view"
            static let hyperlinkView = "hyper_link_view"
            static let hyperlinkTextView = "hyper_link_view_text_view"
            static let storyImageView = "image_view"
            static let storyVideoView = "video_view"
        }
        
        struct AmityHyperLinkConfigComponent {
            static let componentContaier = "hyper_link_config_component/*"
            static let titleTextView = "hyper_link_config_component/title_text_view"
            static let cancelButton = "hyper_link_config_component/cancel_button"
            static let doneButton = "hyper_link_config_component/done_button"
            static let hyperlinkURLTitleTextView = "hyper_link_url_title_text_view"
            static let hyperlinkURLTextField = "hyper_link_config_component/hyper_link_url_text_field"
            static let hyperlinkErrorTextView = "hyper_link_config_component/hyper_link_url_error_text_view"
            static let customizeLinkTitleTextView = "hyper_link_config_component/customize_link_text_title_text_view"
            static let customizeLinkTextField = "hyper_link_config_component/customize_link_text_text_field"
            static let customizeLinkErrorTextView = "hyper_link_config_component/customize_link_text_error_text_view"
            static let customizeLinkDescriptionTextView = "hyper_link_config_component/customize_link_text_description_text_field"
            static let customizeLinkCharacterLimitTextView = "hyper_link_config_component/customize_link_text_characters_limit_text_field"
            static let removeLinkButton = "hyper_link_config_component/remove_link_button"
            static let removeLinkButtonTextView = "hyper_link_config_component/remove_link_button_text_view"
        }
        
        struct AmityViewStoryPage {
            static let meatballsButton = "overflow_menu_button"
            static let closeButton = "close_button"
            static let muteButton = "video_audio_button"
            static let storyImageView = "image_view"
            static let storyVideoView = "video_view"
            static let hyperlinkView = "hyper_link_view"
            static let hyperlinkTextView = "hyper_link_view_text_view"
            static let reachButton = "reach_button"
            static let reachButtonTextView = "reach_button_text_view"
            static let commentButton = "comment_button"
            static let commentButtonTextView = "comment_button_text_view"
            static let reactionButton = "reaction_button"
            static let reactionButtonTextView = "reaction_button_text_view"
            static let communityAvatar = "community_avatar"
            static let createStoryIcon = "create_story_icon"
            static let communityDisplayNameTextView = "community_display_name"
            static let creatorDisplayNameTextView = "creator_display_name"
            static let createdAtTextView = "created_at"
            
            struct BottomSheet {
                static let deleteButton = "bottom_sheet_delete_button"
            }
            
        }
    }
    
    struct AmityCommentTrayComponent {
        static let titleTextView = "comment_tray_component/title_text_view"
        static let emptyTextView = "comment_tray_component/empty_text_view"
        
        struct CommentComposer {
            static let avatarImageView = "comment_tray_component/comment_composer_avatar"
            static let textField = "comment_tray_component/comment_composer_text_field"
            static let postButton = "comment_tray_component/comment_composer_post_button"
            static let disableTextView = "comment_tray_component/disabled_text_view"
        }
        
        struct CommentBubble {
            static let avatarImageView = "comment_list/comment_bubble_avatar"
            static let nameTextView = "comment_list/comment_bubble_creator_display_name"
            static let badgeImageView = "comment_list/comment_bubble_moderator_badge"
            static let commentTextView = "comment_list/comment_bubble_comment_text_view"
            static let timestampTextView = "comment_list/comment_bubble_timestamp"
            static let reactionButton = "comment_list/comment_bubble_reaction_button"
            static let replyButton = "comment_list/comment_bubble_reply_button"
            static let meatballsButton = "comment_list/comment_bubble_meat_balls_button"
            static let reactionCountTextView = "comment_list/comment_bubble_reaction_count_text_view"
            static let editTextField = "edit_comment_component/text_field"
            static let editCancelButton = "edit_comment_component/cancel_button"
            static let editSaveButton = "edit_comment_component/save_button"
            static let viewReplyButton = "comment_list/comment_bubble_view_reply_button"
            static let deletedComment = "comment_list/comment_bubble_deleted_view"
        }
        
        struct BottomSheet {
            static let editCommentButton = "comment_tray_component/bottom_sheet_edit_comment_button"
            static let deleteCommentButton = "comment_tray_component/bottom_sheet_delete_comment_button"
            static let reportCommentButton = "comment_tray_component/bottom_sheet_report_comment_button"
        }
    }
}
