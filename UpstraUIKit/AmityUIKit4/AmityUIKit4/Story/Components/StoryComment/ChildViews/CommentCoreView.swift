//
//  CommentCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import SwiftUI
import AmitySDK

struct CommentCoreView: View {
    private let commentButtonAction: AmityCommentButtonAction
    @ObservedObject private var viewModel: CommentCoreViewModel
    let hideCommentButtons: Bool
    
    init(commentButtonAction: @escaping AmityCommentButtonAction, hideCommentButtons: Bool = false, viewModel: CommentCoreViewModel) {
        self.commentButtonAction = commentButtonAction
        self.viewModel = viewModel
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        CommentListView(viewModel.commentCollection, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
            .environmentObject(viewModel)
    }
}


class CommentCoreViewModel: ObservableObject {
    @Published var commentCollection: AmityCollection<AmityComment>
    @Published var editingComment: AmityCommentModel?
    
    private let commentManager = CommentManager()
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    
    init(referenceId: String, referenceType: AmityCommentReferenceType) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        commentCollection = commentManager.getComments(queryOptions: queryOptions)
    }
    
    func getChildComments(parentId: String) -> AmityCollection<AmityComment> {
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    parentId: parentId,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        return commentManager.getComments(queryOptions: queryOptions)
    }
    
    @MainActor
    func editComment(comment: AmityCommentModel) async throws {
        let updateOptions = AmityCommentUpdateOptions(text: comment.text, metadata: comment.metadata, mentioneesBuilder: comment.mentioneeBuilder)
        try await commentManager.editComment(withId: comment.id, options: updateOptions)
    }
    
}
