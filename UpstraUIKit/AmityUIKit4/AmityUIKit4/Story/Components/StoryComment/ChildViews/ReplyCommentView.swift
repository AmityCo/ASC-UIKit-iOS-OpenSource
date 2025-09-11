//
//  ReplyCommentView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import AmitySDK
import Combine

struct ReplyCommentView: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    @State var collection: AmityCollection<AmityComment>?
    @State private var hideViewReplyCommentButton: Bool = false
    private let viewModel: ReplyCommentViewModel
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @State private var selectedCommentId: String? = nil
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(_ viewModel: ReplyCommentViewModel, hideCommentButtons: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.viewModel = viewModel
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        // Reply Comments
        VStack(alignment: .leading, spacing: 0) {
            let hasTargetReplyComment = commentCoreViewModel.hasTargetReply(comment: viewModel.parentComment)
            let isTargetReplyDeleted = commentCoreViewModel.getTargetReply(for: viewModel.parentComment)?.isDeleted ?? false

            // We show target reply here
            if let targetReply = commentCoreViewModel.getTargetReply(for: viewModel.parentComment) {
                if targetReply.isDeleted {
                    DeletedCommentReplyView()
                        .id(targetReply.id)
                        .padding(.bottom, 8)
                        .padding(.leading, 52)
                        .modifier(ShakeEffect(animatableData: selectedCommentId == targetReply.commentId ? 1 : 0))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    self.selectedCommentId = targetReply.commentId
                                }
                            }
                        }
                } else {
                    AmityCommentView(comment: targetReply, hideReplyButton: true, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                        .id(targetReply.id)
                        .padding(.leading, 42)
                        .modifier(ShakeEffect(animatableData: selectedCommentId == targetReply.commentId ? 1 : 0))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    self.selectedCommentId = targetReply.commentId
                                }
                            }
                        }
                }
            }
            
            // Note:
            // Comment count is decreased if the reply comment gets deleted. So we check for 2 scenarios to hide button
            // - Target reply is present && is not deleted && children count is only 1 (i.e there is only one reply to comment)
            // - Children count is 0 (there is no reply or all the replies are deleted)
            let shouldHideReplyCommentButton = (hasTargetReplyComment && viewModel.parentComment.childrenNumber == 1 && !isTargetReplyDeleted) || viewModel.parentComment.childrenNumber == 0
            let padding: Double = hasTargetReplyComment && !isTargetReplyDeleted ? 100 : 52
            getViewReplyCommentButton(viewModel.parentComment)
                .padding(.bottom, 12)
                .padding(.leading, padding)
                .isHidden(hideViewReplyCommentButton || shouldHideReplyCommentButton)
            
            if let collection {
                let targetCommentId = commentCoreViewModel.getTargetReply(for: viewModel.parentComment)?.commentId
                
                // Pass the view model created only for those comment which has targeted comment
                ReplyCommentListView(collection: collection,
                                     excludedCommentId: targetCommentId,
                                hideCommentButtons: hideCommentButtons,
                                commentButtonAction: commentButtonAction)
                
                getViewMoreReplyCommentButton()
                    .padding([.top, .bottom], 6)
                    .padding(.leading, 52)
                    .isHidden(!collection.hasPrevious)
                
            }
        }
        .onAppear {
            if viewModel.preloadReplyComments {
                collection = commentCoreViewModel.getChildComments(parentId: viewModel.parentComment.commentId)
                hideViewReplyCommentButton = true
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
                    
                    let hasTargetReply = commentCoreViewModel.hasTargetReply(comment: parentComment)
                    let repliesCount = hasTargetReply ? parentComment.childrenNumber - 1 : parentComment.childrenNumber
                    
                    let word = WordsGrammar(count: repliesCount, set: .reply)
                    let finalText = hasTargetReply ? "View more replies" : "View \(repliesCount) \(word.value)"
                    Text(finalText)
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.secondaryColorShade1)))
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
        .buttonStyle(.plain)
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

struct ReplyCommentListView<Content>: View where Content: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    private let headerView: () -> Content
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @StateObject var viewModel: ReplyCommentListViewModel
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         collection: AmityCollection<AmityComment>,
         excludedCommentId: String?,
         hideCommentButtons: Bool = false,
         commentButtonAction: @escaping AmityCommentButtonAction) {
        
        self.headerView = headerView
        self._viewModel = StateObject(wrappedValue: ReplyCommentListViewModel(collection: collection, excludedCommentId: excludedCommentId))
        //self.collection = collection
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack(spacing: 0) {
                    headerView()
                    getComment()
                }
            }
        }
    }
    
    @ViewBuilder
    func getComment() -> some View {
        ForEach(viewModel.comments, id: \.commentId) { amityComment in
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
                        .padding(.leading, 52)
                    } else {
                        AmityCommentView(comment: comment, hideReplyButton: true, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                            .id(comment.id)
                            .padding(.leading, 42)
                    }
                } else {
                    DeletedCommentReplyView()
                        .padding(.bottom, 8)
                        .padding(.leading, 52)
                }
                
                if comment.childrenNumber != 0 {
                    let viewModel = ReplyCommentViewModel(comment)
                    ReplyCommentView(viewModel, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
                }
            }
        }
    }
    
    class ReplyCommentListViewModel: ObservableObject {
        
        @ObservedObject var collection: AmityCollection<AmityComment>
        @Published var comments: [AmityComment] = []
        
        var cancellable: AnyCancellable?
        var excludedCommentId: String?
        
        init(collection: AmityCollection<AmityComment>, excludedCommentId: String?) {
            self.collection = collection
            self.excludedCommentId = excludedCommentId
            
            cancellable = collection.$snapshots.sink(receiveValue: { items in
                
                if let excludedCommentId {
                    let mappedComments = items.filter { $0.commentId != excludedCommentId }
                    self.comments = mappedComments
                } else {
                    self.comments = items
                }
            })
        }
    }
}

class ReplyCommentViewModel: ObservableObject {
    @Published var parentComment: AmityCommentModel
    let preloadReplyComments: Bool
    
    init(_ parentComment: AmityCommentModel, preloadReplyComments: Bool = false) {
        self.parentComment = parentComment
        self.preloadReplyComments = preloadReplyComments
    }
}

struct DeletedCommentReplyView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(AmityIcon.deletedMessageIcon.getImageResource())
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .padding(.leading, 8)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                Text(AmityLocalizedStringSet.Comment.deletedReplyCommentMessage.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.trailing, 16)
            }
            .frame(height: 28)
            .border(radius: 4, borderColor: Color(viewConfig.theme.baseColorShade4), borderWidth: 1)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Spacer()
        }
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.deletedComment)
    }
}
