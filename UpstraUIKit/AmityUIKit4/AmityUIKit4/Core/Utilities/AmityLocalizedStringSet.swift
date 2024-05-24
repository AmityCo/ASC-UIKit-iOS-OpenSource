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
        static let anonymous = "general_anonymous"
        static let permissionRequired = "permission_required"
        static let cameraAccessDenied = "camera_access_denied"
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
}
