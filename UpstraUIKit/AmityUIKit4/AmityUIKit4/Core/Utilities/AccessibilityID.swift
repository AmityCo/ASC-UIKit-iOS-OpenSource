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
    
    struct Chat {
        
        struct MessageList {
            static let container = "message_list/*"
            static let senderTextView = "message_list/message_bubble_sender_text_text_view"
            static let senderText = "message_list/message_bubble_sender_text"
            static let senderReplyText = "message_list/message_bubble_sender_text_reply_text"
            static let senderReplyTextView = "message_list/message_bubble_sender_text_reply_text_text_view"
            
            static let receiverTextView = "message_list/message_bubble_receiver_text_text_view"
            static let receiverText = "message_list/message_bubble_receiver_text"
            static let receiverReplyText = "message_list/message_bubble_receiver_text_reply_text"
            static let receiverReplyTextView = "message_list/message_bubble_receiver_text_reply_text_text_view"
            
            static let emptyStateContainer = "message_list/fail_to_load_message"
            static let emptyStateTitleText = "message_list/fail_to_load_message_title"
            static let emptyStateSubtitleText = "message_list/fail_to_load_message_subtitle"
            static let emptyStateIcon = "message_list/fail_to_load_message_icon"
            
            static let bubbleContainer = "message_list/message_bubble"
            static let bubbleTimestamp = "message_list/message_bubble_timestamp"
            static let bubbleSenderAvatar = "message_list/message_bubble_sender_avatar"
            static let bubbleReceiverAvatar = "message_list/message_bubble_receiver_avatar"
            static let bubbleSenderDisplayName = "message_list/message_bubble_sender_display_name"
            static let bubbleReceiverDisplayName = "message_list/message_bubble_receiver_display_name"
            static let bubbleSendingStatus = "message_list/message_bubble_sending_status"
            static let bubbleReaction = "message_list/message_bubble_reaction"
            
            static let reactionPicker = "message_list/message_reaction_picker"
            static let quickReaction = "message_list/message_quick_reaction"
            static let reactionPreview = "message_list/message_reaction_preview"
        }
        
        struct LiveChatHeader {
            static let container = "live_chat_header/*"
            static let avatar = "live_chat_header/avatar"
            static let headerTitle = "live_chat_header/title"
            static let memberCount = "live_chat_header/member_count"
            static let connectivity = "live_chat_header/conectivity"
        }
        
        struct MessageComposer {
            static let container = "message_composer/*"
            static let sendButton = "message_composer/send_button"
            static let textField = "message_composer/text_field"
        }
        
        struct MentionList {
            static let container = "mention_list/*"
            static let userAvatar = "mention_list/user_avatar"
            static let userDisplayName = "mention_list/user_display_name"
        }
        
        struct ReplyPanel {
            static let container = "reply_panel/*"
            static let userAvatar = "reply_panel/user_avatar"
            static let userDisplayName = "reply_panel/user_display_name"
            static let close_button = "reply_panel/close_button"
        }
        
        struct ReactionList {
            static let reactionListTab = "reaction_list_header/reaction_list_tab"
            static let userAvatarView = "reaction_list/user_avatar_view"
            static let userDisplayName = "reaction_list/user_display_name"
            static let reactionImageView = "reaction_list/reaction_image_view"
        }
    }
    
    struct Social {
        
        struct CategoryList {
            static let categoryImage = "community_row_image"
            static let communityName = "community_row_name"
        }
        
        struct SocialHomePage {
            static let headerLabel = "header_label"
            static let globalSearchButton = "global_search_button"
            static let postCreationButton = "post_creation_button"
            static let newsFeedButton = "newsfeed_button"
            static let exploreButton = "explore_button"
            static let myCommunitiesButton = "my_communities_button"
        }
        
        struct TopSearchBar {
            static let searchIcon = "search_icon"
            static let clearButton = "clear_button"
        }
        
        struct EmptyNewsFeed {
            static let illustration = "illustration"
            static let title = "title"
            static let description = "description"
            static let exploreCommunittiesButton = "explore_communitties_button"
            static let createCommunityButton = "create_community_button"
        }
        
        struct MyCommunities {
            static let communityAvatar = "community_avatar"
            static let communityDisplayName = "community_display_name"
            static let communityPrivateBadge = "community_private_badge"
            static let communityOfficialBadge = "community_official_badge"
            static let communityCategoryName = "community_category_name"
            static let communityMembersCount = "community_members_count"
        }
        
        struct PostContent {
            static let moderatorBadge = "moderator_badge"
            static let timestamp = "timestamp"
            static let postContent = "post_content_view_count"
            static let reactionButton = "reaction_button"
            static let commentButton = "comment_button"
            static let shareButton = "share_button"
            static let nonMemberSection = "non_member_section"
            static let announcementBadge = "announcement_badge"
            static let pinBadge = "pin_badge"
        }
        
        struct Explore {
            static let emptyStateImage = "explore_empty_image"
            static let emptyStateText = "explore_empty_text"
            static let emptyStateCreateCommunity = "explore_create_community"
            
            
            static let recommendedSection = "recommended_communities"
            static let categoriesSection = "community_categories"
            static let trendingSection = "trending_communities"
        
            static let communityJoinButton = "community_card_join_button"
            static let communityMemberCount = "community_card_member_count"
            static let communityCategories = "community_card_categories"
            static let communityImage = "community_card_image"
        }
        
        struct CreatePostMenu {
            static let createPostButton = "create_post_button"
            static let createStoryButton = "create_story_button"
            static let createPollButton = "create_poll_button"
            static let createLivestreamButton = "create_livestream_button"
        }
        
        struct PostTargetSelection {
            static let myTimelineAvatar = "my_timeline_avatar"
            static let myTimelineText = "my_timeline_text"
        }
        
        struct PostComposer {
            static let createNewPostButton = "create_new_post_button"
            static let editPostButton = "edit_post_button"
            static let editPostTitle = "edit_post_title"
        }
        
        struct MediaAttachment {
            static let cameraButton = "camera_button"
            static let imageButton = "image_button"
            static let videoButton = "video_button"
            static let fileButton = "file_button"
        }
        
        struct CommunityHeader {
            static let communityName = "community_name"
            static let communityCover = "community_cover"
            static let communityVerifyBadge = "community_verify_badge"
            static let communityCategory = "community_category"
            static let communityDescription = "community_description"
            static let communityInfo = "community_info"
            static let communityJoinButton = "community_join_button"
            static let communityPendingPost = "community_pending_post"
        }
        
        struct CommunityProfileTab {
            static let communityFeedTabButton = "community_feed_tab_button"
            static let communityPinTabButton = "community_pin_tab_button"
        }
        
        struct CommunitySetup {
            static let title = "title"
            static let communityEditTitle = "community_edit_title"
            static let communityNameTitle = "community_name_title"
            static let communityAboutTitle = "community_about_title"
            static let communityCategoryTitle = "community_category_title"
            static let communityPrivacyTitle = "community_privacy_title"
            static let communityPrivacyPrivateIcon = "community_privacy_private_icon"
            static let communityPrivacyPrivateTitle = "community_privacy_private_title"
            static let communityPrivacyPrivateDescription = "community_privacy_private_description"
            static let communityPrivacyPublicIcon = "community_privacy_public_icon"
            static let communityPrivacyPublicTitle = "community_privacy_public_title"
            static let communityPrivacyPublicDescription = "community_privacy_public_description"
            static let communityAddMemberTitle = "community_add_member_title"
            static let communityAddMemberButton = "community_add_member_button"
            static let communityCreateButton = "community_create_button"
            static let communityEditButton = "community_edit_button"
        }
        
        struct PendingPost {
            static let postAcceptButton = "post_accept_button"
            static let postDeclineButton = "post_decline_button"
        }
        
        struct CommunitySettings {
            static let editProfile = "edit_profile"
            static let members = "members"
            static let notifications = "notifications"
            static let postPermission = "post_permission"
            static let storySetting = "story_setting"
            static let leaveCommunity = "leave_community"
            static let closeCommunity = "close_community"
            static let closeCommunityDescription = "close_community_description"
        }
        
        struct UserProfile {
            static let userFeedTabButton = "user_feed_tab_button"
            static let userImageFeedTabButton = "user_image_feed_tab_button"
            static let userVideoFeedTabButton = "user_video_feed_tab_button"
        }
        
        struct UserProfileHeader {
            static let followUserButton = "follow_user_button"
            static let followingUserButton = "following_user_button"
            static let pendingUserButton = "pending_user_button"
            static let unblockUserButton = "unblock_user_button"
            static let userAvatar = "user_avatar"
            static let userName = "user_name"
            static let userDescription = "user_description"
            static let userFollowing = "user_following"
            static let userFollower = "user_follower"
        }
        
        struct EditUserProfile {
            static let userDisplayNameTitle = "user_display_name_title"
            static let userAboutTitle = "user_about_title"
            static let updateUserProfileButton = "update_user_profile_button"
        }
        
        struct UserFeed {
            static let emptyUserFeed = "empty_user_feed"
            static let privateUserFeed = "private_user_feed"
            static let privateUserFeedInfo = "private_user_feed_info"
            static let blockedUserFeed = "blocked_user_feed"
            static let blockedUserFeedInfo = "blocked_user_feed_info"
            static let emptyUserImageFeed = "empty_user_image_feed"
            static let privateUserImageFeed = "private_user_image_feed"
            static let privateUserImageFeedInfo = "private_user_image_feed_info"
            static let blockedUserImageFeed = "blocked_user_image_feed"
            static let blockedUserImageFeedInfo = "blocked_user_image_feed_info"
            static let emptyUserVideoFeed = "empty_user_video_feed"
            static let privateUserVideoFeed = "private_user_video_feed"
            static let privateUserVideoFeedInfo = "private_user_video_feed_info"
            static let blockedUserVideoFeed = "blocked_user_video_feed"
            static let blockedUserVideoFeedInfo = "blocked_user_video_feed_info"
        }
    }
}


