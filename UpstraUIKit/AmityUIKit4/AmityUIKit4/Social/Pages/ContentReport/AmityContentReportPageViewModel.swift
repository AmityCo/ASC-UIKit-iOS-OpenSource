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
    case comment(id: String)
    
    var description: String {
        switch self {
        case .message:
            return "message"
        case .post:
            return "post"
        case .comment:
            return "comment"
        }
    }
}

class AmityContentReportPageViewModel: ObservableObject {
    
    private let postManager = PostManager()
    private let commentManager = CommentManager()
    private let chatManager = ChatManager()
    
    let type: ContentReportType
   
    @Published var selectedReason: AmityContentFlagReason?
    @Published var submissionState: ContentReportSubmissionState = .none
    
    init(type: ContentReportType) {
        self.type = type
    }
    
    @MainActor
    func flagContent(reason: AmityContentFlagReason) async throws {
        self.submissionState = .submitting
        
        do {
            switch type {
            case .message(id: let id):
                try await chatManager.flagMessage(messageId: id, reason: reason)
            case .post(let id):
                try await postManager.flagPost(withId: id, reason: reason)
            case .comment(let id):
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
