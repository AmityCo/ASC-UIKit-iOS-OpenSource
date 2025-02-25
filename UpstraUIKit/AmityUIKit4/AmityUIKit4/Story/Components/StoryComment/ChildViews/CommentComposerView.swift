//
//  CommentComposerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/17/24.
//

import SwiftUI
import AmitySDK

struct CommentComposerView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let avatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    private let displayName: String = AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName ?? ""
    @ObservedObject private var viewModel: CommentComposerViewModel
    
    init(viewModel: CommentComposerViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        contentView
    }
    
    @ViewBuilder
    var contentView: some View {
        if viewModel.allowCreateComment {
            HStack(spacing: 0) {
                Text("Replying to")
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.leading, 16)
                Text(" \(viewModel.replyState.comment?.displayName ?? AmityLocalizedStringSet.General.anonymous)")
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
                Spacer()
                Button {
                    viewModel.replyState.showToReply.toggle()
                } label: {
                    Image(AmityIcon.grayCloseIcon.getImageResource())
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 40)
            .background(Color(viewConfig.theme.baseColorShade4))
            .isHidden(!viewModel.replyState.showToReply)
            
            HStack(spacing: 8) {
                AmityUserProfileImageView(displayName: displayName, avatarURL: avatarURL)
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .padding(.leading, 12)
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.avatarImageView)
                
                AmityTextEditorView(.comment(communityId: viewModel.community?.communityId ?? ""), text: $viewModel.text, mentionData: $viewModel.mentionData, textViewHeight: 34.0)
                    .placeholder(AmityLocalizedStringSet.Comment.commentTextFieldPlacholder.localizedString)
                    .maxExpandableHeight(120.0)
                    .textColor(viewConfig.theme.baseColor)
                    .backgroundColor(viewConfig.theme.backgroundColor)
                    .hightlightColor(viewConfig.theme.primaryColor)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 5)
                    .background(RoundedRectangle(cornerRadius: 30)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                    )
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.textField)
                
                Button {
                    Task {
                        do {
                            let parentId = viewModel.replyState.showToReply ? viewModel.replyState.comment?.commentId : nil
                            try await viewModel.createComment(text: viewModel.text, parentId: parentId, mentionData: viewModel.mentionData)
                        } catch {
                            Toast.showToast(style: .warning, message: error.isAmityErrorCode(.banWordFound) ? AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString : error.localizedDescription)
                        }
                        viewModel.replyState = (false, nil)
                        viewModel.text.removeAll()
                    }
                    hideKeyboard()
                } label: {
                    Text("Post")
                        .overlay(
                            Text("Post")
                                .foregroundColor(Color(viewConfig.theme.primaryColor))
                                .opacity(viewModel.text.isEmpty ? 0.4 : 1.0)
                        )
                }
                .padding(.trailing, 12)
                .disabled(viewModel.text.isEmpty)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.postButton)
            }
            .padding([.bottom, .top], 10)
        } else {
            HStack(spacing: 16) {
                Image(AmityIcon.lockIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 16)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(AmityLocalizedStringSet.Comment.disableCreateCommentText.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.disableTextView)
                Spacer()
            }
            .frame(height: 20)
            .padding([.bottom, .top], 10)
        }
    }
}


class CommentComposerViewModel: ObservableObject {
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let community: AmityCommunity?
    @Published var allowCreateComment: Bool
    
    @Published var replyState: (showToReply: Bool, comment: AmityCommentModel?) = (false, nil)
    @Published var text: String = ""
    @Published var mentionData: MentionData = MentionData()
    
    private let commentManager = CommentManager()
    
    init(referenceId: String, referenceType: AmityCommentReferenceType, community: AmityCommunity?, allowCreateComment: Bool) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.community = community
        self.allowCreateComment = allowCreateComment
    }
    
    @MainActor
    func createComment(text: String, parentId: String? = nil, mentionData: MentionData?) async throws {
        let createOptions = AmityCommentCreateOptions(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId, metadata: mentionData?.metadata, mentioneeBuilder: mentionData?.mentionee)
        try await commentManager.createComment(createOptions: createOptions)
    }
}

