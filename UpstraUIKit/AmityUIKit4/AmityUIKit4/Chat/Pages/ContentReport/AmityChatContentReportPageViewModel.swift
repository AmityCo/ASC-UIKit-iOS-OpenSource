//
//  AmityChatContentReportPageViewModel.swift
//  AmityUIKit4
//
//  Chat-prefixed clone of AmityContentReportPageViewModel, rebuilt for the
//  design-system report flow. See docs/superpowers/specs/2026-07-14-chat-content-report-clone-design.md
//

import SwiftUI
import AmitySDK

enum ChatContentReportSubmissionState {
    case none
    case submitting
    case success
    case contentError
    case error
}

enum ChatContentReportType {
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

class AmityChatContentReportPageViewModel: ObservableObject {

    private let postManager = PostManager()
    private let commentManager = CommentManager()
    private let chatManager = ChatManager()

    let type: ChatContentReportType

    @Published var selectedReason: AmityContentFlagReason?
    @Published var submissionState: ChatContentReportSubmissionState = .none

    init(type: ChatContentReportType) {
        self.type = type
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
            case .comment(let id, _):
                try await commentManager.flagComment(withId: id, reason: reason)
            }

            self.submissionState = .success
        } catch let error {
            if error.isAmityErrorCode(.itemNotFound) {
                self.submissionState = .contentError
            } else {
                self.submissionState = .error

                let errorMessage = AmityLocalizedStringSet.Social.reportReasonErrorToastMessage.localized(arguments: type.description)
                Toast.showToast(style: .warning, message: errorMessage)
            }
        }
    }
}
