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
        static let edit = "edit"
        static let noInternetConnection = "no_internet_connection"
        static let done = "done"
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
        static let commentWithNotAllowedLink = "comment_with_not_allowed_link_error"
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
    
    public struct LiveChat {
        static let deleteMessage = "live_chat_delete_message"
        static let reportMessage = "live_chat_report_message"
        static let unreportMessage = "live_chat_unreport_message"
        static let toastReportMessage = "live_chat_toast_report_message"
        static let toastUnReportMessage = "live_chat_toast_unreport_message"
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
        static let postFailedReportedMessage = "post_failed_reported_message"
        static let postFailedUnReportedMessage = "post_failed_unreported_message"
        static let postDeletedToastMessage = "post_deleted_toast_message"
        static let postDetailPageTitle = "post_detail_page_title"
        static let sponsored = "ads_sponsored_label"
        static let createPostBottomSheetTitle = "create_post_bottom_sheet_title"
        static let createStoryBottomSheetTitle = "create_story_bottom_sheet_title"
        static let communityPageJoinTitle = "community_page_join_title"
        static let communityPageJoinedTitle = "community_page_joined_title"
        static let communityPagePendingPostTitle = "community_page_pending_post_title"
        static let nonMemberReactPostMessage = "non_member_react_post_message"
        static let communitySetupAlertTitle = "community_setup_alert_title"
        static let communitySetupAlertMessage = "community_setup_alert_message"
        static let communitySetupEditAlertTitle = "community_setup_edit_alert_title"
        static let communitySetupEditAlertMessage = "community_setup_edit_alert_message"
        static let livestreamPlayerEndedTitle = "livestream_player_ended_title"
        static let livestreamPlayerEndedMessage = "livestream_player_ended_message"
        static let livestreamPlayerTerminatedTitle = "livestream_player_terminated_title"
        static let livestreamPlayerTerminatedMessage = "livestream_player_terminated_message"
        static let livestreamPlayerBannedTitle = "livestream_player_banned_title"
        static let livestreamPlayerBannedMessage = "livestream_player_banned_message"
        static let livestreamPlayerUnavailableTitle = "livestream_player_unavailable_title"
        static let livestreamPlayerUnavailableMessage = "livestream_player_unavailable_message"
        static let livestreamPlayerReconnectingTitle = "livestream_player_reconnecting_title"
        static let livestreamPlayerReconnectingMessage = "livestream_player_reconnecting_message"
        static let livestreamPlayerLive = "livestream_player_live"
        static let livestreamPlayerRecorded = "livestream_player_recorded"
        static let livestreamPlayerUpcomingLive = "livestream_player_upcoming_live"
        static let liveStreamSettingReadOnlyTitle = "live_stream_setting_readonly_title"
        static let liveStreamSettingReadOnlyDescription = "live_stream_setting_readonly_description"
        
        static let communitySettingBasicInfoTitle = "community_setting_basic_info_title"
        static let communitySettingCommunityPermissionsTitle = "community_setting_community_permissions_title"
        static let communitySettingNotificationsTitle = "community_setting_notifications_title"
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
        
        static let communityMemberCountSingular = "community_member_count_singular"
        static let communityMemberCountPlural = "community_member_count_plural"
        
        static let exploreCategoriesSeeMore = "explore_categories_see_more"
        static let exploreTrendingComponentTitle = "explore_trending_now_component_title"
        static let exploreRecommendedComponentTitle = "explore_recommended_communities_component_title"
        
        static let searchNoResultsFound = "search_no_results_found_title"
        static let searchCharLimitNotReached = "search_char_limit_not_reached"
        
        static let communityAllCategoriesPageTitle = "community_all_categories_title"
        static let communityEmptyStateTitle = "community_list_empty_state_title"
        
        static let featuredPostBadge = "featured_post_badge"
        static let featuredPostEditConfirmation = "featured_post_edit_confirmation"
        static let featuredPostEditConfirmationTitle = "featured_post_edit_confirmation_title"
        
        static let globalFeaturedCommunityEditConfirmationTitle = "global_featured_community_edit_confirmation_title"
        
        static let globalFeaturedCommunityEditConfirmationMessage = "global_featured_community_edit_confirmation_msg"
        
        static let userProfileEditAlertTitle = "user_profile_edit_alert_title"
        static let userProfileEditAlertMessage = "user_profile_edit_alert_message"
        static let userProfileFollowRequestTitle = "user_profile_follow_request_title"
        
        // Poll
        static let pollCloseAlertTitle = "poll_close_alert_title"
        static let pollCloseAlertDesc = "poll_close_alert_desc"
        static let pollCloseButton = "poll_close_button"
        static let pollCloseToastError = "poll_close_toast_error"

        static let pollStatusEnded = "poll_status_ended"

        static let pollRemainingDaysLeft = "poll_remaining_days_left"
        static let pollRemainingHoursLeft = "poll_remaining_hours_left"
        static let pollRemainingMinutesLeft = "poll_remaining_minutes_left"

        static let pollQuestionTitle = "poll_question_title"
        static let pollQuestionTextfieldPlaceholder = "poll_question_textfield_placeholder"
        static let pollMultipleSelectionTitle = "poll_multiple_selection_title"
        static let pollMultipleSelectionDesc = "poll_multiple_selection_desc"

        static let pollPostCreateError = "poll_post_create_error"
        static let pollCreatePostingToast = "poll_create_posting_toast"

        static let pollDurationTitle = "poll_duration_title"
        static let pollDurationDesc = "poll_duration_desc"
        static let pollEndsOnLabel = "poll_ends_on_label"

        static let pollOptionsTitle = "poll_options_title"
        static let pollOptionsDesc = "poll_options_desc"
        static let pollAddOption = "poll_add_option"

        static let pollOptionLabel = "poll_option_label"

        static let pollAnswerResultNoVotes = "poll_answer_result_no_votes"
        static let pollAnswerResultVotedByYou = "poll_answer_result_voted_by_you"
        static let pollAnswerResultVotedBySingleParticipant = "poll_answer_result_voted_by_single_participant"
        static let pollAnswerResultVotedByMultipleParticipants = "poll_answer_result_voted_by_multiple_participants"
        
        static let pollAnswerResultVotedByAndYou = "poll_answer_result_voted_by_and_you"

        static let pollDurationPickDateAndTime = "poll_duration_pick_date_and_time"
        static let pollDurationDoneButton = "poll_duration_done_button"

        static let pollDurationSingularDay = "poll_duration_singular_day"
        static let pollDurationPluralDays = "poll_duration_plural_days"

        static let pollSelectOneOptionLabel = "poll_select_one_option_label"
        static let pollSelectOneOrMoreOptionLabel = "poll_select_one_or_more_option_label"

        static let pollSeeFullResultsLabel = "poll_see_full_results_label"
        static let pollSeeResultsLabel = "poll_see_results_label"
        static let pollBackToVoteLabel = "poll_back_to_vote_label"
        static let pollSeeMoreOptionsLabel = "poll_see_more_options_label"

        static let pollVoteCounts = "poll_vote_counts"
        static let pollVoteButton = "poll_vote_button"
        
        static let pollLabel = "poll_label"
        
        static let pollOptionCharLimitError = "poll_option_char_limit_error"
        static let pollQuestionCharLimitError = "poll_question_char_limit_error"
        
        static let pollTargetMyTimeline = "poll_target_my_timeline"
        
        static let postDeleteError = "post_delete_error"
        static let postCreateError = "post_create_error"
        static let postEditError = "post_edit_error"
        
        static let postDiscardAlertTitle = "post_discard_alert_title"
        static let postDiscardAlertMessage = "post_discard_alert_message"
        static let postDiscardAlertButtonKeepEditing = "post_discard_alert_button_keep_editing"
        
        // Live Stream Creation
        static let liveStreamTargetLiveOnLabel = "live_stream_target_live_on_label"
        static let liveStreamDurationLabel = "live_stream_duration_label"
        static let liveStreamMyTimelineLabel = "live_stream_my_timeline_label"
        static let liveStreamEndLiveLabel = "live_stream_end_live_label"

        static let liveStreamAlertEndLiveTitle = "live_stream_alert_end_live_title"
        static let liveStreamAlertEndLiveDesc = "live_stream_alert_end_live_desc"
        static let liveStreamAlertEndButton = "live_stream_alert_end_button"

        static let liveStreamChangeThumbnailLabel = "live_stream_change_thumbnail_label"
        static let liveStreamDeleteThumbnailLabel = "live_stream_delete_thumbnail_label"
        static let liveStreamAddThumbnailLabel = "live_stream_add_thumbnail_label"

        static let liveStreamInputAddStreamTitle = "live_stream_input_add_stream_title"
        static let liveStreamInputAddStreamDesc = "live_stream_input_add_stream_desc"

        static let liveStreamAlertEndAtMaxDurationTitle = "live_stream_alert_end_at_max_duration_title"
        static let liveStreamAlertEndAtMaxDurationMessage = "live_stream_alert_end_at_max_duration_message"

        static let liveStreamAlertDiscardStreamTitle = "live_stream_alert_discard_stream_title"
        static let liveStreamAlertDiscardStreamMessage = "live_stream_alert_discard_stream_message"

        static let liveStreamAlertStreamErrorTitle = "live_stream_alert_stream_error_title"
        static let liveStreamAlertStreamErrorMessage = "live_stream_alert_stream_error_message"

        static let liveStreamAlertThumbnailUploadErrorTitle = "live_stream_alert_thumbnail_upload_error_title"
        static let liveStreamAlertThumbnailUploadErrorMessage = "live_stream_alert_thumbnail_upload_error_message"

        static let liveStreamAlertThumbnailUploadInappropriateErrorTitle = "live_stream_alert_thumbnail_upload_inappropriate_error_title"
        static let liveStreamAlertThumbnailUploadInappropriateErrorMessage = "live_stream_alert_thumbnail_upload_inappropriate_error_message"

        static let liveStreamToastEndAtMaxDurationMessage = "live_stream_toast_end_at_max_duration_message"

        static let liveStreamPermissionOpenSettingsLabel = "live_stream_permission_open_settings_label"
        static let liveStreamPermissionCameraAndMicrophoneTitle = "live_stream_permission_camera_and_microphone_title"
        static let liveStreamPermissionCameraAndMicrophoneMessage = "live_stream_permission_camera_and_microphone_message"

        static let liveStreamStartingStateTitle = "live_stream_starting_state_title"
        static let liveStreamReconnectingStateTitle = "live_stream_reconnecting_state_title"
        static let liveStreamReconnectingStateMessage = "live_stream_reconnecting_state_message"
        static let liveStreamEndingStateTitle = "live_stream_ending_state_title"
        
        static let postDetailDeletedPostTitle = "post_detail_deleted_post_title"
        static let postDetailDeletedPostMessage = "post_detail_deleted_post_message"
        static let postDetailDeletedPostButtonTitle = "post_detail_deleted_post_button_title"
        
        static let liveStreamTerminatedPageTitle = "live_stream_terminated_page_title"
        static let liveStreamTerminatedPageDescSectionTitle = "live_stream_terminated_page_desc_section_title"

        static let liveStreamTerminatedWatcherTitle = "live_stream_terminated_watcher_title"
        static let liveStreamTerminatedStreamerTitle = "live_stream_terminated_streamer_title"

        static let liveStreamTerminatedWatcherDesc = "live_stream_terminated_watcher_desc"
        static let liveStreamTerminatedStreamerDesc = "live_stream_terminated_streamer_desc"

        static let liveStreamTerminatedPlaybackDesc = "live_stream_terminated_playback_desc"
        static let liveStreamTerminatedStreamerContentDesc = "live_stream_terminated_streamer_content_desc"
        
        static let liveStreamLabel = "live_stream_label"
        
        static let altTextButtonTitle = "alt_text_button_title"
        static let altTextTitle = "alt_text_title"
        static let altTextEditTitle = "alt_text_edit_title"
        static let altTextPlaceholder = "alt_text_placeholder"
        static let altTextFailedToAdd = "alt_text_failed_to_add"
        static let altTextFailedToEdit = "alt_text_failed_to_edit"
        static let altTextIncludesBannedWords = "alt_text_includes_banned_words"
        static let altTextIncludesNotAllowedLink = "alt_text_includes_not_allowed_link"
        static let altTextUpdated = "alt_text_updated"
        
        static let notificationTrayEmptyStateTitle = "notification_tray_empty_state_title"
        static let notificationTrayTitle = "notification_tray_title"
        
        static let reportPageSubmitButton = "report_page_submit_button"
        static let reportPageInfoLabel = "report_page_info_label"
        static let reportReasonPageTitle = "report_reason_page_title"
        static let reportReasonOthersPageTitle = "report_reason_others_page_title"

        static let reportReasonSuccessToastMessage = "report_reason_success_toast_message"

        static let reportReasonOthersInputTitle = "report_reason_others_input_title"
        static let reportReasonOthersInputPlaceholder = "report_reason_others_input_placeholder"
        static let reportReasonCloseButton = "report_reason_close_button"
        static let reportReasonDoneButton = "report_reason_done_button"

        static let reportReasonErrorToastMessage = "report_reason_error_toast_message"
        
        static let communityUpdateSuccessToastMessage = "community_update_success_toast_message"
        
        static let pendingJoinRequestAlertTitle = "pending_join_request_alert_title"
        static let pendingJoinRequestAlertMessage = "pending_join_request_alert_message"
        
        static let communityLeaveAlertTitle = "community_leave_alert_title"
        static let communityLeaveAlertPendingRequestMessage = "community_leave_alert_pending_request_message"
        
        static let communityJoinToastSuccessMessage = "community_join_toast_success_message"
        static let communityJoinToastRequestSuccessMessage = "community_join_toast_request_success_message"
        static let communityJoinToastErrorMessage = "community_join_toast_error_message"
        
        static let userJoinAcceptedToastSuccessMessage = "user_join_accepted_toast_success_message"
        static let userJoinAcceptedToastErrorMessage = "user_join_accepted_toast_error_message"
        static let userJoinDeclinedToastSuccessMessage = "user_join_declined_toast_success_message"
        static let userJoinDeclinedToastErrorMessage = "user_join_decliend_toast_error_message"
        
        static let userJoinRequestAcceptLabel = "user_join_request_accept_label"
        static let userJoinRequestDeclineLabel = "user_join_request_decline_label"
        
        static let userJoinRequestDeclineAlertBannerMessage = "user_join_request_decline_alert_banner_message"
        
        static let communityPendingRequestTabPostsTitle = "community_pending_request_tab_posts_title"
        static let communityPendingRequestTabJoinRequestsTitle = "community_pending_request_tab_join_requests_title"
        static let communityPendingRequestPageTitle = "community_pending_request_page_title"
        
        static let communityJoinRequestEmptyStateTitle = "community_join_request_empty_state_title"
        static let communityPendingPostsEmptyStateTitle = "community_pending_posts_empty_state_title"
    }
}
