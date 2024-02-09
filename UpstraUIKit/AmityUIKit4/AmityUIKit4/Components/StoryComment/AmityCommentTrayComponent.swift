//
//  AmityCommentTrayComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/29/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommentTrayComponent: View {
    @State private var text: String = ""
    @StateObject private var viewModel: AmityCommentTrayComponentViewModel = AmityCommentTrayComponentViewModel()
    @State private var replyState: (showToReply: Bool, comment: AmityCommentModel?) = (false, nil)
    @State private var bottomSheetState: (isShown: Bool, comment: AmityCommentModel?) = (false, nil)
    @State private var isAlertShown: Bool = false
    @State private var isCommentFlaggedByMe: Bool = false
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    private let avatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let hideCommentButton: Bool
    let allowCreateComment: Bool
    
    public init(referenceId: String, referenceType: AmityCommentReferenceType, hideCommentButtons: Bool = false, allowCreateComment: Bool = false) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.hideCommentButton = hideCommentButtons
        self.allowCreateComment = allowCreateComment
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: referenceId, referenceType: referenceType))
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(AmityLocalizedStringSet.Comment.commentTrayComponentTitle.localizedString)
                .font(.system(size: 17, weight: .medium))
                .padding(.bottom, 17)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(hex: "#EBECEF")))
            
            CommentCoreView(commentButtonAction: commentButtonAction, hideCommentButtons: hideCommentButton, viewModel: commentCoreViewModel)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(hex: "#EBECEF")))
            getBottomView()
        }
        .bottomSheet(isPresented: $bottomSheetState.isShown, height: bottomSheetState.comment?.isOwner ?? false ? 204 : 148) {
            if let comment = bottomSheetState.comment, comment.isOwner {
                getOwnerBottomSheetView()
            } else {
                getNonOwnerBottomSheetView()
            }
        }
        .onChange(of: bottomSheetState.isShown) { isShown in
            guard let comment = bottomSheetState.comment, !comment.isOwner else { return }
            
            if isShown {
                updateIsCommentFlagged(comment)
            }
        }
    }
    
    
    @ViewBuilder
    func getBottomView() -> some View {
        if allowCreateComment {
            HStack(spacing: 0) {
                Text("Replying to")
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor(hex: "#636878")))
                    .padding(.leading, 16)
                Text(" \(replyState.comment?.displayName ?? AmityLocalizedStringSet.General.anonymous)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(UIColor(hex: "#636878")))
                Spacer()
                Button {
                    replyState.showToReply.toggle()
                } label: {
                    Image(AmityIcon.grayCloseIcon.getImageResource())
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 40)
            .background(Color(UIColor(hex: "#EBECEF")))
            .isHidden(!replyState.showToReply)
            
            HStack(spacing: 8) {
                AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: avatarURL)
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .padding(.leading, 12)
                
                TextField(AmityLocalizedStringSet.Comment.commentTextFieldPlacholder.localizedString, text: $text)
                    .font(.system(size: 15))
                    .frame(height: 20)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 10)
                    .background(RoundedRectangle(cornerRadius: 30)
                        .fill(Color(UIColor(hex: "#EBECEF")))
                    )
                
                Button {
                    Task {
                        do {
                            let parentId = replyState.showToReply ? replyState.comment?.commentId : nil
                            try await viewModel.createComment(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId)
                        } catch {
                            Toast.showToast(style: .warning, message: error.localizedDescription)
                        }
                        replyState = (false, nil)
                        text.removeAll()
                    }
                    hideKeyboard()
                } label: {
                    Text("Post")
                        .foregroundColor(.accentColor)
                }
                .padding(.trailing, 12)
                .disabled(text.isEmpty)
            }
            .frame(height: 56)
            .padding(.bottom, 10)
            .isHidden(hideCommentButton)
        } else {
            HStack(spacing: 16) {
                Image(AmityIcon.lockIcon.getImageResource())
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                Text(AmityLocalizedStringSet.Comment.disableCreateCommentText.localizedString)
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor(hex: "#898E9E")))
                Spacer()
            }
            .frame(height: 20)
            .padding([.bottom, .top], 10)
        }
    }
    
    
    @ViewBuilder
    private func getOwnerBottomSheetView() -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(AmityIcon.editCommentIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                
                Button {
                    commentCoreViewModel.editingComment = bottomSheetState.comment
                    bottomSheetState.isShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.editCommentBottomSheetTitle.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.black)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            
            HStack(spacing: 12) {
                Image(AmityIcon.trashBinIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                
                Button {
                    isAlertShown.toggle()
                    bottomSheetState.isShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.deleteCommentBottomSheetTitle.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.black)
                }
                .buttonStyle(.plain)
                .alert(isPresented: $isAlertShown, content: {
                    Alert(title: Text(AmityLocalizedStringSet.Comment.deleteCommentTitle.localizedString), message: Text(AmityLocalizedStringSet.Comment.deleteCommentMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                        Task {
                            if let comment = bottomSheetState.comment {
                                try await viewModel.deleteComment(id: comment.commentId)
                            }
                            bottomSheetState.comment = nil
                        }
                    }))
                })
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            Spacer()
        }
    }
    
    
    @ViewBuilder
    func getNonOwnerBottomSheetView() -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(AmityIcon.flagIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                
                Button {
                    guard let comment = bottomSheetState.comment else {
                        bottomSheetState.isShown.toggle()
                        return
                    }
                    Task {
                        do {
                            if isCommentFlaggedByMe {
                                try await viewModel.unflagComment(id: comment.id)
                            } else {
                                try await viewModel.flagComment(id: comment.id)
                            }
                            
                            updateIsCommentFlagged(comment)
                            Toast.showToast(style: .success, message: isCommentFlaggedByMe ? AmityLocalizedStringSet.Comment.commentUnReportedMessage.localizedString : AmityLocalizedStringSet.Comment.commentReportedMessage.localizedString)
                        } catch {
                            Toast.showToast(style: .warning, message: error.localizedDescription)
                        }
                    }
                    bottomSheetState.isShown.toggle()
                } label: {
                    Text(isCommentFlaggedByMe ? AmityLocalizedStringSet.Comment.unReportCommentBottomSheetTitle.localizedString : AmityLocalizedStringSet.Comment.reportCommentBottomSheetTitle.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.black)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
            
            Spacer()
        }
    }
    
    
    func commentButtonAction(_ type: AmityCommentButtonActionType) {
        switch type {
        case .react(_): break
            // Do nothing since it has rendering orchestration issue.
        case .reply(let comment):
            replyState = (true, comment)
        case .meatball(let comment):
            bottomSheetState.isShown.toggle()
            bottomSheetState.comment = comment
        }
    }
    
    func updateIsCommentFlagged(_ comment: AmityCommentModel) {
        Task {
            isCommentFlaggedByMe = try await viewModel.isCommentFlaggedByMe(id: comment.id)
        }
    }
}


class AmityCommentTrayComponentViewModel: ObservableObject {
    private let commentManager = CommentManager()
    
    @MainActor
    func createComment(referenceId: String, referenceType: AmityCommentReferenceType, text: String, parentId: String? = nil) async throws {
        let createOptions = AmityCommentCreateOptions(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId)
        try await commentManager.createComment(createOptions: createOptions)
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
    
    @MainActor
    func isCommentFlaggedByMe(id: String) async throws -> Bool {
        try await commentManager.isCommentFlaggedByMe(withId: id)
    }
}

#Preview {
    AmityCommentTrayComponent(referenceId: "", referenceType: .story)
}