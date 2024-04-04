//
//  AmityCommentTrayComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/29/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommentTrayComponent: AmityComponentView {
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .commentTrayComponent
    }
    
    @StateObject private var viewModel: AmityCommentTrayComponentViewModel = AmityCommentTrayComponentViewModel()
    @State private var replyState: (showToReply: Bool, comment: AmityCommentModel?) = (false, nil)
    @State private var bottomSheetState: (isShown: Bool, comment: AmityCommentModel?) = (false, nil)
    @State private var isAlertShown: Bool = false
    @State private var isCommentFlaggedByMe: Bool = false
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    private let avatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    
    @State private var text: String = ""
    @State private var mentionData: MentionData = MentionData()
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let communityId: String?
    let hideCommentButton: Bool
    let allowCreateComment: Bool
    
    public init(referenceId: String, referenceType: AmityCommentReferenceType, communityId: String? = nil, hideCommentButtons: Bool = false, allowCreateComment: Bool = false, pageId: PageId? = nil) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.communityId = communityId
        self.hideCommentButton = hideCommentButtons
        self.allowCreateComment = allowCreateComment
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: referenceId, referenceType: referenceType))
        self.pageId = pageId
        
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .commentTrayComponent))
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
            
            Text(AmityLocalizedStringSet.Comment.commentTrayComponentTitle.localizedString)
                .font(.system(size: 17, weight: .semibold))
                .padding(.bottom, 17)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.titleTextView)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
            
            CommentCoreView(commentButtonAction: commentButtonAction, hideCommentButtons: hideCommentButton, viewModel: commentCoreViewModel)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
            getBottomView()
        }
        .bottomSheet(isPresented: $bottomSheetState.isShown, height: bottomSheetState.comment?.isOwner ?? false ? 204 : 148, topBarBackgroundColor: Color(viewConfig.theme.backgroundColor)) {
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
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .environmentObject(viewConfig)
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }
    
    
    @ViewBuilder
    func getBottomView() -> some View {
        if allowCreateComment {
            HStack(spacing: 0) {
                Text("Replying to")
                    .font(.system(size: 15))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .padding(.leading, 16)
                Text(" \(replyState.comment?.displayName ?? AmityLocalizedStringSet.General.anonymous)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
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
            .background(Color(viewConfig.theme.backgroundColor))
            .isHidden(!replyState.showToReply)
            
            HStack(spacing: 8) {
                AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: avatarURL)
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .padding(.leading, 12)
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.avatarImageView)
                
                
                AmityTextEditorView(.comment(communityId: communityId ?? ""), text: $text, mentionData: $mentionData, textViewHeight: 20.0)
                    .placeholder(AmityLocalizedStringSet.Comment.commentTextFieldPlacholder.localizedString)
                    .maxExpandableHeight(120.0)
                    .textColor(viewConfig.theme.baseColor)
                    .backgroundColor(viewConfig.theme.backgroundColor)
                    .hightlightColor(viewConfig.theme.primaryColor)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 10)
                    .background(RoundedRectangle(cornerRadius: 30)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                    )
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.textField)
                
                Button {
                    Task {
                        do {
                            let parentId = replyState.showToReply ? replyState.comment?.commentId : nil
                            try await viewModel.createComment(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId, mentionData: mentionData)
                        } catch {
                            Toast.showToast(style: .warning, message: error.isAmityErrorCode(.banWordFound) ? AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString : error.localizedDescription)
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
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.postButton)
            }
            .padding([.bottom, .top], 10)
            .isHidden(hideCommentButton)
        } else {
            HStack(spacing: 16) {
                Image(AmityIcon.lockIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(AmityLocalizedStringSet.Comment.disableCreateCommentText.localizedString)
                    .font(.system(size: 15))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.disableTextView)
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
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Button {
                    commentCoreViewModel.editingComment = bottomSheetState.comment
                    bottomSheetState.isShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.editCommentBottomSheetTitle.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
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
                    isAlertShown.toggle()
                    bottomSheetState.isShown.toggle()
                } label: {
                    Text(AmityLocalizedStringSet.Comment.deleteCommentBottomSheetTitle.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
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
                        .foregroundColor(Color(viewConfig.theme.baseColor))
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
    
    
    func commentButtonAction(_ type: AmityCommentButtonActionType) {
        switch type {
        case .react(_): break
            // Do nothing since it has rendering orchestration issue.
        case .reply(let comment):
            replyState = (true, comment)
        case .meatball(let comment):
            hideKeyboard() 
            
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
    func createComment(referenceId: String, referenceType: AmityCommentReferenceType, text: String, parentId: String? = nil, mentionData: MentionData?) async throws {
        let createOptions = AmityCommentCreateOptions(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId, metadata: mentionData?.metadata, mentioneeBuilder: mentionData?.mentionee)
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

#if DEBUG
#Preview {
    AmityCommentTrayComponent(referenceId: "", referenceType: .story)
}
#endif
