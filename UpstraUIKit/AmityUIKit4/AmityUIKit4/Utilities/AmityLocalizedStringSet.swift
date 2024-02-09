//
//  AmityLocalizedStringSet.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import Foundation

public struct AmityLocalizedStringSet {
    private init() { }
    
    public enum General {
        static let delete = "delete"
        static let cancel = "cancel"
        static let save = "save"
        static let discard = "discard"
        static let anonymous = "general_anonymous"
    }
    
    public enum Story {
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
    
    public enum Comment {
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
    }
}
