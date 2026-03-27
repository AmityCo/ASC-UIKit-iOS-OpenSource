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
    private let onL2ReplyCreated: ((_ comment: AmityComment, _ l1ParentId: String) -> Void)?
    private let onReplyCreated: ((_ replyTargetCommentId: String) -> Void)?
    
    init(viewModel: CommentComposerViewModel,
         onL2ReplyCreated: ((_ comment: AmityComment, _ l1ParentId: String) -> Void)? = nil,
         onReplyCreated: ((_ replyTargetCommentId: String) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onL2ReplyCreated = onL2ReplyCreated
        self.onReplyCreated = onReplyCreated
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
                    viewModel.replyState = (false, nil, nil)
                } label: {
                    Image(AmityIcon.grayCloseIcon.getImageResource())
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 40)
            .background(Color(viewConfig.theme.baseColorShade4))
            .isHidden(!viewModel.replyState.showToReply)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            HStack(spacing: 8) {
                AmityUserProfileImageView(displayName: displayName, avatarURL: avatarURL)
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)
                    .padding(.leading, 12)
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.avatarImageView)
                
                AmityTextEditorView(.comment(communityId: viewModel.community?.communityId ?? ""), text: $viewModel.text, mentionData: $viewModel.mentionData, textViewHeight: 34.0)
                    .placeholder(AmityLocalizedStringSet.Comment.commentTextFieldPlacholder.localizedString)
                    .maxExpandableHeight(120.0)
                    .autoFocus(viewModel.replyState.showToReply)
                    .textColor(viewConfig.theme.baseColor)
                    .backgroundColor(viewConfig.theme.backgroundColor)
                    .hightlightColor(viewConfig.theme.primaryColor)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 5)
                    .background(RoundedRectangle(cornerRadius: 30)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                    )
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentComposer.textField)
                    .id(viewModel.prefillVersion)
                
                Button {
                    Task {
                        do {
                            let isL2Reply = viewModel.replyState.resolvedParentId != nil
                            let parentId = viewModel.replyState.showToReply ? (viewModel.replyState.resolvedParentId ?? viewModel.replyState.comment?.commentId) : nil
                            let replyTargetCommentId = viewModel.replyState.comment?.commentId
                            let newComment = try await viewModel.createComment(text: viewModel.text, parentId: parentId, mentionData: viewModel.mentionData)
                            if isL2Reply, let l1ParentId = parentId {
                                onL2ReplyCreated?(newComment, l1ParentId)
                            }
                            if let targetId = replyTargetCommentId {
                                onReplyCreated?(targetId)
                            }
                        } catch {
                            let message: String
                            if error.isAmityErrorCode(.banWordFound) {
                                message = AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString
                            } else if error.isAmityErrorCode(.linkNotAllowed) {
                                message = AmityLocalizedStringSet.Comment.commentWithNotAllowedLink.localizedString
                            } else if error.isAmityErrorCode(.itemNotFound) {
                                if viewModel.replyState.showToReply {
                                    if viewModel.replyState.comment?.isParent == true {
                                        message = AmityLocalizedStringSet.Comment.commentUnavailableToastMessage.localizedString
                                    } else {
                                        message = AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString
                                    }
                                } else if let post = viewModel.post, post.dataTypeInternal == .clip {
                                    message = AmityLocalizedStringSet.Comment.clipUnavailableToastMessage.localizedString
                                } else {
                                    message = AmityLocalizedStringSet.Comment.postUnavailableToastMessage.localizedString
                                }
                            } else {
                                message = error.localizedDescription
                            }
                            
                            Toast.showToast(style: .warning, message: message)
                        }
                        viewModel.replyState = (false, nil, nil)
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
    
    @Published var replyState: (showToReply: Bool, comment: AmityCommentModel?, resolvedParentId: String?) = (false, nil, nil)
    @Published var text: String = ""
    @Published var mentionData: MentionData = MentionData()
    @Published var prefillVersion: Int = 0
    
    private let commentManager = CommentManager()
    private let postManager = PostManager()
    
    var post: AmityPostModel?
    
    init(referenceId: String, referenceType: AmityCommentReferenceType, community: AmityCommunity?, allowCreateComment: Bool) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.community = community
        self.allowCreateComment = allowCreateComment
        if referenceType == .post {
            if let localPost = postManager.getPost(withId: referenceId).snapshot {
                self.post = AmityPostModel(post: localPost)
            }
        }
    }
    
    @MainActor
    @discardableResult
    func createComment(text: String, parentId: String? = nil, mentionData: MentionData?) async throws -> AmityComment {
        let links = AmityPreviewLinkWizard.shared.buildLinks(from: text)
        let createOptions = AmityCommentCreateOptions(referenceId: referenceId, referenceType: referenceType, text: text, parentId: parentId, metadata: mentionData?.metadata, mentioneeBuilder: mentionData?.mentionee, links: links.isEmpty ? nil : links)
        return try await commentManager.createComment(createOptions: createOptions)
    }

    func applyMentionPrefill(for comment: AmityCommentModel) {
        let displayName = comment.displayName
        let mention = AmityMention(type: .user, index: 0, length: displayName.count, userId: comment.userId)
        let metadata = AmityMetadataMapper.metadata(mentions: [mention], hashtags: [])

        let mentioneeBuilder = AmityMentioneesBuilder()
        mentioneeBuilder.mentionUsers(userIds: [comment.userId])

        let prefillData = MentionData()
        prefillData.metadata = metadata
        prefillData.mentionee = mentioneeBuilder

        self.text = "@\(displayName) "
        self.mentionData = prefillData
        self.prefillVersion += 1
    }
    
    func handleReplyAction(comment: AmityCommentModel, resolvedParentId: String?) {
        replyState = (true, comment, resolvedParentId ?? comment.commentId)
        let isL2Comment = comment.parentId != nil
        let isOwnComment = comment.userId == AmityUIKitManagerInternal.shared.currentUserId
        if isL2Comment && !isOwnComment {
            applyMentionPrefill(for: comment)
        } else {
            prefillVersion += 1
        }
    }
}

