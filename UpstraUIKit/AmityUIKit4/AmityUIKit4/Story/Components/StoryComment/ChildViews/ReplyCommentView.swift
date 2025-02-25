//
//  ReplyCommentView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import AmitySDK

struct ReplyCommentView: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    @State var collection: AmityCollection<AmityComment>?
    @State private var hideViewReplyCommentButton: Bool = false
    private let viewModel: ReplyCommentViewModel
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(_ viewModel: ReplyCommentViewModel, hideCommentButtons: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.viewModel = viewModel
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        // Reply Comments
        VStack {
            getViewReplyCommentButton(viewModel.parentComment)
                .padding([.top, .bottom], 6)
                .padding(.leading, 52)
                .isHidden(hideViewReplyCommentButton)
            
            if let collection {
                ReplyCommentListView(collection: collection,
                                hideCommentButtons: hideCommentButtons,
                                commentButtonAction: commentButtonAction)
                                .padding(.top, 6)
                
                getViewMoreReplyCommentButton()
                    .padding([.top, .bottom], 6)
                    .padding(.leading, 52)
                    .isHidden(!collection.hasPrevious)
                
            }
            
        }
    }
    
    @ViewBuilder
    func getViewReplyCommentButton(_ parentComment: AmityCommentModel) -> some View {
        Button {
            collection = commentCoreViewModel.getChildComments(parentId: parentComment.commentId)
            hideViewReplyCommentButton = true
        } label: {
            HStack {
                HStack(spacing: 4) {
                    Image(AmityIcon.replyArrowIcon.getImageResource())
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.leading, 8)
                    
                    Text("View \(parentComment.childrenNumber) Reply")
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.secondaryColor.blend(.shade1))))
                        .padding(.trailing, 8)
                }
                .frame(height: 28, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 0.4)
                )
                Spacer()
            }
        }
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.viewReplyButton)
    }
    
    
    @ViewBuilder
    func getViewMoreReplyCommentButton() -> some View {
        Button {
            guard let collection, collection.hasPrevious else { return }
            collection.previousPage()
        } label: {
            HStack {
                HStack(spacing: 4) {
                    Image(AmityIcon.replyArrowIcon.getImageResource())
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.leading, 8)
                    
                    Text(AmityLocalizedStringSet.Comment.viewMoreReplyText.localizedString)
                        .applyTextStyle(.captionBold(Color(UIColor(hex: "#636878"))))
                        .padding(.trailing, 8)
                }
                .frame(height: 28, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.gray, lineWidth: 0.4)
                )
                Spacer()
            }
        }
    }
}


class ReplyCommentViewModel: ObservableObject {
    @Published var parentComment: AmityCommentModel
    
    init(_ parentComment: AmityCommentModel) {
        self.parentComment = parentComment
    }
}

