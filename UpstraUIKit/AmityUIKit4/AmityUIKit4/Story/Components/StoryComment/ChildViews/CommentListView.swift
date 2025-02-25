//
//  CommentListView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import AmitySDK

struct CommentListView<Content>: View where Content: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    private var commentItems: [PaginatedItem<AmityCommentModel>]
    private let headerView: () -> Content
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         commentItems: [PaginatedItem<AmityCommentModel>],
         hideCommentButtons: Bool = false,
         commentButtonAction: @escaping AmityCommentButtonAction) {
        
        self.headerView = headerView
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
        self.commentItems = commentItems
    }
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack {
                    
                    headerView()
                    
                    if commentItems.isEmpty && commentCoreViewModel.loadingStatus != .loaded {
                        getSkeletonView()
                    } else {
                        getCommentWithAds(value: value)
                    }
                    
                    Color.clear.frame(height: 6)
                    
                }
            }
        }
    }
    
    @ViewBuilder
    func getSkeletonView() -> some View {
        ForEach(0..<10, id: \.self) { index in
            VStack(spacing: 0) {
                CommentSkeletonView()
            }
            .listRowInsets(EdgeInsets())
            .modifier(HiddenListSeparator())
        }
    }
        
    @ViewBuilder
    func getCommentWithAds(value: ScrollViewProxy) -> some View {
        ForEach(Array(commentItems.enumerated()), id: \.element.id) { index, item in
            VStack(spacing: 0) {
                switch item.type {
                case .ad(let ad):
                    AmityCommentAdComponent(ad: ad, selctedAdInfoAction: { ad in
                        
                        commentCoreViewModel.adSeetState = (true, ad)
                    })
                case .content(let comment):
                    Section {
                        if !comment.isDeleted {
                            if let editingComment = commentCoreViewModel.editingComment, editingComment.id == comment.id {
                                AmityEditCommentView(comment: comment, cancelAction: {
                                    commentCoreViewModel.editingComment = nil
                                }, saveAction: { editedComment in
                                    Task {
                                        do {
                                            try await commentCoreViewModel.editComment(comment: editedComment)
                                        } catch {
                                            Toast.showToast(style: .warning, message: "Failed to edit post")
                                        }
                                        
                                        commentCoreViewModel.editingComment = nil
                                    }
                                })
                                .padding([.top, .bottom], 3)
                                .padding(.leading, 0)
                            } else {
                                AmityCommentView(comment: comment, hideReplyButton: false, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                                    .id(comment.id)
                                    .padding([.top, .bottom], 3)
                                    .padding(.leading, 0)
                            }
                            
                        } else {
                            getDeletedMessageView()
                        }
                        
                        if comment.childrenNumber != 0 {
                            let viewModel = ReplyCommentViewModel(comment)
                            ReplyCommentView(viewModel, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
                        }
                    }
                }
            }
            .onAppear {
                // Parent comment list will load previous page on scrolling.
                // Reply comment list will load on View More Reply button action.
                if index == commentCoreViewModel.commentItems.count - 1 && commentCoreViewModel.paginator.hasPreviousPage() {
                    commentCoreViewModel.paginator.previousPage()
                    
                }
            }
        }
        .onChange(of: commentItems.first?.id) { _ in
            withAnimation {
                value.scrollTo(commentItems.first?.id)
            }
        }
    }
    
    @ViewBuilder
    func getDeletedMessageView() -> some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            HStack(spacing: 16) {
                Image(AmityIcon.deletedMessageIcon.getImageResource())
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .padding(.leading, 18)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                
                Text(AmityLocalizedStringSet.Comment.deletedCommentMessage.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.trailing, 16)
                
                Spacer()
            }
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
        }
        
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.deletedComment)
    }
}

struct ReplyCommentListView<Content>: View where Content: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    @ObservedObject var collection: AmityCollection<AmityComment>
    private let headerView: () -> Content
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         collection: AmityCollection<AmityComment>,
         hideCommentButtons: Bool = false,
         commentButtonAction: @escaping AmityCommentButtonAction) {
        
        self.headerView = headerView
        self.collection = collection
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack {
                    headerView()
                    getComment(value: value)
                }
            }
        }
    }
        
    @ViewBuilder
    func getComment(value: ScrollViewProxy) -> some View {
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
                        .padding(.leading, 52)
                    } else {
                        AmityCommentView(comment: comment, hideReplyButton: true, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                            .id(comment.id)
                            .padding([.top, .bottom], 3)
                            .padding(.leading, 52)
                    }
                    
                } else {
                    getDeletedMessageView()
                        .padding([.top, .bottom], 3)
                        .padding(.leading, 104)
                }
                
                if comment.childrenNumber != 0 {
                    let viewModel = ReplyCommentViewModel(comment)
                    ReplyCommentView(viewModel, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
                }
            }
        }
    }
    
    
    @ViewBuilder
    func getDeletedMessageView() -> some View {
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
            .background(Color(viewConfig.theme.baseColorShade4))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            Spacer()
        }
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.deletedComment)
    }
}
