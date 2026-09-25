//
//  AmityContentReportPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 29/4/25.
//

import SwiftUI
import AmitySDK

enum ContentReportSubmissionState {
    case none
    case submitting
    case success
    case contentError
    case error
}

enum ContentReportType {
    case message(id: String)
    case post(id: String)
    case comment(id: String, isReply: Bool)
    
    var description: String {
        switch self {
        case .message:
            return AmityLocalizedStringSet.Social.reportReasonContentTypeMessage.localizedString
        case .post:
            return AmityLocalizedStringSet.Social.reportReasonContentTypePost.localizedString
        case .comment(_, let isReply):
            return isReply
                ? AmityLocalizedStringSet.Social.reportReasonContentTypeReply.localizedString
                : AmityLocalizedStringSet.Social.reportReasonContentTypeComment.localizedString
        }
    }
}

class AmityContentReportPageViewModel: ObservableObject {
    
    private let postManager = PostManager()
    private let commentManager = CommentManager()
    private let chatManager = ChatManager()
    
    let type: ContentReportType

    /// Height of the bottom bar under the report sheet, so the toast lands above it once this page is
    /// dismissed. `nil` when the underlying screen has no bottom bar (standard placement).
    let bottomBarHeight: CGFloat?

    @Published var selectedReason: AmityContentFlagReason?
    @Published var submissionState: ContentReportSubmissionState = .none

    init(type: ContentReportType, bottomBarHeight: CGFloat? = nil) {
        self.type = type
        self.bottomBarHeight = bottomBarHeight
    }

    /// Shows the report result toast above the bottom bar when a height was provided, else with the
    /// standard placement.
    func showResultToast(style: ToastStyle, message: String) {
        if let bottomBarHeight = bottomBarHeight {
            Toast.showToast(style: style, message: message, aboveBottomBarHeight: bottomBarHeight)
        } else {
            Toast.showToast(style: style, message: message)
        }
    }
    
    @MainActor
    func flagContent(reason: AmityContentFlagReason) async throws {
        self.submissionState = .submitting
        
        do {
            switch type {
            case .message(id: let id):
                try await chatManager.flagMessage(messageId: id, reason: reason)
                MessageCache.shared.setFlagStatus(messageId: id, value: true)
            case .post(let id):
                try await postManager.flagPost(withId: id, reason: reason)
            case .comment(let id, let isReply):
                try await commentManager.flagComment(withId: id, reason: reason)
            }
            
            self.submissionState = .success
        } catch let error {
            if error.isAmityErrorCode(.itemNotFound) {
                self.submissionState = .contentError
            } else {
                self.submissionState = .error
                
                let errorMessage = AmityLocalizedStringSet.Social.reportReasonErrorToastMessage.localized(arguments: type.description)
                showResultToast(style: .warning, message: errorMessage)
            }
        }
    }
    
}
