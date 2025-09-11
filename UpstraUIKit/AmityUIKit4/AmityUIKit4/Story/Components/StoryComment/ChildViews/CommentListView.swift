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
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    private var commentItems: [PaginatedItem<AmityCommentModel>]
    private let headerView: () -> Content
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    
    @State private var selectedCommentId: String? = nil
    
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
        ScrollViewReader { proxy in
            ScrollView {
                if commentCoreViewModel.targetCommentId == nil {
                    LazyVStack(spacing: 0) {
                        getContent(proxy: proxy)
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    })
                } else {
                    // To support scroll to particular comment & bounce animation when navigating to comment through notification tray page
                    // We cannot do that in LazyVStack as the comment isn't rendered.
                    VStack(spacing: 0) {
                        getContent(proxy: proxy)
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    })
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offsetY in
                if commentCoreViewModel.hasScrolledToTop != (offsetY < -1) {
                    commentCoreViewModel.hasScrolledToTop.toggle()
                }
            }
        }
    }
    
    @ViewBuilder
    func getContent(proxy: ScrollViewProxy) -> some View {
        headerView()
            .padding(.bottom, 8)
        
        if commentItems.isEmpty && commentCoreViewModel.loadingStatus != .loaded {
            getSkeletonView()
        } else {
            getCommentWithAds(value: proxy)
                .onAppear {
                    if let commentId = commentCoreViewModel.targetComment?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(commentId, anchor: .top)
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                self.selectedCommentId = commentCoreViewModel.targetCommentReply?.id ?? commentId
                            }
                        }
                    }
                }
        }
        
        Color.clear.frame(height: 6)
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
                            } else {
                                AmityCommentView(comment: comment, hideReplyButton: false, hideButtonView: hideCommentButtons, commentButtonAction: commentButtonAction)
                                    .id(comment.id)
                                    .modifier(ShakeEffect(animatableData: selectedCommentId == comment.id ? 1 : 0))
                            }
                        } else {
                            DeletedCommentView()
                                .id(comment.id)
                                .modifier(ShakeEffect(animatableData: selectedCommentId == comment.id ? 1 : 0))
                        }
                        
                        if comment.childrenNumber != 0 {
                            let preloadReplyComments = comment.commentId == commentCoreViewModel.targetCommentId && commentCoreViewModel.preloadRepliesOfComment
                            let viewModel = ReplyCommentViewModel(comment, preloadReplyComments: preloadReplyComments)
                            ReplyCommentView(viewModel, hideCommentButtons: hideCommentButtons, commentButtonAction: commentButtonAction)
                                .padding(.top, comment.reactionsCount == 0 ? 8 : 4)
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
    
    struct DeletedCommentView: View {
        @EnvironmentObject var viewConfig: AmityViewConfigController
        
        var body: some View {
            VStack(spacing: 10) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                
                HStack(spacing: 16) {
                    Image(AmityIcon.deletedMessageIcon.imageResource)
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
}
