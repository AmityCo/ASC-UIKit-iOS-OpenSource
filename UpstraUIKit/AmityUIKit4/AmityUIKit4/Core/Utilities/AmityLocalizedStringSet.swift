//
//  AmityLocalizedStringSet.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import Foundation

public struct AmityLocalizedStringSet {
    private init() { }
    
    public struct General {
        static let delete = "delete"
        static let cancel = "cancel"
        static let save = "save"
        static let retry = "retry"
        static let discard = "discard"
        static let leave = "leave"
        static let confirm = "confirm"
        static let okay = "okay"
        static let anonymous = "general_anonymous"
        static let permissionRequired = "permission_required"
        static let cameraAccessDenied = "camera_access_denied"
        static let on = "on"
        static let off = "off"
    }
    
    public struct Story {
        static let creatingStory = "creating_story"
        static let createdStorySuccessfully = "created_story_successfully"
        static let createdStoryFailed = "crated_story_failed"
        static let deleteStoryTitle = "delete_story_title"
        static let deleteStoryMessage = "delete_story_message"
        static let storyDeletedToastMessage = "story_deleted_toast_message"
        static let failedStoryBannerMessage = "failed_story_banner_message"
        static let failedStoryAlertTitle = "failed_story_alert_title"
        static let failedStoryAlertMessage = "failed_story_alert_message"
        static let nonMemberReactStoryMessage = "non_member_react_story_message"
    }
    
    public struct Comment {
        static let commentTrayComponentTitle = "comment_tray_component_title"
        static let commentTextFieldPlacholder = "comment_text_field_placeholder"
        static let noCommentAvailable = "no_comment_available"
        static let deleteCommentTitle = "delete_comment_title"
        static let deleteCommentMessage = "delete_comment_message"
        static let deletedCommentMessage = "deleted_comment_message"
        static let deletedReplyCommentMessage = "deleted_reply_comment_message"
        static let editCommentBottomSheetTitle = "edit_comment_bottom_sheet_title"
        static let deleteCommentBottomSheetTitle = "delete_comment_bottom_sheet_title"
        static let reportCommentBottomSheetTitle = "report_comment_bottom_sheet_title"
        static let unReportCommentBottomSheetTitle = "unreport_comment_bottom_sheet_title"
        static let commentReportedMessage = "comment_reported_message"
        static let commentUnReportedMessage = "comment_unreported_message"
        static let reactButtonText = "comment_react_button_text"
        static let reactedButtonText = "comment_reacted_button_text"
        static let replyButtonText = "comment_reply_button_text"
        static let editedText = "comment_edited_text"
        static let viewMoreReplyText = "view_more_reply_text"
        static let disableCreateCommentText = "disable_create_comment_text"
        static let commentWithBannedWordsErrorMessage = "comment_with_banned_words_error_message"
    }
    
    public struct Chat {
        
        // Toast
        static let toastLoading = "chat_toast_loading"
        static let toastDeleteErrorMessage = "chat_toast_delete_error"
        static let toastCopied = "chat_toast_copied"
        static let toastLinkNotAllow = "chat_toast_link_not_allow"
        static let toastBannedWord = "chat_toast_banned_word"
        static let toastReportMessage = "chat_toast_report_message"
        static let toastReportMessageError = "chat_toast_report_message_error"
        static let toastUnReportMessage = "chat_toast_un_report_message"
        static let toastUnReportMessageError = "chat_toast_un_report_message_error"
        // Button
        static let deletedMessage = "chat_deleted_message_text"
        
        static let replyButton = "chat_button_reply"
        static let copyButton = "chat_button_copy"
        static let deleteButton = "chat_button_delete"
        static let reportButton = "chat_button_report"
        static let unReportButton = "chat_button_un_report"
        static let okButton = "chat_button_ok"
        
        // Error
        static let errorLoadingChat = "chat_error_loading_chat_title"
        static let errorBannedTitleChat = "chat_error_banned_chat_title"
        static let errorBannedSubTitleInChat = "chat_error_banned_chat_sub_title"
        
        static let charLimitAlertTitle = "chat_char_limit_alert_title"
        static let charLimitAlertMessage = "chat_char_limit_alert_message"
        static let deleteAlertTitle = "chat_delete_alert_title"
        static let deleteAlertMessage = "chat_delete_alert_message"
       
        static let deleteActionSheetTitle = "chat_delete_action_sheet_title"
        
        static let userIsMuted = "chat_user_is_muted"
        static let channelIsMuted = "chat_channel_is_muted"
        
        static let statusSending = "chat_sending_status"
        static let connectivityStatusWaiting = "network_connectivity_status"
        
        static let mentionEveryone = "chat_mention_everyone"
        static let replyMessagePreview = "chat_reply_preview"
        static let memberCount = "chat_member_count"
        
        static let reachMentionLimitTitle = "reach_mention_limit_title"
        static let reachMentionLimitMessage = "chat_reach_mention_limit_Message"
    }
    
    public struct Reaction {
        static let unableToLoadTitle = "reaction_list_unable_to_load_title"
        static let unableToLoadSubtitle = "reaction_list_unrable_to_load_subtitle"
        static let noReactionTitle = "reaction_list_no_reactions_title"
        static let noReactionSubtitle = "reaction_list_no_reactions_subtitle"
        static let tapToRemove = "reaction_list_tap_to_remove"
        static let allTab = "All"
    }
    
    public enum Social {
        static let emptyNewsFeedTitle = "empty_newsfeed_title"
        static let emptyNewsFeedDescription = "empty_newsfeed_description"
        static let editPostBottomSheetTitle = "edit_post_bottom_sheet_title"
        static let deletePostBottomSheetTitle = "delete_post_bottom_sheet_title"
        static let reportPostBottomSheetTitle = "report_post_bottom_sheet_title"
        static let unreportPostBottomSheetTitle = "unreport_post_bottom_sheet_title"
        static let deletePostTitle = "delete_post_title"
        static let deletePostMessage = "delete_post_message"
        static let postReportedMessage = "post_reported_message"
        static let postUnReportedMessage = "post_unreported_message"
        static let postDeletedToastMessage = "post_deleted_toast_message"
        static let postDetailPageTitle = "post_detail_page_title"
        static let sponsored = "ads_sponsored_label"
        static let createPostBottomSheetTitle = "create_post_bottom_sheet_title"
        static let createStoryBottomSheetTitle = "create_story_bottom_sheet_title"
        static let communityPageJoinTitle = "community_page_join_title"
        static let communityPagePendingPostTitle = "community_page_pending_post_title"
        static let nonMemberReactPostMessage = "non_member_react_post_message"
        static let communitySetupAlertTitle = "community_setup_alert_title"
        static let communitySetupAlertMessage = "community_setup_alert_message"
        static let communitySetupEditAlertTitle = "community_setup_edit_alert_title"
        static let communitySetupEditAlertMessage = "community_setup_edit_alert_message"
        
        static let communitySettingBasicInfoTitle = "community_setting_basic_info_title"
        static let communitySettingCommunityPermissionsTitle = "community_setting_community_permissions_title" 
        static let communitySettingEditProfile = "community_setting_edit_profile";
        static let communitySettingMembers = "community_setting_members";
        static let communitySettingNotifications = "community_setting_notifications";
        static let communitySettingPostPermissions = "community_setting_post_permissions";
        static let communitySettingStoryComments = "community_setting_story_comments";
        static let communitySettingLeaveCommunity = "community_setting_leave_community";
        static let communitySettingCloseCommunity = "community_setting_close_community";
        static let communitySettingCloseCommunityDescription = "community_setting_close_community_description";
        
        static let communitySettingLeaveCommunityAlertTitle = "community_setting_leave_community_alert_title"
        static let communitySettingLeaveCommunityAlertMessage = "community_setting_leave_community_alert_message"
        static let communitySettingLeaveCommunityFailedAlertTitle = "community_setting_leave_community_failed_alert_title"
        static let communitySettingLeaveCommunityFailedAlertMessage = "community_setting_leave_community_failed_alert_message"
        static let communitySettingCloseCommunityAlertTitle = "community_setting_close_community_alert_title"
        static let communitySettingCloseCommunityAlertMessage = "community_setting_close_community_alert_message"
        
        static let communityPostPermissionTitle = "community_post_permission_title"
        static let communityPostPermissionDescription = "community_post_permission_description"
        static let communityPostPermissionEveryoneCanPostSetting = "community_post_permission_everyone_can_post_setting"
        static let communityPostPermissionAdminReviewSetting = "community_post_permission_admin_review_setting"
        static let communityPostPermissionOnlyAdminCanPostSetting = "community_post_permission_only_admin_can_post_setting"
        static let communityStorySettingTitle = "community_story_setting_title"
        static let communityStorySettingDescription = "community_story_setting_description"
        
        static let communityNotificationSettingPageTitle = "community_notification_setting_page_title"
        static let communityNotificationSettingTitle = "community_notification_setting_title"
        static let communityNotificationSettingDescription = "community_notification_setting_description"
        static let communityNotificationSettingPosts = "community_notification_setting_posts"
        static let communityNotificationSettingComments = "community_notification_setting_comments"
        static let communityNotificationSettingStories = "community_notification_setting_stories"
        
        static let communityNotificationSettingOptionEveryone = "community_notification_setting_option_everyone"
        static let communityNotificationSettingOptionOnlyModerator = "community_notification_setting_option_only_moderator"
        static let communityNotificationSettingOptionOff = "community_notification_setting_option_off"
        
        static let communityNotificationSettingPostReactionTitle = "community_notification_setting_post_reaction_title"
        static let communityNotificationSettingPostReactionDescription = "community_notification_setting_post_reaction_description"
        static let communityNotificationSettingPostCreationTitle = "community_notification_setting_post_creation_title"
        static let communityNotificationSettingPostCreationDescription = "community_notification_setting_post_creation_description"
        static let communityNotificationSettingCommentReactionTitle = "community_notification_setting_comment_reaction_title"
        static let communityNotificationSettingCommentReactionDescription = "community_notification_setting_comment_reaction_description"
        static let communityNotificationSettingCommentCreationTitle = "community_notification_setting_comment_creation_title"
        static let communityNotificationSettingCommentCreationDescription = "community_notification_setting_comment_creation_description"
        static let communityNotificationSettingCommentReplyTitle = "community_notification_setting_comment_reply_title"
        static let communityNotificationSettingCommentReplyDescription = "community_notification_setting_comment_reply_description"
        static let communityNotificationSettingStoryCreationTitle = "community_notification_setting_story_creation_title"
        static let communityNotificationSettingStoryCreationDescription = "community_notification_setting_story_creation_description"
        static let communityNotificationSettingStoryReactionTitle = "community_notification_setting_story_reaction_title"
        static let communityNotificationSettingStoryReactionDescription = "community_notification_setting_story_reaction_Description"
        static let communityNotificationSettingStoryCommentTitle = "community_notification_setting_story_comment_title"
        static let communityNotificationSettingStoryCommentDescription = "community_notification_setting_story_comment_description"
    }
    
}
