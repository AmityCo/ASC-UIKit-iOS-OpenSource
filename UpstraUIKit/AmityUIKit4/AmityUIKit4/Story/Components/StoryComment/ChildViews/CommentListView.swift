//
//  CommentListView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import AmitySDK

struct CommentListView: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    @ObservedObject var collection: AmityCollection<AmityComment>
    private let isReply: Bool
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(_ collection: AmityCollection<AmityComment>, isReply: Bool = false, hideCommentButtons: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.collection = collection
        self.isReply = isReply
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { value in
                ScrollView {
                    LazyVStack {
                        isReply ? nil : Color.clear.frame(height: 6)
                        
                        ForEach(Array(collection.snapshots.enumerated()), id: \.element.commentId) { index, amityComment in
                            let comment = AmityCommentModel(comment: amityComment)
                            
                            Section {
                                if !comment.isDeleted {
                                    if let editingComment = commentCoreViewModel.editingComment, editingComment.id == comment.id {
                                        AmityEditCommentView(comment: comment, cancelAction: {
                                            commentCoreViewModel.editingComment = nil
                                        }, saveAction: { editedComment in
                                            Task {
                                                try await commentCoreViewModel.editComment(comment: editedComment)
                                                commentCoreViewModel.editingComment = nil
                                            }
                                        })
                                        .padding([.top, .bottom], 3)
                                        .padding(.leading, isReply ? 52 : 0)
                                    } else {
                                        AmityCommentView(comment: comment, hideReplyButton: isReply, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                                            .id(comment.id)
                                            .padding([.top, .bottom], 3)
                                            .padding(.leading, isReply ? 52 : 0)
                                    }
                                    
                                } else {
                                    getDeletedMessageView(isReply: isReply)
                                        .padding([.top, .bottom], 3)
                                        .padding(.leading, isReply ? 104 : 52)
                                }
                                
                                if comment.childrenNumber != 0 {
                                    let viewModel = ReplyCommentViewModel(comment)
                                    ReplyCommentView(viewModel, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
                                }
                            }
                            .onAppear {
                                // Parenet comment list will load previous page on scrolling.
                                // Reply comment list will load on View More Reply button action.
                                if index == collection.snapshots.count - 1 && collection.hasPrevious && !isReply {
                                    collection.previousPage()
                                }
                            }
                        }
                        .onChange(of: collection.snapshots.first?.commentId) { _ in
                            guard !isReply else { return }
                            withAnimation {
                                value.scrollTo(collection.snapshots.first?.commentId)
                            }
                        }
                        
                        isReply ? nil : Color.clear.frame(height: 6)
                    }
                }
            }
            
            Text(AmityLocalizedStringSet.Comment.noCommentAvailable.localizedString)
                .font(.system(size: 15))
                .foregroundColor(Color(UIColor(hex: "#898E9E")))
                .isHidden(collection.snapshots.count != 0 || isReply)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.emptyTextView)
        }
    }
    
    
    @ViewBuilder
    func getDeletedMessageView(isReply: Bool) -> some View {
        HStack {
            HStack(spacing: 8) {
                    Image(AmityIcon.deletedMessageIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 8)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                Text(isReply ? AmityLocalizedStringSet.Comment.deletedReplyCommentMessage.localizedString : AmityLocalizedStringSet.Comment.deletedCommentMessage.localizedString)
                        .font(.system(size: 13))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        .padding(.trailing, 16)
                }
                .frame(height: 28)
                .background(Color(viewConfig.theme.baseColorShade4))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Spacer()
        }
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.deletedComment)
    }
}
