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
        if let comment = viewModel.sheetState.comment {
            if comment.isOwner {
                getOwnerBottomSheetView()
            } else {
                getNonOwnerBottomSheetView()
                    .onAppear {
                        viewModel.updateCommentFlaggedByMeState(id: comment.id)
                    }
            }
        }
    }
    
    // MARK: - Shared Delete Button
    
    @ViewBuilder
    private func deleteCommentButton(isReply: Bool) -> some View {
        let deleteTitle = isReply ? AmityLocalizedStringSet.Comment.deleteReplyBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.deleteCommentBottomSheetTitle.localizedString
        BottomSheetItemView(icon: AmityIcon.trashBinIcon.imageResource, text: deleteTitle, isDestructive: true)
            .onTapGesture {
                viewModel.isAlertShown.toggle()
            }
            .alert(isPresented: $viewModel.isAlertShown, content: {
                let alertTitle = isReply ? AmityLocalizedStringSet.Comment.deleteReplyTitle.localizedString : AmityLocalizedStringSet.Comment.deleteCommentTitle.localizedString
                let alertMessage = isReply ? AmityLocalizedStringSet.Comment.deleteReplyMessage.localizedString : AmityLocalizedStringSet.Comment.deleteCommentMessage.localizedString

                return Alert(title: Text(alertTitle), message: Text(alertMessage), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                    Task { @MainActor in
                        viewModel.sheetState.isShown.toggle()
                        if let comment = viewModel.sheetState.comment {
                            do {
                                try await viewModel.deleteComment(id: comment.commentId)
                                viewModel.sheetState.comment = nil
                            } catch {
                                Toast.showToast(style: .warning, message: error.localizedDescription)
                            }
                        }
                    }
                }))
            })
            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.deleteCommentButton)
    }
    
    @ViewBuilder
    private func getOwnerBottomSheetView() -> some View {
        VStack {
            let isReply = viewModel.sheetState.comment?.parentId != nil
            let editTitle = isReply ? AmityLocalizedStringSet.Comment.editReplyBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.editCommentBottomSheetTitle.localizedString
            BottomSheetItemView(icon: AmityIcon.editCommentIcon.imageResource, text: editTitle)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.editCommentButton)
                .onTapGesture {
                    editAction?(viewModel.sheetState.comment)
                    viewModel.sheetState.isShown.toggle()
                }
                        
            deleteCommentButton(isReply: isReply)

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

            if viewModel.hasDeletePermission {
                deleteCommentButton(isReply: isReply)
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
    @Published var hasDeletePermission: Bool = false
    
    private let commentManager = CommentManager()
    
    func checkDeletePermission(communityId: String?) {
        guard let communityId = communityId else { return }
        Task { @MainActor in
            hasDeletePermission = await CommunityPermissionChecker.hasDeleteCommunityCommentPermission(communityId: communityId)
        }
    }
    
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

