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
        static let delete = "amity_common_button_delete"
        static let cancel = "amity_common_button_cancel"
        static let save = "save"
        static let retry = "retry"
        static let discard = "discard"
        static let leave = "leave"
         static let confirm = "confirm"
         static let anonymous = "general_anonymous"
        static let permissionRequired = "permission_required"
        static let cameraAccessDenied = "camera_access_denied"
        static let on = "on"
        static let off = "off"
        static let edit = "edit"
        static let done = "done"
        static let camera = "general_camera"
        static let errorMessage = "general_error_message"
        static let errorTitle = "general_error_title"
        static let notificationsLowercase = "general_notifications_lowercase"
        // Ad Info
        static let adAboutTitle = "amity_common_ad_about_title"
        static let adWhyTitle = "amity_common_ad_why_title"
        static let adWhyDescription = "amity_common_ad_why_description"
        static let adAboutAdvertiser = "amity_common_ad_about_advertiser"
        static let adAdvertiserName = "amity_common_ad_advertiser_name"
        static let optionalLabel = "amity_social_label_optional"
        static let requiredIndicator = "amity_common_required_indicator"
        static let unknown = "amity_common_unknown"
        static let unknownError = "amity_common_unknown_error"
        static let next = "amity_common_next"
        static let justNow = "amity_common_just_now"
        static let timeDaysSuffix = "amity_common_time_days_suffix"
        static let timeHoursSuffix = "amity_common_time_hours_suffix"
        static let timeMinutesSuffix = "amity_common_time_minutes_suffix"
        static let timeSecondsSuffix = "amity_common_time_seconds_suffix"
        static let timeAm = "amity_common_time_am"
        static let timePm = "amity_common_time_pm"
        static let yes = "amity_common_yes"
        static let no = "amity_common_no"
        static let remove = "amity_common_remove"
        static let join = "amity_common_join"
        static let unblock = "amity_common_unblock"
        static let post = "amity_common_post"
        static let view = "amity_common_view"
        static let moderator = "amity_common_moderator"
        static let live = "amity_social_status_live"
        static let pending = "amity_common_pending"
        static let clips = "amity_social_button_social_home_clips_button"
        static let nothingHereYet = "amity_common_nothing_here_yet"
        static let byAuthor = "amity_common_by_author"
    }
    
    public struct Story {
        static let creatingStory = "creating_story"
        static let createdStorySuccessfully = "created_story_successfully"
        static let createdStoryFailed = "crated_story_failed"
        static let deleteStoryTitle = "delete_story_title"
        static let deleteStoryMessage = "delete_story_message"
        static let storyDeleteButton = "amity_story_delete_button"
        static let storyDeletedToastMessage = "story_deleted_toast_message"
        static let failedToDeleteStoryToastMessage = "amity_social_failed_to_delete_story_please_try_again"
        static let failedStoryBannerMessage = "failed_story_banner_message"
        static let failedStoryAlertTitle = "failed_story_alert_title"
        static let failedStoryAlertMessage = "failed_story_alert_message"
        static let replyingTo = "amity_social_replying_to"
        static let shareStory = "amity_social_share_story"
        static let unsavedChangesMessage = "amity_social_unsaved_changes_message"
        static let removeLinkButton = "amity_social_remove_link_button"
        static let removeLinkTitle = "amity_social_remove_link_title"
        static let removeLinkMessage = "amity_social_remove_link_message"
        static let discardStoryTitle = "amity_social_discard_story_title"
        static let discardStoryMessage = "amity_social_discard_story_message"
        static let cameraPhotoButton = "amity_story_camera_photo_button"
        static let cameraVideoButton = "amity_story_camera_video_button"
    }
    
    public struct Comment {
        static let commentTrayComponentTitle = "comment_tray_component_title"
        static let commentTextFieldPlacholder = "comment_text_field_placeholder"
        static let noCommentAvailable = "no_comment_available"
        static let deleteCommentTitle = "delete_comment_title"
        static let deleteCommentMessage = "social_label_delete_comment_message"
        static let deletedCommentMessage = "deleted_comment_message"
        static let deletedReplyCommentMessage = "deleted_reply_comment_message"
        static let editCommentBottomSheetTitle = "edit_comment_bottom_sheet_title"
        static let deleteCommentBottomSheetTitle = "delete_comment_bottom_sheet_title"
        static let reportCommentBottomSheetTitle = "report_comment_bottom_sheet_title"
        static let unReportCommentBottomSheetTitle = "unreport_comment_bottom_sheet_title"
        static let commentReportedMessage = "comment_reported_message"
        static let commentUnReportedMessage = "comment_unreported_message"
        
        static let reportReplyBottomSheetTitle = "report_reply_bottom_sheet_title"
        static let unReportReplyBottomSheetTitle = "unreport_reply_bottom_sheet_title"
        static let replyReportedMessage = "reply_reported_message"
        static let replyUnReportedMessage = "reply_unreported_message"
        
        static let reactButtonText = "comment_react_button_text"
        static let reactedButtonText = "comment_reacted_button_text"
        static let replyButtonText = "comment_reply_button_text"
        static let editedText = "comment_edited_text"
        static let viewMoreReplyText = "view_more_reply_text"
        static let replyUnavailableToastMessage = "reply_unavailable_toast_message"
        static let disableCreateCommentText = "disable_create_comment_text"
        static let commentWithBannedWordsErrorMessage = "comment_with_banned_words_error_message"
        static let commentWithNotAllowedLink = "comment_with_not_allowed_link_error"
        static let editReplyBottomSheetTitle = "edit_reply_bottom_sheet_title"
        static let deleteReplyBottomSheetTitle = "delete_reply_bottom_sheet_title"
        static let deleteReplyTitle = "delete_reply_title"
        static let deleteReplyMessage = "delete_reply_message"
        static let commentUnavailableToastMessage = "comment_unavailable_toast_message"
        static let postUnavailableToastMessage = "post_unavailable_toast_message"
        static let clipNoLongerAvailable = "social_label_this_clip_is_no_longer_available"
        static let commentEditError = "comment_edit_error"
        static let commentDeleteError = "comment_delete_failed_toast"
    }
    
    public struct Chat {
        
        // Toast
        static let toastLoading = "amity_chat_loading_label"
        static let toastDeleteErrorMessage = "amity_chat_toast_delete_error"
        static let toastCopied = "amity_chat_toast_copied"
        static let toastLinkNotAllow = "amity_chat_toast_link_not_allow"
        static let toastBannedWord = "amity_chat_toast_banned_word"
        static let toastReportMessage = "amity_chat_toast_message_reported"
        static let toastReportMessageError = "amity_chat_toast_message_reported_error"
        static let toastUnReportMessage = "amity_chat_toast_un_report_message"
        static let toastUnReportMessageError = "amity_chat_toast_un_report_message_error"
        static let toastReplyParentDeleted = "amity_chat_toast_reply_parent_deleted"
        // Button
        static let deletedMessage = "amity_chat_preview_deleted"
        static let deletedUser = "amity_chat_deleted_user"
        static let memberYouSuffix = "amity_chat_member_you_suffix"

        public struct ReactionLabel {
            static let like = "amity_chat_reaction_label_like"
            static let love = "amity_chat_reaction_label_love"
            static let fire = "amity_chat_reaction_label_fire"
            static let happy = "amity_chat_reaction_label_happy"
            static let sad = "amity_chat_reaction_label_sad"
        }

        static let editButton = "amity_chat_option_edit"
        static let replyButton = "amity_chat_option_reply"
        static let copyButton = "amity_chat_option_copy"
        static let deleteButton = "amity_chat_option_delete"
        static let reportButton = "amity_chat_option_report"
        static let unReportButton = "amity_chat_option_unreport"
        static let okButton = "amity_chat_button_ok"
        static let doneButton = "amity_chat_button_done"
        static let uploadFailedTitle = "amity_chat_upload_failed_title"
        static let uploadFailedMessage = "amity_chat_upload_failed_message"
        static let seeMore = "amity_chat_see_more"
        static let camera = "amity_chat_media_camera"

        // Composer media section
        static let mediaButton = "message_media"
        static let messagePlaceholder = "amity_chat_composer_placeholder"
        static let sendButton = "amity_chat_button_message_send"

        // Error
        static let errorLoadingChat = "amity_chat_load_error"
        static let errorBannedTitleChat = "amity_chat_label_banned_from_chat"
        static let errorBannedSubTitleInChat = "amity_chat_error_banned_chat_sub_title"

        static let charLimitAlertTitle = "amity_chat_char_limit_alert_title"
        static let charLimitAlertMessage = "amity_chat_char_limit_alert_message"
        static let deleteAlertTitle = "amity_chat_delete_alert_title"
        static let deleteAlertMessage = "amity_chat_delete_alert_message"

        static let deleteActionSheetTitle = "amity_chat_delete_action_sheet_title"

        static let userIsMuted = "amity_chat_user_is_muted"
        static let channelIsMuted = "amity_chat_group_permission_only_moderators_banner"

        static let statusSending = "amity_chat_sending_status"
        static let mediaFailedToSend = "amity_chat_message_failed_to_send"
        static let connectivityStatusWaiting = "network_connectivity_status"

        static let mentionEveryone = "amity_chat_mention_everyone"
        static let replyMessagePreview = "amity_chat_replying_to"
        static let memberCount = "amity_chat_group_member_count"

        static let reachMentionLimitTitle = "amity_chat_reach_mention_limit_title"
        static let reachMentionLimitMessage = "amity_chat_reach_mention_limit_message"
        static let notificationTurnOffError = "amity_chat_action_mute_failed"
        static let notificationTurnOnError = "amity_chat_notification_turn_on_error"
        static let modalEmptyDescription = "amity_chat_home_empty_description"

        // MARK: - Chat home / search / create group (P0/P1/P2)
        public struct Home {
            static let title = "amity_chat_home_title"
            static let menuArchived = "amity_chat_archived"
            static let menuDirectChat = "amity_chat_create_direct"
            static let menuGroupChat = "amity_chat_create_group"
            static let waitingForNetwork = "amity_chat_waiting_for_network"
            static let timestampNow = "amity_chat_timestamp_now"
            static let tabAll = "amity_chat_tab_all"
            static let tabDirect = "amity_chat_tab_direct"
            static let tabGroups = "amity_chat_tab_groups"
            static let createNew = "amity_chat_create_new_chat"
            static let emptyTitle = "amity_chat_home_empty_title"
            static let notificationsDisabled = "amity_chat_notifications_disabled"
        }

        public struct Search {
            static let placeholder = "amity_chat_search_placeholder"
            static let emptyTitle = "amity_chat_search_no_results"
            static let tabChats = "amity_chat_search_tab_chats"
            static let tabMessages = "amity_chat_search_tab_messages"
            static let minimumChars = "amity_chat_search_min_chars"
        }

        public struct CreateGroup {
            static let title = "amity_chat_create_group_title"
            static let createButton = "amity_chat_create_group_button"
            static let nameLabel = "amity_chat_group_name_label"
            static let nameOptional = "amity_chat_group_name_optional"
            static let namePlaceholder = "amity_chat_group_name_placeholder"
            static let publicTitle = "amity_chat_create_group_public_title"
            static let publicSubtitle = "amity_chat_create_group_public_subtitle"
            static let createError = "amity_chat_create_group_error"
            static let privacyTitle = "amity_chat_privacy_label"
            static let privacyPublic = "amity_chat_create_group_public_title"
            static let privacyPublicDesc = "amity_chat_create_group_public_subtitle"
            static let privacyPrivate = "amity_chat_create_group_private_title"
            static let privacyPrivateDesc = "amity_chat_create_group_private_subtitle"
            static let privacyWarning = "amity_chat_privacy_warning"
            static let memberLabel = "amity_chat_group_members"
            static let createSuccess = "amity_chat_create_group_success"
            static let leaveAlertTitle = "amity_chat_leave_without_finishing_title"
            static let leaveAlertMessage = "amity_chat_leave_without_finishing_message"
            static let memberYouLabel = "amity_chat_create_group_member_you"
        }

        public struct ParentPreview {
            static let photo = "amity_chat_reply_photo_label"
            static let video = "amity_chat_reply_video_label"
            static let unavailable = "amity_chat_reply_parent_unavailable"
        }

        public struct DM {
            static let blockUserTitle = "amity_chat_block_confirm_title"
            static let blockUserMessage = "amity_chat_block_confirm_message"
            static let blockUserConfirm = "amity_chat_block_confirm_label"
            static let unblockUserTitle = "amity_chat_unblock_confirm_title"
            static let unblockUserMessage = "amity_chat_unblock_confirm_message"
            static let unblockUserConfirm = "amity_chat_unblock_confirm_label"
            static let blockedBanner = "amity_chat_blocked_message"
        }

        public struct NotificationPreference {
            static let title = "chat_notification_pref_title"
        }

        public struct SaveMedia {
            static let imageSuccess = "amity_chat_save_photo_success"
            static let imageFailed = "amity_chat_save_photo_failed"
            static let videoSuccess = "amity_chat_save_video_success"
            static let videoFailed = "amity_chat_save_video_failed"
            static let saveImageAction = "amity_chat_action_save"
            static let saveVideoAction = "amity_chat_action_save"
        }

        public struct JumpToMessage {
            static let unavailable = "amity_chat_jump_to_message_unavailable"
        }

        public struct Bubble {
            static let edited = "amity_chat_status_edited"
            static let linkPreviewUnavailable = "amity_chat_preview_not_available"
            static let linkPreviewNoData = "amity_chat_bubble_link_preview_no_data"
            static let replyYouToDeleted = "amity_chat_reply_you_to_deleted"
            static let replyToDeleted    = "amity_chat_reply_to_deleted"
            // Private (1:1) — no names
            static let replyYou               = "amity_chat_reply_you"
            static let replyToYou             = "amity_chat_reply_to_you"
            static let replyToThemself        = "amity_chat_reply_to_themself"
            static let replyYouToYourself     = "amity_chat_reply_you_to_yourself"
            // Group — with name placeholders (%@)
            static let replyYouToName         = "amity_chat_reply_you_to_name"
            static let replyNameToYou         = "amity_chat_reply_name_to_you"
            static let replyNameToThemself    = "amity_chat_reply_name_to_themself"
            static let replyNameToName        = "amity_chat_reply_name_to_name"
            static let unknownUser            = "amity_chat_unknown_user"
            static let repliedMessage         = "amity_chat_message_replied_message"
            static let replyingYourself       = "amity_chat_message_replying_yourself"
            static let resend                 = "amity_chat_message_resend"
            static let editing                = "amity_chat_editing_message"
        }
        
        // MARK: - P4.27 full localization sweep

        public struct GroupMemberList {
            static let tabMembers = "amity_chat_group_member_list_tab_title"
            static let tabModerators = "amity_chat_member_tab_moderators"
            static let navbarTitle = "amity_chat_member_list_title"
            static let searchPlaceholder = "amity_chat_search_placeholder"
            static let moderatorBadge = "chat_group_member_list_moderator_badge"
            static let empty = "amity_chat_no_members_found"
            static let actionCompleted = "chat_group_member_list_action_completed"
            static let actionFailed = "chat_group_member_list_action_failed"

            // Confirmation dialogs
            static let promoteTitle = "amity_chat_group_member_list_promote_title"
            static let promoteMessage = "amity_chat_group_member_list_promote_message"
            static let promoteConfirm = "amity_chat_group_member_list_promote_confirm"
            static let demoteTitle = "amity_chat_group_member_list_demote_title"
            static let demoteMessage = "amity_chat_group_member_list_demote_message"
            static let demoteConfirm = "amity_chat_group_member_list_demote_confirm"
            static let removeTitle = "amity_chat_group_member_list_remove_title"
            static let removeMessage = "amity_chat_group_member_list_remove_message"
            static let removeConfirm = "amity_chat_group_member_list_remove_confirm"
            static let banTitle = "amity_chat_ban_confirm_title"
            static let banMessage = "amity_chat_group_member_list_ban_message"
            static let banConfirm = "amity_chat_group_member_list_ban_confirm"
            static let muteTitle = "amity_chat_mute_confirm_title"
            static let muteMessage = "amity_chat_mute_confirm_message"
            static let muteConfirm = "amity_chat_mute_confirm_label"
            static let unmuteTitle = "amity_chat_unmute_confirm_title"
            static let unmuteMessage = "amity_chat_unmute_confirm_message"
            static let unmuteConfirm = "amity_chat_unmute_confirm_label"
            static let cancel = "amity_chat_cancel"

            // Per-action toasts
            static let toastPromoted = "amity_chat_group_member_list_toast_promoted"
            static let toastPromoteError = "amity_chat_action_promote_member_failed"
            static let toastDemoted = "amity_chat_group_member_list_toast_demoted"
            static let toastDemoteError = "amity_chat_action_demote_member_failed"
            static let toastRemoved = "amity_chat_action_remove_member"
            static let toastRemoveError = "amity_chat_action_remove_member_failed"
            static let toastBanned = "amity_chat_group_member_list_toast_banned"
            static let toastBanError = "amity_chat_action_ban_member_failed"
            static let toastMuted = "amity_chat_action_mute_user"
            static let toastMuteError = "amity_chat_action_mute_user_failed"
            static let toastUnmuted = "amity_chat_action_unmute_user"
            static let toastUnmuteError = "amity_chat_action_unmute_user_failed"
        }

        public struct GroupSetting {
            static let leaveTitle = "amity_chat_group_leave_confirm_title"
            static let leaveConfirm = "amity_chat_group_leave_confirm_label"
            static let leaveFailed = "amity_chat_action_leave_group_failed"
            static let toastLeft = "amity_chat_toast_group_chat_left"
            static let sectionGroup = "amity_chat_group_settings_section"
            static let tileProfile = "amity_chat_group_profile"
            static let tileNotifications = "chat_group_setting_tile_notifications"
            static let tilePermissions = "amity_chat_group_member_permissions"
            static let tileAllMembers = "amity_chat_group_members_label"
            static let tileBanned = "amity_chat_group_banned_members"
            static let sectionPreferences = "amity_chat_your_preferences_section"
            static let tileMyNotifications = "amity_chat_notifications_title"
            static let toggleOn = "amity_chat_notifications_on"
            static let toggleOff = "amity_chat_notifications_off"
            static let leaveButton = "amity_chat_group_leave"
            static let notifModeDefault = "amity_chat_group_notification_default_label"
            static let notifModeSilent = "amity_chat_group_notification_silent_label"
            static let notifModeSubscribe = "amity_chat_group_notification_subscribe_label"
            static let leaveGroupConfirm = "amity_chat_group_leave_confirm_message"
            static let leaveLastModTitle = "amity_chat_group_leave_last_mod_title"
            static let leaveLastModMessage = "amity_chat_group_leave_last_mod_message"
            static let promoteMemberCTA = "amity_chat_group_promote_member"
        }

        public struct EditGroupProfile {
            static let navbarTitle = "amity_chat_edit_group_profile_navbar_title"
            static let save = "amity_chat_group_edit_profile_save"
            static let toastSuccess = "amity_chat_group_edit_profile"
            static let toastFailed = "amity_chat_group_edit_profile_failed"
            static let nameLabel = "chat_edit_group_profile_name_label"
            static let namePlaceholder = "amity_chat_edit_group_profile_name_placeholder"
            static let avatarLibrary = "amity_chat_media_photo"
            static let nameRequired = "amity_chat_group_name_required"
            static let uploadFailedTitle = "amity_chat_group_edit_profile_upload_failed_title"
            static let uploadFailedMessage = "amity_chat_group_edit_profile_upload_failed_message"
        }

        public struct EditGroupNotification {
            static let navbarTitle = "amity_chat_group_notifications"
            static let save = "amity_chat_group_edit_notification_save"
            static let toastSuccess = "amity_chat_group_notification_save_success"
            static let toastFailed = "amity_chat_group_notification_save_error"
            static let modeDefaultTitle = "amity_chat_group_notification_default_title"
            static let modeDefaultDescription = "amity_chat_group_notification_default_desc"
            static let modeSilentTitle = "amity_chat_group_notification_silent_title"
            static let modeSilentDescription = "amity_chat_group_notification_silent_desc"
            static let modeSubscribeTitle = "amity_chat_group_notification_subscribe_title"
            static let modeSubscribeDescription = "amity_chat_group_notification_subscribe_desc"
        }

        public struct EditGroupMemberPermission {
            static let navbarTitle = "amity_chat_group_member_permissions_navbar_title"
            static let save = "amity_chat_group_edit_permission_save"
            static let toastSuccess = "amity_chat_edit_group_perm_toast_success"
            static let toastFailed = "amity_chat_edit_group_perm_toast_failed"
            static let sectionMessaging = "amity_chat_group_edit_permissions_messaging_title"
            static let optionEveryoneTitle = "amity_chat_group_edit_permissions_everyone_title"
            static let optionEveryoneDescription = "amity_chat_group_edit_permissions_everyone_description"
            static let optionModeratorsTitle = "amity_chat_group_edit_permissions_moderators_only_title"
            static let optionModeratorsDescription = "amity_chat_group_edit_permissions_moderators_only_description"
        }

        public struct AddGroupMember {
            static let navbarTitle = "amity_chat_add_member_title"
            static let submitButton = "amity_chat_add_member_button"
            static let memberChip = "amity_chat_add_member_chip"
            static let toastFailed = "amity_chat_add_group_member_toast_failed"
            static let toastAdded = "amity_chat_toast_member_added"
            static let toastAddedMultiple = "amity_chat_toast_members_added"
            static let toastAddMultipleError = "amity_chat_toast_members_add_error"
            static let searchPlaceholder = "amity_chat_search_placeholder"
            static let empty = "chat_add_group_member_empty"
        }

        public struct BannedMembers {
            static let navbarTitle = "amity_chat_banned_member_list_navbar_title"
            static let searchPlaceholder = "amity_chat_search_placeholder"
            static let empty = "amity_chat_banned_members_empty"
            static let unbanSuccess = "amity_chat_action_unban_user"
            static let unbanFailed = "amity_chat_action_unban_user_failed"
            static let unbanUser = "amity_chat_member_action_unban"
            static let unbanConfirmTitle = "amity_chat_unban_confirm_title"
            static let unbanConfirmDescription = "amity_chat_unban_confirm_message"
            static let unbanButton = "user_unban_button"
        }

        public struct Archived {
            static let navbarTitle = "amity_chat_archived_navbar_title"
            static let emptyTitle = "amity_chat_archived_empty_title"
            static let label = "amity_chat_archived_badge_label"
        }
        
        public struct Archive {
            static let archive = "amity_chat_archive"
            static let unarchive = "amity_chat_unarchive"
            static let toastArchived = "amity_chat_archived_toast"
            static let toastUnarchived = "amity_chat_unarchived_toast"
            static let toastArchiveError = "amity_chat_archive_error_toast"
            static let toastUnarchiveError = "amity_chat_unarchive_error_toast"
            static let limitTitle = "amity_chat_archive_limit_title"
            static let limitMessage = "amity_chat_archive_limit_message"
        }

        // Channel preview placeholders
        public struct Preview {
            static let messageDeleted = "amity_chat_message_deleted"
            static let messagePhoto = "amity_chat_reply_photo_label"
            static let messagePhotoSent = "amity_chat_preview_sent_photo"
            static let messageVideo = "amity_chat_reply_video_label"
            static let messageVideoSent = "amity_chat_preview_sent_video"
            static let messageGeneric = "amity_chat_preview_message"
            static let messageNoPreview = "amity_chat_message_no_preview"
            static let messageNoContent = "amity_chat_message_no_content"
            static let noMessageYet = "amity_chat_preview_no_message"
            static let unknownUser = "user_profile_unknown_name"
            // New message banner
            static let bannerPhoto = "amity_chat_message_photo"
            static let bannerVideo = "amity_chat_message_video"
        }

        public struct CreateConversation {
            static let navbarTitle = "amity_chat_create_conversation_title"
            static let searchPlaceholder = "amity_chat_search_placeholder"
            static let empty = "chat_create_conversation_empty"
        }

        public struct SelectGroupMember {
            static let navbarTitle = "amity_chat_select_members_title"
            static let next = "amity_chat_next"
            static let done = "amity_chat_select_group_member_done"
            static let searchPlaceholder = "amity_chat_search_placeholder"
            static let empty = "amity_chat_no_users_found"
            static let selectMemberError = "chat_select_member_error"
            // Maximum-members reached alert
            static let memberLimitAlertTitle = "amity_chat_member_limit_reached_title"
            static let memberLimitAlertMessage = "amity_chat_member_limit_reached_message"
        }

        public struct GroupNotificationPreference {
            static let navbarTitle = "amity_chat_group_notif_pref_navbar_title"
            static let save = "amity_chat_group_notif_pref_save"
            static let moderatorBanner = "amity_chat_group_notifications_disabled"
            static let toggleTitle = "amity_chat_group_notification_preference_title"
            static let toggleDescription = "amity_chat_group_notification_preference_description"
        }

        public struct GroupMemberAction {
            static let demote = "amity_chat_member_action_demote"
            static let promote = "amity_chat_member_action_promote"
            static let unmute = "amity_chat_group_member_action_unmute"
            static let mute = "amity_chat_group_member_action_mute"
            static let report = "amity_chat_action_report_user"
            static let unreport = "amity_chat_action_unreport_user"
            static let remove = "amity_chat_member_action_remove"
            static let ban = "amity_chat_user_action_ban"
        }

        public struct EditMessage {
            static let previewTitle = "amity_chat_edit_message_preview_title"
        }

        public struct ComposerCamera {
            static let deniedTitle = "amity_chat_composer_camera_denied_title"
            static let deniedMessage = "amity_chat_composer_camera_denied_message"
            static let openSettings = "amity_chat_composer_camera_denied_open_settings"
            static let cameraTitle = "amity_chat_permission_camera_title"
            static let cameraDetail = "amity_chat_permission_camera_detail"
            static let microphoneTitle = "amity_chat_permission_microphone_title"
            static let microphoneDetail = "amity_chat_permission_microphone_detail"
            static let permissionDenied = "amity_chat_toast_permission_denied"
        }

        public struct DMAction {
            static let turnOnNotifications = "amity_chat_action_turn_on_notification"
            static let turnOffNotifications = "amity_chat_action_turn_off_notification"
            static let unreportUser = "amity_chat_action_unreport_user"
            static let reportUser = "amity_chat_action_report_user"
            static let unblockUser = "amity_chat_action_unblock_user"
            static let blockUser = "amity_chat_action_block_user"
            static let toastNotificationsOn = "amity_chat_action_unmute"
            static let toastNotificationsOff = "amity_chat_action_mute"
            static let toastUnmuteFailed = "amity_chat_toast_unmute_failed"
            static let toastMuteFailed = "amity_chat_toast_mute_failed"
            static let toastUserBlocked = "amity_chat_block_success"
            static let toastUserUnblocked = "amity_chat_unblock_success"
            static let toastBlockFailed = "amity_chat_block_failed"
            static let toastUnblockFailed = "amity_chat_unblock_failed"
        }
        static let editMessage = "amity_chat_edit_message"

        // Shared report-user toasts
        static let toastUserReported = "amity_chat_action_report_user_success"
        static let toastUserUnreported = "amity_chat_action_unreport_user_success"
        static let toastReportUserFailed = "amity_chat_action_report_user_failed"
        static let toastUnreportUserFailed = "amity_chat_action_unreport_user_failed"
    }
    
    public struct LiveChat {
        static let deleteMessage = "live_chat_delete_message"
        static let reportMessage = "live_chat_report_message"
        static let unreportMessage = "live_chat_unreport_message"
        static let toastReportMessage = "live_chat_toast_report_message"
        static let toastUnReportMessage = "live_chat_toast_unreport_message"
        static let promoteToModerator = "live_chat_promote_to_moderator"
        static let demoteToMember = "live_chat_demote_to_member"
        static let muteUser = "live_chat_mute_user"
        static let unmuteUser = "live_chat_unmute_user"
        static let promoteToModeratorTitle = "live_chat_promote_to_moderator_title"
        static let promoteToModeratorDesc = "live_chat_promote_to_moderator_desc"
        static let demoteToMemberTitle = "live_chat_demote_to_member_title"
        static let demoteToMemberDesc = "live_chat_demote_to_member_desc"
        static let muteUserTitle = "live_chat_mute_user_title"
        static let muteUserDesc = "live_chat_mute_user_desc"
        static let unmuteUserTitle = "live_chat_unmute_user_title"
        static let unmuteUserDesc = "live_chat_unmute_user_desc"
        static let promote = "live_chat_promote_button"
        static let demote = "live_chat_demote_button"
        static let mute = "live_chat_mute_button"
        static let unmute = "live_chat_unmute_button"
        static let promoteSuccessToastMessage = "live_chat_promote_to_moderator_success_toast"
        static let promoteFailedToastMessage = "live_chat_promote_to_moderator_failed_toast"
        static let demoteSuccessToastMessage = "live_chat_demote_to_member_success_toast"
        static let demoteFailedToastMessage = "live_chat_demote_to_member_failed_toast"
        static let muteSuccessToastMessage = "live_chat_mute_user_success_toast"
        static let muteFailedToastMessage = "live_chat_mute_user_failed_toast"
        static let unmuteSuccessToastMessage = "live_chat_unmute_user_success_toast"
        static let unmuteFailedToastMessage = "live_chat_unmute_user_failed_toast"
    }
    
    public struct Reaction {
        static let unableToLoadTitle = "reaction_list_unable_to_load_title"
        static let unableToLoadSubtitle = "reaction_list_unrable_to_load_subtitle"
        static let noReactionTitle = "reaction_list_no_reactions_title"
        static let noReactionSubtitle = "reaction_list_no_reactions_subtitle"
        static let tapToRemove = "reaction_list_tap_to_remove"
        static let allTab = "amity_common_reaction_all_tab"

        // Reaction display name keys (resolved via AmityStringProvider.common)
        static let reactionLike = "amity_social_reaction_like"
        static let reactionLove = "amity_social_reaction_love"
        static let reactionFire = "amity_social_reaction_fire"
        static let reactionHappy = "amity_social_reaction_happy"
        static let reactionSad = "amity_social_reaction_sad"
        static let reactionHeart = "amity_social_reaction_heart"
        static let reactionGrinning = "amity_social_reaction_grinning"
    }
    
    public enum Social {
        static let keepEditing = "amity_social_button_keep_editing"
        static let reachMentionLimitTitle = "social_reach_mention_limit_title"
        static let reachMentionLimitMessage = "social_reach_mention_limit_message"
        static let emptyNewsFeedDescription = "amity_social_label_find_community_or_create_your_own"
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
        static let createStoryBottomSheetTitle = "amity_social_button_story"
        static let communityPageJoinTitle = "community_page_join_title"
        static let communityPageJoinedTitle = "community_page_joined_title"
        static let communityPagePendingPostTitle = "community_page_pending_post_title"
        static let communitySetupAlertTitle = "community_setup_alert_title"
        static let communitySetupAlertMessage = "community_setup_alert_message"
        static let communitySetupEditAlertTitle = "community_setup_edit_alert_title"
        static let communitySetupEditAlertMessage = "community_setup_edit_alert_message"
        static let livestreamPlayerEndedTitle = "livestream_player_ended_title"
        static let livestreamPlayerEndedMessage = "livestream_player_ended_message"
        static let livestreamPlayerErrorTitle = "livestream_player_error_title"
        static let livestreamPlayerErrorMessage = "livestream_player_error_message"
        
        static let livestreamPlayerTerminatedTitle = "livestream_player_terminated_title"
        static let livestreamPlayerTerminatedMessage = "livestream_player_terminated_message"
        static let livestreamPlayerBannedTitle = "livestream_player_banned_title"
        static let livestreamPlayerBannedMessage = "livestream_player_banned_message"
        static let livestreamPlayerUnavailableTitle = "livestream_player_unavailable_title"
        static let livestreamPlayerUnavailableMessage = "livestream_player_unavailable_message"
        static let livestreamPlayerReconnectingTitle = "livestream_player_reconnecting_title"
        static let livestreamPlayerReconnectingMessage = "livestream_player_reconnecting_message"
        static let livestreamPlayerRecorded = "livestream_player_recorded"
        static let livestreamPlayerUpcomingLive = "livestream_player_upcoming_live"
        static let liveStreamSettingReadOnlyTitle = "live_stream_setting_readonly_title"
        static let liveStreamSettingReadOnlyDescription = "live_stream_setting_readonly_description"
        
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
        static let communitySettingCloseCommunityAlertMessage = "social_button_close_community_msg"
        
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
        static let communityMemberLabelSingular = "community_member_label_singular"
        static let communityMemberLabelPlural = "community_member_label_plural"
        
        // Community Membership Page
        static let communityMembershipAllMembersTitle = "community_membership_all_members_title"
        static let communityMembershipTabModerators = "community_membership_tab_moderators"
        static let communityMembershipAddSuccess = "community_membership_add_success"
        static let communityMembershipAddFailed = "community_membership_add_failed"
        static let communityMembershipInviteSuccess = "community_membership_invite_success"
        static let communityMembershipInviteFailed = "community_membership_invite_failed"
        static let communityRemoveMember = "amity_community_remove_member"
        
        static let exploreCategoriesSeeMore = "explore_categories_see_more"
        static let expandableTextSeeMore = "expandable_text_see_more"
        static let exploreTrendingComponentTitle = "explore_trending_now_component_title"
        static let exploreRecommendedComponentTitle = "amity_social_label_recommended_for_you"
        
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
        static let userProfileEditSuccess = "user_profile_edit_success"
        static let userProfileEditBannedWord = "user_profile_edit_banned_word"
        static let userProfileEditFailed = "user_profile_edit_failed"
        static let userProfileFollowRequestTitle = "user_profile_follow_request_title"
        
        
        static let userProfileAllPostTitle = "amity_social_user_profile_all_post_title"
        static let userProfileCommunityPostTitle = "amity_social_user_profile_community_post_title"
        static let userProfileUserPostTitle = "amity_social_user_profile_user_post_title"
        
        // Poll
        static let pollCloseAlertTitle = "poll_close_alert_title"
        static let pollCloseAlertDesc = "poll_close_alert_desc"
        static let pollCloseButton = "poll_close_button"
        static let pollCloseToastError = "poll_close_toast_error"

        static let pollRemainingDaysLeft = "poll_remaining_days_left"
        static let pollRemainingHoursLeft = "poll_remaining_hours_left"
        static let pollRemainingMinutesLeft = "poll_remaining_minutes_left"

        static let pollQuestionTitle = "poll_question_title"
        static let pollPostTitle = "poll_post_title"
        static let pollPostTitleOptional = "poll_post_title_optional"
        static let pollPostTitleTextfieldPlaceholder = "poll_post_title_textfield_placeholder"
        static let pollQuestionTextfieldPlaceholder = "poll_question_textfield_placeholder"
        static let pollMultipleSelectionTitle = "poll_multiple_selection_title"
        static let pollMultipleSelectionDesc = "poll_multiple_selection_desc"

        static let pollPostCreateError = "poll_post_create_error"
        static let pollPostCreateBanWordError = "poll_post_create_ban_word_error"
        static let pollCreatePostingToast = "poll_create_posting_toast"

        static let pollDurationTitle = "poll_duration_title"
        static let pollDurationDesc = "poll_duration_desc"
        static let pollEndsOnLabel = "poll_ends_on_label"

        static let pollOptionsTitle = "poll_options_title"
        static let pollOptionsDesc = "poll_options_desc"
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
        static let pollDateTimeFormat = "amity_social_poll_date_time_format"

        static let pollSelectOneOptionLabel = "poll_select_one_option_label"
        static let pollSelectOneOrMoreOptionLabel = "poll_select_one_or_more_option_label"

        static let pollSeeFullResultsLabel = "poll_see_full_results_label"
        static let pollSeeResultsLabel = "poll_see_results_label"
        static let pollBackToVoteLabel = "poll_back_to_vote_label"
        static let pollSeeMoreOptionsLabel = "poll_see_more_options_label"

        static let pollVoteCounts = "poll_vote_counts"
        static let pollVoteButton = "poll_vote_button"
        static let pollUnvoteButton = "poll_unvote_button"
        
        static let pollLabel = "poll_label"
        
        static let pollOptionCharLimitError = "poll_option_char_limit_error"
        static let pollQuestionCharLimitError = "poll_question_char_limit_error"
        static let pollTitleCharLimitError = "poll_title_char_limit_error"
        
        static let pollTargetMyTimeline = "poll_target_my_timeline"
        
        static let postDeleteError = "post_delete_error"
        static let postCreateError = "post_create_error"
        static let postEditError = "post_edit_error"
        
        static let postDiscardAlertTitle = "social_modal_dialog_title_discard_post"
        static let postDiscardAlertMessage = "post_discard_alert_message"
        
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
        static let liveStreamPermissionCameraAndMicrophoneMessage = "amity_social_status_allow_camera_desc"

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
        
        static let liveStreamLabel = "amity_social_status_live_stream"
        
        static let altTextButtonTitle = "alt_text_button_title"
        static let altTextTitle = "alt_text_title"
        static let altTextEditTitle = "alt_text_edit_title"
        static let socialViewPost = "social_label_view_original_post"
        static let altTextPlaceholder = "alt_text_placeholder"
        static let altTextFailedToAdd = "alt_text_failed_to_add"
        static let altTextFailedToEdit = "alt_text_failed_to_edit"
        static let altTextIncludesBannedWords = "alt_text_includes_banned_words"
        static let altTextIncludesNotAllowedLink = "alt_text_includes_not_allowed_link"
        static let altTextUpdated = "alt_text_updated"

        // Product Tags
        static let productTagsAdded = "product_tags_added"
        static let productTagsUpdated = "product_tags_updated"
        static let productTagLimitTitle = "product_tag_limit_title"
        static let productTagLimitMessage = "product_tag_limit_message"
        static let productTagUnavailableTitle = "social_label_product_tagging_unavailable_title"
        static let productTagUnavailableMessage = "product_tag_unavailable_description"
        static let productTagUnavailableWhileStreamingMessage = "product_tag_unavailable_while_streaming_message"
        static let productTagReviewPost = "product_tag_review_post"
        static let productTagPublish = "product_tag_publish"
        static let productTagEditLive = "product_tag_edit_live"
        static let productTagGoLive = "product_tag_go_live"
        static let productTagDisableCoHostTitle = "product_tag_disable_cohost_title"
        static let productTagDisableCoHostMessage = "product_tag_disable_cohost_message"
        static let productTagDisableButton = "product_tag_disable_button"
        static let productTagToastAdded = "product_tag_toast_added"
        static let productTagToastPinned = "product_tag_toast_pinned"
        static let productTagToastUnpinned = "product_tag_toast_unpinned"
        static let productTagToastPinFailed = "product_tag_toast_pin_failed"
        static let productTagToastUnpinFailed = "product_tag_toast_unpin_failed"
        static let productTagToastRemoved = "product_tag_toast_removed"
        static let productTagToastCoHostManageEnabled = "product_tag_toast_cohost_manage_enabled"
        static let productTagCoHostRevokedMessage = "product_tag_cohost_revoked_message"
        static let productTagSelectionDiscardTitle = "product_tag_selection_discard_title"
        static let productTagSelectionDiscardMessage = "product_tag_selection_discard_message"
        static let productTagDiscardTitle = "product_tag_discard_title"
        static let productTagDiscardMessage = "product_tag_discard_message"
        static let productTagDiscard = "product_tag_discard"
        static let productTagTaggedProducts = "product_tag_tagged_products"
        static let productTagAddProducts = "product_tag_add_products"
        static let productTagPinnedLabel = "product_tag_pinned_label"
        static let productTagUnlistedLabel = "product_tag_unlisted_label"
        static let productTagPinButton = "product_tag_pin_button"
        static let productTagUnpinButton = "product_tag_unpin_button"
        static let productTagNoProductsTitle = "product_tag_no_products_title"
        static let productTagNoProductsMessage = "product_tag_no_products_message"
        static let productTagPinnedProductSection = "product_tag_pinned_product_section"
        static let productTagOtherProductsSection = "product_tag_other_products_section"
        static let liveStreamEndingStreamTitle = "live_stream_ending_stream_title"
        static let liveStreamWaitingForApprovalTitle = "live_stream_waiting_for_approval_title"
        static let liveStreamWaitingForApprovalMessage = "live_stream_waiting_for_approval_message"
        static let liveStreamWaitingForCoHost = "live_stream_waiting_for_cohost"

        static let notificationTrayEmptyStateTitle = "notification_tray_empty_state_title"
        
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
        static let reportReasonContentTypePost = "report_reason_content_type_post"
        static let reportReasonContentTypeComment = "report_reason_content_type_comment"
        static let reportReasonContentTypeReply = "report_reason_content_type_reply"
        static let reportReasonContentTypeMessage = "report_reason_content_type_message"
        static let reportReasonCommunityGuidelines = "social_label_report_reason_community_guidelines"
        static let reportReasonFalseInformation = "social_label_report_reason_false_information"
        static let reportReasonHarassmentOrBullying = "social_label_report_reason_harassment_or_bullying"
        static let reportReasonSelfHarmOrSuicide = "social_label_report_reason_self_harm_or_suicide"
        static let reportReasonSellingRestricted = "social_label_report_reason_selling_restricted"
        static let reportReasonSexualContentOrNudity = "social_label_report_reason_sexual_content_or_nudity"
        static let reportReasonSpamOrScams = "social_label_report_reason_spam_or_scams"
        static let reportReasonViolenceOrThreatening = "social_label_report_reason_violence_or_threatening"
        
        static let communityUpdateSuccessToastMessage = "community_update_success_toast_message"
        
        static let pendingJoinRequestAlertTitle = "pending_join_request_alert_title"
        static let pendingJoinRequestAlertMessage = "pending_join_request_alert_message"
        
        static let communityLeaveAlertPendingRequestMessage = "community_leave_alert_pending_request_message"
        
        static let communityJoinToastSuccessMessage = "community_join_toast_success_message"
        static let communityJoinToastRequestSuccessMessage = "community_join_toast_request_success_message"
        
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
        
        static let errorGuestUser = "error_guest_user"

        static let exploreEventViewAll = "explore_event_view_all"

        static let myEventFeedUpcoming = "my_event_feed_upcoming"
        static let myEventFeedPast = "my_event_feed_past"

        static let eventDetailAlertEditNotPossibleTitle = "event_detail_alert_edit_not_possible_title"
        static let eventDetailAlertEditNotPossibleMessage = "amity_social_label_you_can_no_longer_edit_this_event_changes_are_restricte"
        static let eventDetailAlertLeaveWithoutFinishingTitle = "event_detail_alert_leave_without_finishing_title"
        static let eventDetailAlertLeaveWithoutFinishingMessage = "event_detail_alert_leave_without_finishing_message"
        static let eventDetailAlertDeleteEventTitle = "event_detail_alert_delete_event_title"
        static let eventDetailAlertDeleteEventMessage = "event_detail_alert_delete_event_message"
        static let eventDetailAlertPendingJoinRequestTitle = "amity_event_alert_pending_join_request_title"
        static let eventDetailAlertPendingJoinRequestMessage = "amity_event_alert_pending_join_request_message"

        static let eventDiscussionFeedNoPostsYet = "amity_social_empty_state_empty_feed_no_posts"

        static let eventInfoAboutTheEvent = "event_info_about_the_event"
        static let eventInfoSeeMore = "event_info_see_more"
        static let eventInfoEventLink = "event_info_event_link"
        static let eventInfoLiveStream = "amity_social_status_live_stream"
        static let eventInfoEventAddress = "event_info_event_address"
        static let eventInfoAddressCopied = "event_info_address_copied"
        static let eventInfoCopy = "event_info_copy"
        static let eventInfoLinkCopied = "event_info_link_copied"
        static let eventInfoStreamStatusLive = "event_info_stream_status_live"
        static let eventInfoStreamStatusRecorded = "event_info_stream_status_recorded"
        static let eventInfoStreamStatusUpcomingLive = "event_info_stream_status_upcoming_live"

        static let eventDetailHeaderUnknownUser = "event_detail_header_unknown_user"
        static let eventDetailHeaderStarts = "event_detail_header_starts"
        static let eventDetailHeaderEventType = "event_detail_header_event_type"
        static let eventDetailHeaderInPerson = "event_detail_header_in_person"
        static let eventDetailHeaderVirtual = "event_detail_header_virtual"
        static let eventDetailHeaderHostedBy = "event_detail_header_hosted_by"
        static let eventDetailHeaderStatusUpcoming = "event_detail_header_status_upcoming"
        static let eventDetailHeaderStatusCancelled = "event_detail_header_status_cancelled"
        static let eventDetailHeaderStatusEnded = "event_detail_header_status_ended"
        static let eventDetailHeaderAttendees = "event_detail_header_attendees"
        static let eventDetailHeaderEventAddedToCalendar = "event_detail_header_event_added_to_calendar"
        static let eventDetailHeaderNoCalendarAccess = "event_detail_header_no_calendar_access"
        static let eventDetailHeaderAttendingStatusChangeNotAllowed = "event_detail_header_attending_status_change_not_allowed"
        static let eventDetailHeaderUpdateAttendingStatusFailed = "event_detail_header_update_attending_status_failed"
        static let eventDetailHeaderAddToCalendar = "event_detail_header_add_to_calendar"
        static let eventDetailHeaderGoing = "event_detail_header_going"
        static let eventDetailHeaderNotGoing = "event_detail_header_not_going"
        static let eventDetailHeaderRsvp = "event_detail_header_rsvp"
        static let eventDetailHeaderUpdateAttendingStatusSuccess = "event_detail_header_update_attending_status_success"
        static let eventDetailHeaderLivestreamSetupInfo = "event_detail_header_livestream_setup_info"

        static let eventAttendeesPageTitle = "event_attendees_page_title"

        static let joinCommunitySheetTitle = "join_community_sheet_title"
        static let joinCommunitySheetDescription = "join_community_sheet_description"
        static let joinCommunitySheetJoinAndRsvp = "join_community_sheet_join_and_rsvp"
        static let joinCommunitySheetJoin = "join_community_sheet_join"
        static let joinCommunitySheetCancel = "join_community_sheet_cancel"

        static let addCalendarSheetTitle = "add_calendar_sheet_title"
        static let addCalendarSheetDescription = "add_calendar_sheet_description"
        static let addCalendarSheetAddButton = "add_calendar_sheet_add_button"

        static let eventListPastEventsTitle = "event_list_past_events_title"
        static let eventListUpcomingEventsTitle = "event_list_upcoming_events_title"
        static let eventListTabAll = "event_list_tab_all"
        static let eventListTabHosting = "event_list_tab_hosting"
        static let eventListHappeningNowTitle = "social_button_happening_now"

        static let eventDetailPageEditEvent = "amity_social_label_edit_event"
        static let eventDetailPageDeleteEvent = "event_detail_page_delete_event"
        static let eventDetailPageEventDeleted = "event_detail_page_event_deleted"
        static let eventDetailPageDeleteFailed = "event_detail_page_delete_failed"
        static let eventDetailPageSetupLivestream = "event_detail_page_setup_livestream"
        static let eventDetailCopyEventLink = "event_detail_copy_event_link"
        static let eventDetailFailedToCopyLink = "event_detail_failed_to_copy_link"

        static let eventSetupEventNameTitle = "event_setup_event_name_title"
        static let eventSetupEventNamePlaceholder = "event_setup_event_name_placeholder"
        static let eventSetupEventDetailsTitle = "event_setup_event_details_title"
        static let eventSetupEventDetailsPlaceholder = "event_setup_event_details_placeholder"
        static let eventSetupEditEventTitle = "amity_social_label_edit_event"
        static let eventSetupLeaveAlertTitle = "event_setup_leave_alert_title"
        static let eventSetupLeaveAlertMessage = "event_setup_leave_alert_message"
        static let eventSetupCamera = "event_setup_camera"
        static let eventSetupPhoto = "event_setup_photo"
        static let eventSetupDateAndTime = "event_setup_date_and_time"
        static let eventSetupTimezone = "event_setup_timezone"
        static let eventSetupStartsOn = "event_setup_starts_on"
        static let eventSetupNoEndTimeInfo = "event_setup_no_end_time_info"
        static let eventSetupAddEndDateTime = "event_setup_add_end_date_time"
        static let eventSetupEndsOn = "social_button_event_setup_ends_on"
        static let eventSetupLocation = "event_setup_location"
        static let eventSetupLocationPlaceholder = "event_setup_location_placeholder"
        static let eventSetupCreating = "event_setup_creating"
        static let eventSetupSaving = "event_setup_saving"
        static let eventSetupSuccessfullyCreated = "event_setup_successfully_created"
        static let eventSetupSuccessfullyUpdated = "event_setup_successfully_updated"
        static let eventSetupUpdateTimeLimitError = "amity_social_error_event_setup_update_time_limit_error"
        static let eventSetupCreateTimeLimitError = "event_setup_create_time_limit_error"
        static let eventSetupUpdateTimeLimitErrorGeneric = "amity_social_error_event_setup_update_time_limit_error"
        static let eventSetupCreateLinkNotAllowedError = "event_setup_create_link_not_allowed_error"
        static let eventSetupUpdateLinkNotAllowedError = "event_setup_update_link_not_allowed_error"
        static let eventSetupCreateBanWordError = "event_setup_create_ban_word_error"
        static let eventSetupUpdateBanWordError = "event_setup_update_ban_word_error"
        static let eventSetupCreateFailed = "event_setup_create_failed"
        static let eventSetupUpdateFailed = "event_setup_update_failed"
        static let eventSetupCreateButton = "event_setup_create_button"
        static let eventSetupSaveButton = "event_setup_save_button"
        static let eventSetupUploadFailedTitle = "event_setup_upload_failed_title"
        static let eventSetupUploadFailedMessage = "event_setup_upload_failed_message"

        static let communityEventFeedUpcoming = "community_event_feed_upcoming"
        static let communityEventFeedPast = "community_event_feed_past"

        static let eventTargetSelectionNoCommunities = "event_target_selection_no_communities"

        static let eventEmptyStateNoEvents = "event_empty_state_no_events"

        // Live Stream Co-Host Invite
        static let livestreamInviteCoHostTitle = "livestream_invite_cohost_title"
        static let livestreamCoHostingSectionTitle = "livestream_cohosting_section_title"
        static let livestreamRemoveCoHostButton = "livestream_remove_cohost_button"
        static let livestreamCancelInvitationButton = "livestream_cancel_invitation_button"
        static let livestreamInvitationCancelledToast = "livestream_invitation_cancelled_toast"
        static let livestreamInvitationCancelFailedToast = "social_toast_invitation_cancel_failed_toast"
        static let livestreamWhosWatchingTitle = "livestream_whos_watching_title"
        static let livestreamInviteButton = "livestream_invite_button"
        static let livestreamInvitationSentToast = "livestream_invitation_sent_toast"
        static let livestreamInvitationSendFailedToast = "livestream_invitation_send_failed_toast"
        static let livestreamConfirmInviteCoHostTitle = "livestream_confirm_invite_cohost_title"
        static let livestreamConfirmInviteCoHostMessage = "livestream_confirm_invite_cohost_message"
        static let livestreamNoViewersTitle = "livestream_no_viewers_title"
        static let livestreamNoViewersMessage = "livestream_no_viewers_message"

        // Live Stream Co-Host Join
        static let livestreamJoinAsCoHostTitle = "livestream_join_as_cohost_title"
        static let livestreamJoinAsCoHostMessage = "livestream_join_as_cohost_message"
        static let livestreamAcceptButton = "livestream_accept_button"
        static let livestreamDeclineButton = "livestream_decline_button"

        // Live Stream Badges
        static let livestreamHost = "amity_social_status_host_badge"
        static let livestreamCoHost = "amity_social_button_cohost"
        static let livestreamModeratorBadge = "amity_common_moderator"

        // Live Stream Banned Page
        static let livestreamBannedPageTitle = "amity_social_status_live_stream"
        static let livestreamBannedTitle = "livestream_banned_title"
        static let livestreamBannedMessage = "livestream_banned_message"
        static let livestreamBannedOkButton = "livestream_banned_ok_button"

        // Live Stream Backstage
        static let livestreamBackstageHeaderTitle = "livestream_backstage_header_title"
        static let livestreamBackstageSetupMessage = "livestream_backstage_setup_message"
        static let livestreamBackstageJoinLiveButton = "livestream_backstage_join_live_button"

        // Live Stream Chat Compose Bar
        static let livestreamChatPlaceholder = "livestream_chat_placeholder"
        static let livestreamChatMutedMessage = "livestream_chat_muted_message"
        static let livestreamChatReadonlyMessage = "livestream_chat_readonly_message"
        static let livestreamChatSendFailedMessage = "livestream_chat_send_failed_message"

        // Live Stream Chat Feed
        static let livestreamChatDeletedMessage = "livestream_chat_deleted_message"
        static let livestreamChatUnknownUser = "livestream_chat_unknown_user"
        static let livestreamChatInviteAsCoHost = "livestream_chat_invite_as_cohost"
        static let livestreamChatMessageNotSentTitle = "amity_common_label_message_not_sent"

        // Live Stream Player Page
        static let livestreamLeaveBackstageTitle = "livestream_leave_backstage_title"
        static let livestreamLeaveBackstageMessage = "livestream_leave_backstage_message"
        static let livestreamLeftStageToast = "livestream_left_stage_toast"
        static let livestreamInvitationNoLongerValid = "livestream_invitation_no_longer_valid"
        static let livestreamAcceptInvitationFailed = "livestream_accept_invitation_failed"
        static let livestreamInvitationDeclinedToast = "amity_social_toast_snackbar_invitation_declined"
        static let livestreamDeclineInvitationFailed = "livestream_decline_invitation_failed"
        static let livestreamLeftBackstageToast = "livestream_left_backstage_toast"

        // Live Stream Alerts
        static let livestreamAlertCancelCoHostInvitationTitle = "livestream_alert_cancel_cohost_invitation_title"
        static let livestreamAlertCancelCoHostInvitationMessage = "social_modal_alert_cancel_cohost_invitation_message"
        static let livestreamAlertCoHostLeaveTitle = "livestream_alert_cohost_leave_title"
        static let livestreamAlertCoHostLeaveMessage = "livestream_alert_cohost_leave_message"
        static let livestreamAlertLeaveAsCoHostTile = "livestream_alert_leave_as_cohost_title"
        static let livestreamAlertLeaveAsCoHostMessage = "livestream_alert_leave_as_cohost_message"
        static let livestreamAlertRemoveCoHostTitle = "livestream_alert_remove_cohost_title"
        static let livestreamAlertRemoveCoHostMessage = "livestream_alert_remove_cohost_message"
        static let livestreamAlertConfirmButton = "livestream_alert_confirm_button"
        static let livestreamAlertRemoveButton = "livestream_alert_remove_button"
        static let livestreamCancelInvitationLabel = "amity_livestream_cancel_invitation_label"
        static let livestreamRemoveFromLive = "amity_livestream_remove_from_live"
        static let myCommunities = "amity_social_my_communities"
        
        // Social Home Tab Titles
        static let socialHomeNewsfeedTab = "social_home_newsfeed_tab"
        static let socialHomeForYouTab = "social_home_for_you_tab"
        static let socialHomeExploreTab = "social_home_explore_tab"
        static let socialHomeMyCommunitiesTab = "social_home_my_communities_tab"
        static let socialHomeCommunitiesTab = "social_home_communities_tab"
        static let socialHomeEventsTab = "social_home_events_tab"
        static let socialHomeClipsTab = "amity_social_tab_tab_clips"

        // For You Feed — end-of-feed nudge
        static let feedCaughtUpTitle = "amity_social_feed_caught_up_title"
        static let feedCaughtUpCTA = "amity_social_feed_caught_up_cta"

        static let pendingPostsTitle = "amity_social_pending_posts_title"
        static let postAcceptedToast = "amity_social_post_accepted_toast"
        static let postDeclinedToast = "amity_social_post_declined_toast"
        static let acceptButton = "amity_social_accept_button"
        static let declineButton = "amity_social_decline_button"
        static let saveButton = "amity_social_save_button"
        static let cameraButton = "amity_social_camera_button"
        static let photoButton = "amity_social_photo_button"
        
        // Clip
        static let clipFeedEmptyTitle = "amity_social_empty_state_social_home_empty_title"
        static let clipExploreCommunity = "amity_social_clip_explore_community"
        static let clipCreateCommunity = "amity_social_clip_create_community"
        static let clipUnableToLoad = "amity_social_clip_unable_to_load"
        static let clipWatchNext = "amity_social_clip_watch_next"
        static let clipAlertMaxFileSizeTitle = "amity_clip_alert_max_file_size_title"
        static let clipAlertUnsupportedVideoTitle = "amity_clip_alert_unsupported_video_title"
        static let clipAlertMaxDurationTitle = "amity_clip_alert_max_duration_title"
        static let clipAlertTooShortTitle = "amity_clip_alert_too_short_title"
        static let clipAlertDiscardTitle = "amity_clip_alert_discard_title"
        static let clipAlertFailedUploadTitle = "amity_clip_alert_failed_upload_title"
        static let clipAlertMaxFileSizeMessage = "amity_clip_alert_max_file_size_message"
        static let clipAlertUnsupportedVideoMessage = "amity_clip_alert_unsupported_video_message"
        static let clipAlertTooShortMessage = "amity_clip_alert_too_short_message"
        static let clipAlertDiscardMessage = "amity_clip_alert_discard_message"
        static let clipAlertFailedUploadMessage = "amity_clip_alert_failed_upload_message"
        static let seeLess = "amity_social_see_less"
        
        // Community
        static let cancelRequest = "amity_social_cancel_request"
        static let privateCommunityTitle = "amity_social_private_community_title"
        static let privateCommunityDescription = "amity_social_private_community_description"
        static let declinePendingPostMessage = "amity_social_decline_pending_post_message"
        static let maxUploadLimitTitle = "amity_social_max_upload_limit_title"
        static let maxUploadLimitMessage = "amity_social_max_upload_limit_message"
        static let noPostToReview = "amity_social_no_post_to_review"
        static let addCategory = "amity_social_add_category"
        static let addMember = "amity_social_add_member"
        static let startSearchHint = "amity_social_start_search_hint"
        static let noCommunityYet = "amity_social_no_community_yet"
        static let noCommunityYetDescription = "amity_social_no_community_yet_description"
        static let categoriesLabel = "amity_social_categories_label"
        
        // Invitation
        static let declineInvitationTitle = "amity_social_decline_invitation_title"
        static let declineInvitationMessage = "amity_social_decline_invitation_message"
        
        // Content Report
        static let reportThanksTitle = "amity_social_report_thanks_title"
        static let reportThanksMessage = "amity_social_report_thanks_message"
        
        // Error/Banned
        static let contentUnavailable = "amity_social_content_unavailable"
        static let bannedTitle = "amity_social_banned_title"
        static let bannedMessage = "amity_social_banned_message"
        static let postTextExceedErrorMessage = "amity_social_error_post_text_exceed_error_message"
        static let postBanWordErrorMessage = "amity_social_error_post_ban_word_error_message"
        static let postLinkNotAllowedErrorMessage = "amity_social_error_post_link_not_allowed_error_message"
        static let noDescriptionAvailable = "amity_social_label_no_description_available"
        
        // User Profile
        static let noRequestsToReview = "amity_social_no_requests_to_review"
        static let declineFollowRequestMessage = "amity_social_decline_follow_request_message"
        static let manageBlockedUsers = "amity_social_manage_blocked_users"
        static let reportUser = "amity_social_report_user"
        static let unreportUser = "amity_social_unreport_user"
        static let blockUser = "amity_social_block_user"
        static let unblockUser = "amity_social_unblock_user"
        static let editProfile = "amity_social_edit_profile"
        static let displayName = "social_label_edit_user_display_name_title"
        static let editPost = "amity_social_edit_post"
        
        // Products/Poll
        static let tagProducts = "amity_social_tag_products"
        static let productsTagged = "amity_social_products_tagged"
        static let productsTaggedInPost = "amity_social_products_tagged_in_post"
        static let productsTaggedInPhoto = "amity_social_products_tagged_in_photo"
        static let productsTaggedInVideo = "amity_social_products_tagged_in_video"
        static let addOption = "amity_social_button_add_option"
        static let uploadImage = "amity_social_upload_image"
        static let uploadNewImage = "amity_social_upload_new_image"
        static let imageUploadFailed = "amity_social_image_upload_failed"
        static let optionN = "amity_social_option_n"
        static let choosePollType = "amity_social_choose_poll_type"
        static let pollTypeTextOnly = "amity_social_poll_type_text_only"
        static let pollTypeImage = "amity_social_poll_type_image"
        static let startTypingToSearch = "amity_social_start_typing_to_search"
        static let searchByProductName = "amity_social_search_by_product_name"
        static let editTags = "amity_social_edit_tags"
        static let alreadyTagged = "amity_social_already_tagged"
        
        // Post/LiveStream
        static let liveOn = "amity_social_live_on"
        static let livestreamLimitedVisibility = "amity_social_livestream_limited_visibility"
        static let livestreamJoinToInteract = "amity_social_livestream_join_to_interact"
        static let videoNoLongerAvailable = "amity_social_video_no_longer_available"
        static let photoNoLongerAvailable = "amity_social_photo_no_longer_available"
        static let videoNotAvailable = "amity_social_video_not_available"
        
        // Event
        static let eventPlatform = "amity_social_event_platform"
        static let eventPlatformLivestream = "amity_social_event_platform_livestream"
        static let eventPlatformExternal = "amity_social_event_platform_external"
        static let eventPlatformLivestreamDescription = "amity_social_label_event_platform_livestream_description"
        static let eventPlatformExternalDescription = "amity_social_label_event_platform_external_description"
        static let eventDateToday = "amity_social_time_event_date_today"
        static let eventDateTomorrow = "amity_social_label_event_date_tomorrow"
        static let eventDateYesterday = "amity_social_time_event_date_yesterday"
        static let eventDateTimeFormat = "amity_social_event_date_time_format"

        // Post actions
        static let postCommentButtonText = "post_comment_button_text"
        static let postCommentCountSingular = "post_comment_count_singular"
        static let postCommentCountPlural = "post_comment_count_plural"
        static let postViewRepliesSingular = "post_view_replies_singular"
        static let postViewRepliesPlural = "post_view_replies_plural"

        // Navigation tabs
        static let socialHomeMyEventTab = "social_home_my_event_tab"
        static let socialSearchPostsTab = "social_search_posts_tab"
        static let socialSearchUsersTab = "social_search_users_tab"
        static let socialCommunityNavTitle = "social_community_nav_title"
        static let socialMediaFeedVideosTab = "social_tab_tab_videos"

        // Buttons
        static let videoButton = "amity_social_video_button"
        static let exploreCommunityButton = "amity_social_explore_community_button"

        // User Profile
        static let userProfileFollowings = "user_profile_followings"
        static let userProfileFollowers = "user_profile_followers"
        static let userProfileFollowingButton = "user_profile_following_button"

        // Community Pending
        static let communityPendingRequestSingular = "community_pending_request_singular"
        static let communityJoinRequestSingular = "community_join_request_singular"
        static let communityJoinRequestPlural = "community_join_request_plural"
        static let communityPendingRequiresApproval = "community_pending_requires_approval"
        static let communityPendingRequireApproval = "community_pending_require_approval"
        static let communityPostsPendingReview = "community_posts_pending_review"

        // Media Feed Tabs
        static let socialMediaFeedPhotosTab = "social_media_feed_photos_tab"

        // Empty Feed States
        static let communityEmptyFeedNoPosts = "amity_social_empty_state_empty_feed_no_posts"
        static let communityEmptyFeedNoPhotos = "community_empty_feed_no_photos"
        static let communityEmptyFeedNoVideos = "community_empty_feed_no_videos"
        static let communityEmptyFeedNoClips = "community_empty_feed_no_clips"

        // Post Menu Types
        static let postMenuTypePoll = "post_menu_type_poll"
        static let postMenuTypeStory = "amity_social_button_social_home_create_story_button"
        static let postMenuTypeClip = "post_menu_type_clip"
        static let postMenuTypeEvent = "post_menu_type_event"
        static let postMenuTypeLiveStream = "amity_social_status_live_stream"

        // Community Profile Labels (post count)
        static let communityPostLabelSingular = "community_post_label_singular"
        static let communityPostLabelPlural = "community_post_label_plural"

        // Community Profile Menu
        static let communitySettingsOptionTitle = "community_settings_option_title"
        static let communityInformationOptionTitle = "community_information_option_title"

        // Copy/Share Link
        static let socialCopyLink = "amity_social_copy_link"
        static let socialShareTo = "amity_social_share_to"

        // Invite Member
        static let communityInviteMemberTitle = "community_invite_member_title"
        static let communityInviteMemberDescription = "community_invite_member_description"
        static let communityInviteMemberButton = "community_invite_member_button"

        // Search
        static let searchUserPlaceholder = "search_user_placeholder"
        static let searchPlaceholder = "amity_search_placeholder"
        static let searchCommunityUserPlaceholder = "amity_search_community_user_placeholder"
        static let searchMyCommunitiesPlaceholder = "amity_search_my_communities_placeholder"

        // Community Setup
        static let communitySetupPageTitle = "community_setup_page_title"
        static let communitySetupEditPageTitle = "community_setup_edit_page_title"
        static let communitySetupNameTitle = "community_setup_name_title"
        static let communitySetupNamePlaceholder = "community_setup_name_placeholder"
        static let communitySetupAboutTitle = "community_setup_about_title"
        static let communitySetupAboutPlaceholder = "community_setup_about_placeholder"
        static let communitySetupCategoryTitle = "community_setup_category_title"
        static let communitySetupCategoryPlaceholder = "community_setup_category_placeholder"
        static let communitySetupPrivacyTitle = "community_setup_privacy_title"
        static let communitySetupPrivacyPublicTitle = "community_setup_privacy_public_title"
        static let communitySetupPrivacyPublicDescription = "community_setup_privacy_public_description"
        static let communitySetupPrivacyPrivateTitle = "community_setup_privacy_private_title"
        static let communitySetupPrivacyPrivateDescription = "community_setup_privacy_private_description"
        static let communitySetupPrivacyPrivateVisibleTitle = "community_setup_privacy_private_visible_title"
        static let communitySetupPrivacyPrivateVisibleDescription = "community_setup_privacy_private_visible_description"
        static let communitySetupPrivacyPrivateHiddenTitle = "community_setup_privacy_private_hidden_title"
        static let communitySetupPrivacyPrivateHiddenDescription = "community_setup_privacy_private_hidden_description"
        static let communitySetupMembershipTitle = "community_setup_membership_title"
        static let communitySetupMembershipDescription = "community_setup_membership_description"
        static let communitySetupMembershipSubDescription = "community_setup_membership_sub_description"
        static let communitySetupAddMemberTitle = "community_setup_add_member_title"
        static let communitySetupAddMemberButton = "community_setup_add_member_button"
        static let communitySetupCreateButton = "community_setup_create_button"
        static let communitySetupCreateSuccess = "community_setup_create_success"
        static let communitySetupCreateFailed = "community_setup_create_failed"
        static let communitySetupSaveFailed = "community_setup_save_failed"

        // Community Setting
        static let communitySettingPendingInvitations = "community_setting_pending_invitations"
        static let communitySettingLeaveAlertMessage = "social_button_last_moderator_leave_community_msg"
        static let communitySettingLeavingToast = "community_setting_leaving_toast"
        static let communitySettingLeaveSuccess = "community_setting_leave_success"
        static let communitySettingClosingToast = "community_setting_closing_toast"
        static let communitySettingCloseSuccess = "community_setting_close_success"

        // Context-specific Copy Link
        static let socialCopyProfileLink = "amity_social_copy_profile_link"
        static let socialCopyPostLink = "amity_social_label_copy_post_link"
        static let socialCopyClipLink = "amity_social_copy_clip_link"
        static let socialCopyLivestreamLink = "amity_social_copy_livestream_link"

        // Search
        static let searchMemberPlaceholder = "search_member_placeholder"

        // User Profile - Toast Messages
        static let userBlockedToast = "user_blocked_toast"
        static let userUnblockedToast = "user_unblocked_toast"
        static let userReportedToast = "user_reported_toast"
        static let userUnreportedToast = "user_unreported_toast"
        static let userBlockFailedToast = "user_block_failed_toast"
        static let userUnblockFailedToast = "user_unblock_failed_toast"
        static let userReportFailedToast = "user_report_failed_toast"
        static let userUnreportFailedToast = "user_unreport_failed_toast"
        static let followRequestDeclinedToast = "follow_request_declined_toast"
        static let followRequestAcceptFailedToast = "follow_request_accept_failed_toast"
        static let followRequestDeclineFailedToast = "follow_request_decline_failed_toast"

        // User Profile - Alert
        static let unblockUserAlertTitle = "social_label_user_unblock_title"
        static let unblockUserAlertMessage = "unblock_user_alert_message"
        static let unableToFollowAlertTitle = "unable_to_follow_alert_title"
        static let unableToFollowAlertMessage = "unable_to_follow_alert_message"

        // Edit User Profile
        static let editUserAboutTitle = "edit_user_about_title"

        // Community Member Management - Toast
        static let communityProfileUpdateFailedToast = "community_profile_update_failed_toast"
        static let communityMemberRemovedToast = "community_member_removed_toast"
        static let communityMemberRemoveLoadingToast = "community_member_remove_loading_toast"
        static let communityMemberAddLoadingToast = "community_member_add_loading_toast"
        static let communityMemberReportedToast = "community_member_reported_toast"
        static let communityMemberUnreportedToast = "community_member_unreported_toast"
        static let communityMemberReportFailedToast = "community_member_report_failed_toast"
        static let communityMemberUnreportFailedToast = "community_member_unreport_failed_toast"
        static let communityMemberRemoveFailedToast = "community_member_remove_failed_toast"
        static let communityMemberPromoteSuccessToast = "community_member_promote_success_toast"
        static let communityMemberPromoteFailedToast = "community_member_promote_failed_toast"
        static let communityMemberDemoteSuccessToast = "community_member_demote_success_toast"
        static let communityMemberDemoteFailedToast = "community_member_demote_failed_toast"
        static let communityMemberPromoteToModerator = "community_member_promote_to_moderator"
        static let communityMemberDemoteToMember = "community_member_demote_to_member"
        static let communityJoinFailedToast = "amity_social_toast_snackbar_join_community_failed"
        static let communityJoinRequestNoLongerAvailableToast = "community_join_request_no_longer_available_toast"
        static let communityJoinCancelRequestFailedToast = "community_join_cancel_request_failed_toast"
        static let communityUnjoinedToast = "community_unjoined_toast"
        static let postReviewFailedToast = "post_review_failed_toast"

        // Community Notification Settings - Alert
        static let communityNotificationLeaveAlertMessage = "community_notification_leave_alert_message"

        // Post Composer - Alert
        static let postComposerHashtagLimitAlertTitle = "post_composer_hashtag_limit_alert_title"
        static let postComposerHashtagLimitAlertMessage = "post_composer_hashtag_limit_alert_message"
        static let postComposerLinkLimitAlertTitle = "post_composer_link_limit_alert_title"
        static let postComposerLinkLimitAlertMessage = "post_composer_link_limit_alert_message"
        static let postComposerProductsUnavailableToast = "post_composer_products_unavailable_toast"

        // Poll
        static let postSentForReviewAlertTitle = "post_sent_for_review_alert_title"
        static let postSentForReviewAlertMessage = "post_sent_for_review_alert_message"
        static let postComposerLoadingUpdating = "amity_post_composer_loading_updating"
        static let postComposerTitlePlaceholder = "amity_post_composer_title_placeholder"
        static let postComposerBodyPlaceholder = "amity_post_composer_body_placeholder"
        static let postComposerBodyClipPlaceholder = "amity_post_composer_body_clip_placeholder"
        static let postComposerPostsSentForReviewTitle = "amity_post_composer_posts_sent_for_review_title"
        static let postComposerPostUpdatesSentForReviewTitle = "amity_post_composer_post_updates_sent_for_review_title"
        static let postComposerPostSentForReviewMessage = "amity_post_composer_post_sent_for_review_message"
        static let postComposerPostUpdateSentForReviewMessage = "amity_post_composer_post_update_sent_for_review_message"
        static let pollEndedToast = "poll_ended_toast"
        static let pollPostUnavailableToast = "poll_post_unavailable_toast"
        static let pollGenericErrorToast = "poll_generic_error_toast"
        static let pollVoteRemovedToast = "poll_vote_removed_toast"

        // Notification Tray
        static let notificationTrayGenericErrorToast = "notification_tray_generic_error_toast"
        static let notificationTrayInvitationDeclinedToast = "amity_social_toast_snackbar_invitation_declined"

        // Story
        static let storyLinkLimitToast = "story_link_limit_toast"

        // LiveStream - Toast
        static let livestreamCoHostAcceptedToast = "livestream_co_host_accepted_toast"
        static let livestreamCoHostDeclinedToast = "livestream_co_host_declined_toast"
        static let livestreamCoHostLeftToast = "livestream_co_host_left_toast"
        static let livestreamCoHostLeftStageToast = "livestream_co_host_left_stage_toast"
        static let livestreamCoHostRemovedToast = "livestream_co_host_removed_toast"
        static let livestreamRemoveCoHostFailedToast = "livestream_remove_co_host_failed_toast"
        static let livestreamFollowToInteractToast = "livestream_follow_to_interact_toast"
        static let joinCommunityToast = "common_label_join_community_to_interact"
        static let livestreamWaitingNetworkToast = "livestream_waiting_network_toast"

        // Story
        static let storyTargetDefaultName = "amity_social_button_story"

         // LiveStream - Display Fallbacks


        // Media
        static let mediaProcessing = "amity_media_processing"

        // Event Date Picker
        static let eventStartsOn = "amity_event_starts_on"
        static let eventLocationAddressTitle = "amity_event_location_address_title"
        static let eventLocationAddressPlaceholder = "amity_event_location_address_placeholder"
        static let eventLocationTitle = "amity_event_location_title"

        // LiveStream Permissions - Photos
        static let livestreamPermissionPhotosTitle = "amity_livestream_permission_photos_title"
        static let livestreamPermissionPhotosMessage = "amity_livestream_permission_photos_message"

        // LiveStream Co-Host Product Tags
        static let livestreamCoHostProductTagsTitle = "amity_livestream_cohost_product_tags_title"
        static let livestreamCoHostProductTagsDescription = "amity_livestream_cohost_product_tags_description"

        // User Profile - Block/Unblock/Unfollow Alerts
        static let userUnblockTitle = "amity_user_unblock_title"
        static let userUnblockMessageFormat = "amity_user_unblock_message_format"
        static let userUnfollowTitle = "amity_user_unfollow_title"
        static let userUnfollowMessage = "amity_user_unfollow_message"
        static let userUnfollowButton = "amity_user_unfollow_button"
        static let userBlockTitle = "amity_user_block_title"
        static let userBlockMessageFormat = "amity_user_block_message_format"

        // Community Pending Invitations
        static let communityPendingInvitationsTitle = "amity_community_pending_invitations_title"
        static let communityInvitationJoinedFormat = "amity_community_invitation_joined_format"
        static let communityInvitationExpired = "amity_community_invitation_expired"
        static let communityInvitationDeclined = "amity_social_toast_snackbar_invitation_declined"

        // Notification Tray Sections
        static let notificationTrayRequestsTitle = "amity_notification_tray_requests_title"
        static let notificationTrayRecentTitle = "amity_notification_tray_recent_title"
        static let notificationTrayOlderTitle = "amity_notification_tray_older_title"
        static let notificationTrayDeclineFailed = "amity_notification_tray_decline_failed"
        static let notificationTrayAcceptInvitationFailed = "amity_notification_tray_accept_invitation_failed"
        static let notificationTrayInvitedToJoinFormat = "amity_notification_tray_invited_to_join_format"
        static let notificationTrayInvitedToJoinSeparator = "amity_notification_tray_invited_to_join_separator"

        // Poll Image Options
        static let pollImageOptionsTitle = "amity_poll_image_options_title"
        static let pollImageOptionsDescription = "amity_poll_image_options_description"

        // User Profile Edit Fields
        static let userProfileAboutTitle = "amity_user_profile_about_title"
        static let userProfileAboutPlaceholder = "amity_user_profile_about_placeholder"
        static let userFollowRequestsTitleFormat = "amity_user_follow_requests_title_format"
        
        // MARK: - Master keys (aligned with DLS)
        static let addLink = "amity_social_button_add_link"
        static let addProducts = "amity_social_button_add_products"
         static let block = "amity_social_button_block"
         static let by = "amity_social_button_by"
        static let community = "amity_social_button_community"
        static let communityAnd = "amity_social_button_community_and"
        static let deleteCommentWarningMessage = "amity_social_button_delete_comment_warning_message"
        static let deleteMessageFailed = "amity_social_button_delete_message_failed"
        static let deletePostWarningMessage = "amity_social_button_delete_post_warning_message"
        static let discard = "amity_social_button_discard"
        static let editUserSaveButton = "amity_social_button_edit_user_save_button"
        static let eventProgressNotSaved = "amity_social_button_event_progress_not_saved"
        static let image = "amity_social_button_image"
        static let joinGroup = "amity_social_button_join_group"
        static let leave = "amity_social_button_leave"
        static let myTimeline = "amity_social_button_my_timeline"
        static let pendingInvitation = "amity_social_button_pending_invitation"
        static let pendingPostDeclineButton = "amity_social_button_pending_post_decline_button"
        static let pollDuration1Day = "amity_social_button_poll_duration_1_day"
        static let pollDuration14Days = "amity_social_button_poll_duration_14_days"
        static let pollDuration3Days = "amity_social_button_poll_duration_3_days"
        static let pollDuration30Days = "amity_social_button_poll_duration_30_days"
        static let pollDuration7Days = "amity_social_button_poll_duration_7_days"
        static let pollVoter = "amity_social_button_poll_voter"
        static let pollVoters = "amity_social_button_poll_voters"
        static let postComposerFileButton = "amity_social_button_post_composer_file_button"
        static let postContentShareButton = "amity_social_button_post_content_share_button"
        static let postTo = "amity_social_button_post_to"
        static let selectEventTargetMyTimeline = "amity_social_button_select_event_target_my_timeline"
        static let selectPollTargetMyTimeline = "amity_social_button_select_poll_target_my_timeline"
        static let unblock = "amity_social_button_unblock"
        static let userFollowButton = "amity_social_button_user_follow_button"
        static let userFollowingButton = "amity_social_button_user_following_button"
        static let userProfileFollower = "amity_social_button_user_profile_follower"
        static let userProfileFollowing = "amity_social_button_user_profile_following"
        static let v3Loadmore = "amity_social_button_v3_loadmore"
        static let stateExploreEmpty = "amity_social_empty_state_explore_empty"
        static let closeCommunityErrorTitle = "amity_social_error_close_community_error_title"
        static let blockedUserFeed = "amity_social_label_blocked_user_feed"
        static let blockedUserFeedInfo = "amity_social_label_blocked_user_feed_info"
        static let blockedUserImageFeed = "amity_social_label_blocked_user_image_feed"
        static let blockedUserImageFeedInfo = "amity_social_label_blocked_user_image_feed_info"
        static let blockedUserVideoFeed = "amity_social_label_blocked_user_video_feed"
        static let blockedUserVideoFeedInfo = "amity_social_label_blocked_user_video_feed_info"
        static let communitySetupInviteMembersDescription = "amity_social_label_community_setup_invite_members_description"
        static let communitySetupInviteMembersTitle = "amity_social_label_community_setup_invite_members_title"
        static let customizeLinkText = "amity_social_label_customize_link_text"
        static let hyperlinkUrlLabel = "amity_social_label_hyperlink_url"
        static let hyperlinkCustomizeInfo = "amity_social_label_hyperlink_customize_info"
        static let enterValidUrl = "amity_social_label_enter_valid_url"
        static let enterWhitelistedUrl = "amity_social_label_enter_whitelisted_url"
        static let followRequestAccepted = "amity_social_label_follow_request_accepted"
        static let joinToAttendEvents = "amity_social_label_join_to_attend_events"
        static let msgBlockedWord = "amity_social_label_msg_blocked_word"
        static let noInternetConnection = "amity_social_label_no_internet_connection"
        static let noUsersAvailable = "amity_social_label_no_users_available"
        static let oopsSomethingWentWrong = "social_toast_failed_generic"
        static let privateUserFeed = "amity_social_label_private_user_feed"
        static let privateUserFeedInfo = "amity_social_label_private_user_feed_info"
        static let privateUserImageFeed = "amity_social_label_private_user_image_feed"
        static let privateUserImageFeedInfo = "amity_social_label_private_user_image_feed_info"
        static let privateUserVideoFeed = "amity_social_label_private_user_video_feed"
        static let privateUserVideoFeedInfo = "amity_social_label_private_user_video_feed_info"
        static let selectEventTargetTitle = "amity_social_label_select_event_target_title"

        static let textContainsBlocklisted = "amity_social_label_text_contains_blocklisted"
        static let yourMessageIsTooLongPleaseShortenYourMessageAn = "amity_social_label_your_message_is_too_long_please_shorten_your_message_an"
        static let dialogCohostInvitationDescription = "amity_social_modal_dialog_cohost_invitation_description"
        static let dialogSomethingWentWrong = "amity_social_modal_dialog_something_went_wrong"
        static let postPermissionAdminReview = "amity_social_permission_post_permission_admin_review"
        static let editUserAboutHint = "amity_social_placeholder_edit_user_about_hint"
        static let hyperlinkNameHint = "amity_social_placeholder_hyperlink_name_hint"
        static let hyperlinkUrlHint = "amity_social_placeholder_hyperlink_url_hint"
        static let communityReportFailed = "amity_social_toast_community_report_failed"
        static let communitySetupToastCreateFailed = "amity_social_toast_community_setup_toast_create_failed"
        static let communityUnreportFailed = "amity_social_toast_community_unreport_failed"
        static let leaveCommunityFailed = "amity_social_toast_leave_community_failed"
        static let memberUnbanFailed = "amity_social_toast_member_unban_failed"
        static let productTagAddFailed = "amity_social_toast_product_tag_add_failed"
        static let productTagRemoveFailed = "amity_social_toast_product_tag_remove_failed"
        static let snackbarCloseCommunityFailed = "amity_social_toast_snackbar_close_community_failed"
        static let snackbarStoryShared = "amity_social_toast_snackbar_story_shared"
        static let updateCohostPermissionFailed = "amity_social_toast_update_cohost_permission_failed"
        static let acceptInvite = "amity_social_button_accept_invite"
        
        // Visitor Usage Limit
        static let visitorUsageLimitTitle = "amity_social_visitor_limit_title"
        static let visitorUsageLimitSubtitle = "amity_social_visitor_limit_subtitle"
        static let visitorUsageLimitSignIn = "amity_social_visitor_limit_sign_in"
        static let visitorUsageLimitToast = "amity_social_visitor_limit_toast"
    }
}
