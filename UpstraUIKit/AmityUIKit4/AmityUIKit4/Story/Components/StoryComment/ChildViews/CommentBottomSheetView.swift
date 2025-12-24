//
//  CommentBottomSheetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/20/24.
//

import SwiftUI

struct CommentBottomSheetView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: CommentBottomSheetViewModel
    
    let editAction: ((AmityCommentModel?) -> Void)?
    let reportAction: (AmityCommentModel?) -> Void
    
    init(viewModel: CommentBottomSheetViewModel, editingComment: ((AmityCommentModel?) -> Void)? = nil, reportAction: @escaping (AmityCommentModel?) -> Void) {
        self.viewModel = viewModel
        self.editAction = editingComment
        self.reportAction = reportAction
    }

    var body: some View {
        if let comment = viewModel.sheetState.comment, comment.isOwner {
            getOwnerBottomSheetView()
        } else {
            getNonOwnerBottomSheetView()
                .onAppear {
                    if let comment = viewModel.sheetState.comment {
                        viewModel.updateCommentFlaggedByMeState(id: comment.id)
                    }
                }
        }
    }
    
    @ViewBuilder
    private func getOwnerBottomSheetView() -> some View {
        VStack {
            let isReply = viewModel.sheetState.comment?.parentId != nil
            let editTitle = isReply ? "Edit reply" : AmityLocalizedStringSet.Comment.editCommentBottomSheetTitle.localizedString
            BottomSheetItemView(icon: AmityIcon.editCommentIcon.imageResource, text: editTitle)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.editCommentButton)
                .onTapGesture {
                    editAction?(viewModel.sheetState.comment)
                    viewModel.sheetState.isShown.toggle()
                }
                        
            let deleteTitle = isReply ? "Delete reply" : AmityLocalizedStringSet.Comment.deleteCommentBottomSheetTitle.localizedString
            BottomSheetItemView(icon: AmityIcon.trashBinIcon.imageResource, text: deleteTitle, isDestructive: true)
                .onTapGesture {
                    viewModel.isAlertShown.toggle()
                }
                .alert(isPresented: $viewModel.isAlertShown, content: {
                    let isReply = viewModel.sheetState.comment?.parentId != nil
                    
                    let alertTitle = isReply ? "Delete reply" : AmityLocalizedStringSet.Comment.deleteCommentTitle.localizedString
                    let alertMessage = isReply ? "This reply will be permanently deleted." : AmityLocalizedStringSet.Comment.deleteCommentMessage.localizedString

                    return Alert(title: Text(alertTitle), message: Text(alertMessage), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                        Task {
                            viewModel.sheetState.isShown.toggle()
                            if let comment = viewModel.sheetState.comment {
                                try await viewModel.deleteComment(id: comment.commentId)
                            }
                            viewModel.sheetState.comment = nil
                        }
                    }))
                })
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.deleteCommentButton)

            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    
    @ViewBuilder
    func getNonOwnerBottomSheetView() -> some View {
        VStack {
            let isReply = viewModel.sheetState.comment?.parentId != nil
            
            let reportTitle = isReply ? AmityLocalizedStringSet.Comment.reportReplyBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.reportCommentBottomSheetTitle.localizedString
            let unreportTitle = isReply ? AmityLocalizedStringSet.Comment.unReportReplyBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.unReportCommentBottomSheetTitle.localizedString
            
            BottomSheetItemView(icon: viewModel.isCommentFlaggedByMe ? AmityIcon.unflagIcon.imageResource : AmityIcon.flagIcon.imageResource, text: viewModel.isCommentFlaggedByMe ? unreportTitle : reportTitle)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.reportCommentButton)
                .onTapGesture {
                    guard let comment = viewModel.sheetState.comment else {
                        viewModel.sheetState.isShown.toggle()
                        return
                    }
                    
                    if viewModel.isCommentFlaggedByMe {
                        Task { @MainActor in
                            do {
                                try await viewModel.unflagComment(id: comment.id)
                                
                                viewModel.updateCommentFlaggedByMeState(id: comment.id)
                                let reportMessage = isReply ? AmityLocalizedStringSet.Comment.replyReportedMessage.localizedString : AmityLocalizedStringSet.Comment.commentReportedMessage.localizedString
                                let unReportMessage = isReply ? AmityLocalizedStringSet.Comment.replyUnReportedMessage.localizedString : AmityLocalizedStringSet.Comment.commentUnReportedMessage.localizedString
                                
                                Toast.showToast(style: .success, message: viewModel.isCommentFlaggedByMe ? unReportMessage : reportMessage)
                            } catch {
                                Toast.showToast(style: .warning, message: error.localizedDescription)
                            }
                        }
                        viewModel.sheetState.isShown.toggle()
                    } else {
                        reportAction(comment)
                        // Dismiss
                        viewModel.sheetState.isShown.toggle()
                    }
                }

            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
}


class CommentBottomSheetViewModel: ObservableObject {
    @Published var sheetState: (isShown: Bool, comment: AmityCommentModel?) = (false, nil)
    @Published var isAlertShown: Bool = false
    @Published var isCommentFlaggedByMe: Bool = false
    
    private let commentManager = CommentManager()
    
    @MainActor
    func deleteComment(id: String) async throws {
        try await commentManager.deleteComment(withId: id)
    }
    
    @MainActor
    func flagComment(id: String) async throws {
        try await commentManager.flagComment(withId: id)
    }
    
    @MainActor
    func unflagComment(id: String) async throws {
        try await commentManager.unflagComment(withId: id)
    }
    
    func updateCommentFlaggedByMeState(id: String) {
        Task { @MainActor in
            isCommentFlaggedByMe = try await commentManager.isCommentFlaggedByMe(withId: id)
        }
    }
}

