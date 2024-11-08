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
    
    let editingComment: ((AmityCommentModel?) -> Void)?
    
    init(viewModel: CommentBottomSheetViewModel, editingComment: ((AmityCommentModel?) -> Void)? = nil) {
        self.viewModel = viewModel
        self.editingComment = editingComment
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
            HStack(spacing: 12) {
                Image(AmityIcon.editCommentIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Button {
                    editingComment?(viewModel.sheetState.comment)
                    viewModel.sheetState.isShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.editCommentBottomSheetTitle.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.editCommentButton)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            
            HStack(spacing: 12) {
                Image(AmityIcon.trashBinIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Button {
                    viewModel.isAlertShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.deleteCommentBottomSheetTitle.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                }
                .buttonStyle(.plain)
                .alert(isPresented: $viewModel.isAlertShown, content: {
                    Alert(title: Text(AmityLocalizedStringSet.Comment.deleteCommentTitle.localizedString), message: Text(AmityLocalizedStringSet.Comment.deleteCommentMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
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
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    
    @ViewBuilder
    func getNonOwnerBottomSheetView() -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(AmityIcon.flagIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Button {
                    guard let comment = viewModel.sheetState.comment else {
                        viewModel.sheetState.isShown.toggle()
                        return
                    }
                    
                    Task { @MainActor in
                        do {
                            if viewModel.isCommentFlaggedByMe {
                                try await viewModel.unflagComment(id: comment.id)
                            } else {
                                try await viewModel.flagComment(id: comment.id)
                            }
                            
                            viewModel.updateCommentFlaggedByMeState(id: comment.id)
                            
                            Toast.showToast(style: .success, message: viewModel.isCommentFlaggedByMe ? AmityLocalizedStringSet.Comment.commentUnReportedMessage.localizedString : AmityLocalizedStringSet.Comment.commentReportedMessage.localizedString)
                        } catch {
                            Toast.showToast(style: .warning, message: error.localizedDescription)
                        }
                    }
                    viewModel.sheetState.isShown.toggle()
                } label: {
                    Text(viewModel.isCommentFlaggedByMe ? AmityLocalizedStringSet.Comment.unReportCommentBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.reportCommentBottomSheetTitle.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.reportCommentButton)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            
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

