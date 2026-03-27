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
    @State private var targetReplyChildCollection: AmityCollection<AmityComment>? = nil
    @State private var l2PinnedHighlightActive: Bool = false
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    private var isL2Thread: Bool {
        return viewModel.parentComment.parentId != nil
    }
    
    init(_ viewModel: ReplyCommentViewModel, hideCommentButtons: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.viewModel = viewModel
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let hasTargetReplyComment = commentCoreViewModel.hasTargetReply(comment: viewModel.parentComment)
            let isTargetReplyDeleted = commentCoreViewModel.getTargetReply(for: viewModel.parentComment)?.isDeleted ?? false

            if let targetReply = commentCoreViewModel.getTargetReply(for: viewModel.parentComment) {
                if targetReply.isDeleted {
                    DeletedCommentReplyView()
                        .id(targetReply.id)
                        .padding(.bottom, 8)
                        .padding(.leading, isL2Thread ? 94 : 52)
                        .modifier(ShakeEffect(animatableData: selectedCommentId == targetReply.commentId ? 1 : 0))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    self.selectedCommentId = targetReply.commentId
                                }
                            }
                        }
                } else {
                    let l2TargetUnavailable = commentCoreViewModel.isL2Target
                        && commentCoreViewModel.isTargetCommentFetched
                        && commentCoreViewModel.getTargetL2Comment() == nil
                        && targetReplyChildCollection == nil
                    AmityCommentView(
                        comment: targetReply,
                        hideReplyButton: false,
                        hideButtonView: hideCommentButtons,
                        showChildLine: targetReply.childrenNumber > 0 && !l2TargetUnavailable,
                        commentButtonAction: commentButtonAction
                    )
                    .id(targetReply.id)
                    .padding(.leading, isL2Thread ? 84 : 42)
                    .modifier(ShakeEffect(animatableData: selectedCommentId == targetReply.commentId ? 1 : 0))
                    .onAppear {
                        if !commentCoreViewModel.isL2Target {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    self.selectedCommentId = targetReply.commentId
                                }
                            }
                        }
                    }
                    
                    if targetReply.childrenNumber > 0 {
                        if commentCoreViewModel.isL2Target {
                            if let l2Comment = commentCoreViewModel.getTargetL2Comment() {
                                let remainingReplies = max(0, targetReply.childrenNumber - 1)

                                let optimisticNewReplies = (commentCoreViewModel.optimisticL2InsertComments[targetReply.commentId] ?? [])
                                    .filter { $0.commentId != l2Comment.commentId }
                                ForEach(optimisticNewReplies, id: \.commentId) { newReply in
                                    let comment = AmityCommentModel(comment: newReply)
                                    HStack(alignment: .top, spacing: 0) {
                                        L2ThreadConnectorView(isLastItem: false)
                                        if let editingComment = commentCoreViewModel.editingComment, editingComment.id == comment.id {
                                            AmityEditCommentView(comment: comment, cancelAction: {
                                                commentCoreViewModel.editingComment = nil
                                            }, saveAction: { editedComment in
                                                Task {
                                                    do {
                                                        try await commentCoreViewModel.editComment(comment: editedComment)
                                                        commentCoreViewModel.editingComment = nil
                                                    } catch {
                                                        let message: String
                                                        if error.isAmityErrorCode(.banWordFound) {
                                                            message = AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString
                                                        } else if error.isAmityErrorCode(.linkNotAllowed) {
                                                            message = AmityLocalizedStringSet.Comment.commentWithNotAllowedLink.localizedString
                                                        } else {
                                                            message = AmityLocalizedStringSet.Comment.commentEditError.localizedString
                                                            commentCoreViewModel.editingComment = nil
                                                        }
                                                        Toast.showToast(style: .warning, message: message)
                                                    }
                                                }
                                            })
                                        } else {
                                            AmityCommentView(
                                                comment: comment,
                                                hideReplyButton: false,
                                                hideButtonView: hideCommentButtons,
                                                replyParentId: newReply.parentId,
                                                commentButtonAction: commentButtonAction
                                            )
                                            .id(newReply.commentId)
                                        }
                                    }
                                }

                                HStack(alignment: .top, spacing: 0) {
                                    L2ThreadConnectorView(isLastItem: targetReplyChildCollection == nil)
                                    AmityCommentView(
                                        comment: l2Comment,
                                        hideReplyButton: false,
                                        hideButtonView: hideCommentButtons,
                                        replyParentId: l2Comment.parentId,
                                        highlightColor: l2PinnedHighlightActive ? Color(viewConfig.theme.primaryColor.blend(.shade2)) : nil,
                                        commentButtonAction: commentButtonAction
                                    )
                                    .id(l2Comment.id)
                                }
                                .onAppear {
                                    guard !l2PinnedHighlightActive else { return }
                                    l2PinnedHighlightActive = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            l2PinnedHighlightActive = false
                                        }
                                    }
                                }

                                if targetReplyChildCollection == nil && remainingReplies > 0 {
                                    ViewMoreRepliesButton {
                                        targetReplyChildCollection = commentCoreViewModel.getChildComments(
                                            parentId: targetReply.commentId,
                                            isL2Thread: true
                                        )
                                    }
                                    .padding(.bottom, 12)
                                    .padding(.leading, 84)
                                }

                                if let targetReplyChildCollection {
                                    ReplyCommentListView(
                                        collection: targetReplyChildCollection,
                                        excludedCommentId: l2Comment.commentId,
                                        isL2Thread: true,
                                        l1ParentId: targetReply.commentId,
                                        targetCommentId: nil,
                                        hideCommentButtons: hideCommentButtons,
                                        showPinnedComments: false,
                                        commentButtonAction: commentButtonAction
                                    )
                                }
                            } else if commentCoreViewModel.isTargetCommentFetched {
                                if targetReplyChildCollection == nil {
                                    ViewMoreRepliesButton {
                                        targetReplyChildCollection = commentCoreViewModel.getChildComments(
                                            parentId: targetReply.commentId,
                                            isL2Thread: true
                                        )
                                    }
                                    .padding(.bottom, 12)
                                    .padding(.leading, 84)
                                }

                                if let targetReplyChildCollection {
                                    ReplyCommentListView(
                                        collection: targetReplyChildCollection,
                                        excludedCommentId: nil,
                                        isL2Thread: true,
                                        l1ParentId: targetReply.commentId,
                                        targetCommentId: nil,
                                        hideCommentButtons: hideCommentButtons,
                                        commentButtonAction: commentButtonAction
                                    )
                                }
                            } else {
                                HStack(alignment: .top, spacing: 0) {
                                    L2ThreadConnectorView(isLastItem: true)
                                    CommentSkeletonView()
                                        .padding(.leading, 10)
                                }
                            }
                        } else if !commentCoreViewModel.isL2Target {
                            if targetReplyChildCollection == nil {
                                ViewMoreRepliesButton {
                                    targetReplyChildCollection = commentCoreViewModel.getChildComments(
                                        parentId: targetReply.commentId,
                                        isL2Thread: true
                                    )
                                }
                                .padding(.bottom, 12)
                                .padding(.leading, 84)
                            }

                            if let targetReplyChildCollection {
                                ReplyCommentListView(
                                    collection: targetReplyChildCollection,
                                    excludedCommentId: nil,
                                    isL2Thread: true,
                                    l1ParentId: targetReply.commentId,
                                    targetCommentId: commentCoreViewModel.highlightTargetCommentId ?? commentCoreViewModel.targetCommentId,
                                    hideCommentButtons: hideCommentButtons,
                                    commentButtonAction: commentButtonAction
                                )
                            }
                        }
                    }
                }
            }
            
            let normalFlowHasOptimisticReplies = isL2Thread
                && commentCoreViewModel.getTargetReply(for: viewModel.parentComment) == nil
                && !(commentCoreViewModel.optimisticL2InsertComments[viewModel.parentComment.commentId] ?? []).isEmpty
                && collection == nil
            let shouldHideReplyCommentButton = (hasTargetReplyComment && viewModel.parentComment.childrenNumber == 1 && !isTargetReplyDeleted)
                || viewModel.parentComment.childrenNumber == 0
                || normalFlowHasOptimisticReplies
            let baseButtonPadding: Double = isL2Thread ? 84 : 42
            let isFromNotification = commentCoreViewModel.targetCommentParentId != nil
            let padding: Double = !isFromNotification && hasTargetReplyComment && !isTargetReplyDeleted ? baseButtonPadding + 48 : baseButtonPadding

            if isL2Thread && !isFromNotification {
                HStack(alignment: .top, spacing: 0) {
                    L2ThreadConnectorView(isLastItem: true)
                    getViewReplyCommentButton(viewModel.parentComment)
                        .padding(.bottom, 12)
                }
                .isHidden(hideViewReplyCommentButton || shouldHideReplyCommentButton)
            } else {
                getViewReplyCommentButton(viewModel.parentComment)
                    .padding(.bottom, 12)
                    .padding(.leading, padding)
                    .isHidden(hideViewReplyCommentButton || shouldHideReplyCommentButton)
            }
            
            if isL2Thread && commentCoreViewModel.getTargetReply(for: viewModel.parentComment) == nil {
                let optimisticReplies = commentCoreViewModel.optimisticL2InsertComments[viewModel.parentComment.commentId] ?? []
                if !optimisticReplies.isEmpty && collection == nil {
                    let existingCount = max(0, viewModel.parentComment.childrenNumber - optimisticReplies.count)
                    ForEach(optimisticReplies, id: \.commentId) { newReply in
                        let isLastReply = newReply.commentId == optimisticReplies.last?.commentId
                        let comment = AmityCommentModel(comment: newReply)
                        HStack(alignment: .top, spacing: 0) {
                            L2ThreadConnectorView(isLastItem: isLastReply)
                            if let editingComment = commentCoreViewModel.editingComment, editingComment.id == comment.id {
                                AmityEditCommentView(comment: comment, cancelAction: {
                                    commentCoreViewModel.editingComment = nil
                                }, saveAction: { editedComment in
                                    Task {
                                        do {
                                            try await commentCoreViewModel.editComment(comment: editedComment)
                                            commentCoreViewModel.editingComment = nil
                                        } catch {
                                            let message: String
                                            if error.isAmityErrorCode(.banWordFound) {
                                                message = AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString
                                            } else if error.isAmityErrorCode(.linkNotAllowed) {
                                                message = AmityLocalizedStringSet.Comment.commentWithNotAllowedLink.localizedString
                                            } else {
                                                message = AmityLocalizedStringSet.Comment.commentEditError.localizedString
                                                commentCoreViewModel.editingComment = nil
                                            }
                                            Toast.showToast(style: .warning, message: message)
                                        }
                                    }
                                })
                            } else {
                                AmityCommentView(
                                    comment: comment,
                                    hideReplyButton: false,
                                    hideButtonView: hideCommentButtons,
                                    replyParentId: newReply.parentId,
                                    commentButtonAction: commentButtonAction
                                )
                                .id(newReply.commentId)
                            }
                        }
                    }
                    if existingCount > 0 {
                        ViewMoreRepliesButton {
                            collection = commentCoreViewModel.getChildComments(
                                parentId: viewModel.parentComment.commentId,
                                isL2Thread: true
                            )
                            hideViewReplyCommentButton = true
                        }
                        .padding(.bottom, 12)
                        .padding(.leading, 84)
                    }
                }
            }

            if let collection {
                let targetCommentId = commentCoreViewModel.getTargetReply(for: viewModel.parentComment)?.commentId
                let l1ParentId: String? = isL2Thread ? viewModel.parentComment.commentId : nil
                let highlightId = commentCoreViewModel.highlightTargetCommentId
                
                ReplyCommentListView(collection: collection,
                                     excludedCommentId: targetCommentId,
                                     isL2Thread: isL2Thread,
                                     l1ParentId: l1ParentId,
                                     targetCommentId: highlightId,
                                hideCommentButtons: hideCommentButtons,
                                commentButtonAction: commentButtonAction)
                
            }
        }
        .onAppear {
            if viewModel.preloadReplyComments {
                collection = commentCoreViewModel.getChildComments(parentId: viewModel.parentComment.commentId, isL2Thread: isL2Thread)
                hideViewReplyCommentButton = true
            }
        }
        .onChange(of: commentCoreViewModel.expandRepliesForCommentId) { expandId in
            if expandId == viewModel.parentComment.commentId, collection == nil {
                if isL2Thread {
                    hideViewReplyCommentButton = true
                } else {
                    collection = commentCoreViewModel.getChildComments(parentId: viewModel.parentComment.commentId, isL2Thread: isL2Thread)
                    hideViewReplyCommentButton = true
                }
            }
            if let targetReply = commentCoreViewModel.getTargetReply(for: viewModel.parentComment),
               expandId == targetReply.commentId,
               targetReplyChildCollection == nil {
                targetReplyChildCollection = commentCoreViewModel.getChildComments(
                    parentId: targetReply.commentId,
                    isL2Thread: true
                )
            }
        }
        .onChange(of: commentCoreViewModel.optimisticL2InsertIds) { newIds in
            if let targetReply = commentCoreViewModel.getTargetReply(for: viewModel.parentComment),
               targetReplyChildCollection == nil,
               !(newIds[targetReply.commentId] ?? []).isEmpty {
                targetReplyChildCollection = commentCoreViewModel.getChildComments(
                    parentId: targetReply.commentId,
                    isL2Thread: true
                )
            }
        }
    }
    
    @ViewBuilder
    func getViewReplyCommentButton(_ parentComment: AmityCommentModel) -> some View {
        Button {
            collection = commentCoreViewModel.getChildComments(parentId: parentComment.commentId, isL2Thread: isL2Thread)
            hideViewReplyCommentButton = true
        } label: {
            HStack {
                HStack(spacing: 4) {
                    let hasTargetReply = commentCoreViewModel.hasTargetReply(comment: parentComment)
                    if hasTargetReply {
                        Image(AmityIcon.viewMoreReplyArrowIcon.getImageResource())
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    } else {
                        Image(AmityIcon.replyArrowIcon.getImageResource())
                            .resizable()
                            .frame(width: 20, height: 20)
                            .isHidden(isL2Thread)
                    }
                    
                    let repliesCount = hasTargetReply ? parentComment.childrenNumber - 1 : parentComment.childrenNumber
                    
                    let word = WordsGrammar(count: repliesCount, set: .reply)
                    let finalText = hasTargetReply ? AmityLocalizedStringSet.Comment.viewMoreReplyText.localizedString : "View \(repliesCount) \(word.value)"
                    Text(finalText)
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                }
                .padding(.horizontal, 4)
                .frame(height: 28, alignment: .leading)
                
                Spacer()
            }
            .padding(.leading, 12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.viewReplyButton)
    }
    
}


struct ReplyCommentListView<Content>: View where Content: View {
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    private let headerView: () -> Content
    private let commentButtonAction: AmityCommentButtonAction
    private let hideCommentButtons: Bool
    private let isL2Thread: Bool
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @StateObject var viewModel: ReplyCommentListViewModel
    
    private let l1ParentId: String?
    private let targetCommentId: String?
    
    @State private var activeHighlightId: String?
    private let showPinnedComments: Bool

    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         collection: AmityCollection<AmityComment>,
         excludedCommentId: String?,
         isL2Thread: Bool = false,
         l1ParentId: String? = nil,
         targetCommentId: String? = nil,
         hideCommentButtons: Bool = false,
         showPinnedComments: Bool = true,
         commentButtonAction: @escaping AmityCommentButtonAction) {
        
        self.headerView = headerView
        self._viewModel = StateObject(wrappedValue: ReplyCommentListViewModel(collection: collection, excludedCommentId: excludedCommentId))
        self.targetCommentId = targetCommentId
        self.commentButtonAction = commentButtonAction
        self.hideCommentButtons = hideCommentButtons
        self.isL2Thread = isL2Thread
        self.l1ParentId = l1ParentId
        self.showPinnedComments = showPinnedComments
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            headerView()
            if viewModel.comments.isEmpty && viewModel.collection.loadingStatus != .loaded {
                getReplySkeletonView()
            } else {
                getComment()
                getViewMoreReplyCommentButton()
                    .padding([.top, .bottom], 6)
                    .padding(.leading, isL2Thread ? 92 : 60)
                    .isHidden(isL2Thread ? !viewModel.collection.hasNext : !viewModel.collection.hasPrevious)
            }
        }
        .onAppear {
            if let targetCommentId, activeHighlightId == nil {
                activeHighlightId = targetCommentId
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        activeHighlightId = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    func getReplySkeletonView() -> some View {
        CommentSkeletonView()
            .padding(.leading, isL2Thread ? 84 : 42)
    }

    @ViewBuilder
    func getViewMoreReplyCommentButton() -> some View {
        ViewMoreRepliesButton {
            guard viewModel.collection.loadingStatus != .loading else { return }
            if isL2Thread {
                guard viewModel.collection.hasNext else { return }
                viewModel.collection.nextPage()
            } else {
                guard viewModel.collection.hasPrevious else { return }
                viewModel.collection.previousPage()
            }
        }
    }
    
    @ViewBuilder
    func getComment() -> some View {
        let optimisticIds: [String] = isL2Thread ? (commentCoreViewModel.optimisticL2InsertIds[l1ParentId ?? ""] ?? []) : []
        let pinnedComments: [AmityComment] = (isL2Thread && showPinnedComments) ? (commentCoreViewModel.optimisticL2InsertComments[l1ParentId ?? ""] ?? []) : []
        let normalComments = viewModel.comments.filter { !optimisticIds.contains($0.commentId) }
        let displayComments = pinnedComments + normalComments

        ForEach(displayComments, id: \.commentId) { amityComment in
            let comment = AmityCommentModel(comment: amityComment)
            let isLastL2Item = isL2Thread && displayComments.last?.commentId == amityComment.commentId
            
            Section {
                if !comment.isDeleted {
                    if let editingComment = commentCoreViewModel.editingComment, editingComment.id == comment.id {
                        if isL2Thread {
                            HStack(alignment: .top, spacing: 0) {
                                L2ThreadConnectorView(isLastItem: isLastL2Item)
                                AmityEditCommentView(comment: comment, cancelAction: {
                                    commentCoreViewModel.editingComment = nil
                                }, saveAction: { editedComment in
                                    Task {
                                        do {
                                            try await commentCoreViewModel.editComment(comment: editedComment)
                                            commentCoreViewModel.editingComment = nil
                                        } catch {
                                            let message: String
                                            if error.isAmityErrorCode(.banWordFound) {
                                                message = AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString
                                            } else if error.isAmityErrorCode(.linkNotAllowed) {
                                                message = AmityLocalizedStringSet.Comment.commentWithNotAllowedLink.localizedString
                                            } else {
                                                message = AmityLocalizedStringSet.Comment.commentEditError.localizedString
                                                commentCoreViewModel.editingComment = nil
                                            }
                                            Toast.showToast(style: .warning, message: message)
                                        }
                                    }
                                })
                            }
                        } else {
                            AmityEditCommentView(comment: comment, showChildLine: comment.childrenNumber > 0, cancelAction: {
                                commentCoreViewModel.editingComment = nil
                            }, saveAction: { editedComment in
                                Task {
                                    do {
                                        try await commentCoreViewModel.editComment(comment: editedComment)
                                        commentCoreViewModel.editingComment = nil
                                    } catch {
                                        let message: String
                                        if error.isAmityErrorCode(.banWordFound) {
                                            message = AmityLocalizedStringSet.Comment.commentWithBannedWordsErrorMessage.localizedString
                                        } else if error.isAmityErrorCode(.linkNotAllowed) {
                                            message = AmityLocalizedStringSet.Comment.commentWithNotAllowedLink.localizedString
                                        } else {
                                            message = AmityLocalizedStringSet.Comment.commentEditError.localizedString
                                            commentCoreViewModel.editingComment = nil
                                        }
                                        Toast.showToast(style: .warning, message: message)
                                    }
                                }
                            })
                            .padding(.leading, 42)
                        }
                    } else {
                        if isL2Thread {
                            let isHighlighted = activeHighlightId == amityComment.commentId
                            HStack(alignment: .top, spacing: 0) {
                                L2ThreadConnectorView(isLastItem: isLastL2Item)
                                AmityCommentView(
                                    comment: comment,
                                    hideReplyButton: false,
                                    hideButtonView: hideCommentButtons,
                                    replyParentId: comment.parentId,
                                    highlightColor: isHighlighted ? Color(viewConfig.theme.primaryColor.blend(.shade2)) : nil,
                                    commentButtonAction: commentButtonAction
                                )
                                .id(comment.id)
                            }
                        } else {
                            AmityCommentView(
                                comment: comment,
                                hideReplyButton: false,
                                hideButtonView: hideCommentButtons,
                                replyParentId: nil,
                                showChildLine: comment.childrenNumber != 0,
                                commentButtonAction: commentButtonAction
                            )
                            .id(comment.id)
                            .padding(.leading, 42)
                        }
                    }
                } else {
                    if isL2Thread {
                        HStack(alignment: .top, spacing: 0) {
                            L2ThreadConnectorView(isLastItem: isLastL2Item)
                            DeletedCommentReplyView()
                                .padding(.bottom, 8)
                                .padding(.leading, 10)
                        }
                    } else {
                        DeletedCommentReplyView()
                            .padding(.bottom, 8)
                            .padding(.leading, 52)
                    }
                }
                
                if comment.childrenNumber != 0 && !isL2Thread {
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
        private var hasShownUnavailableToast = false
        private var hasEverHadItems = false
        
        init(collection: AmityCollection<AmityComment>, excludedCommentId: String?) {
            self.collection = collection
            self.excludedCommentId = excludedCommentId
            
            cancellable = collection.$snapshots.sink(receiveValue: { [weak self] items in
                guard let self else { return }
                
                let filtered: [AmityComment]
                if let excludedCommentId = self.excludedCommentId {
                    filtered = items.filter { $0.commentId != excludedCommentId }
                } else {
                    filtered = items
                }
                self.comments = filtered
                
                if !filtered.isEmpty {
                    self.hasEverHadItems = true
                }
                
                if self.collection.loadingStatus == .loaded && filtered.isEmpty && !self.hasShownUnavailableToast && !self.hasEverHadItems {
                    self.hasShownUnavailableToast = true
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString)
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

struct L2ThreadConnectorView: View {
    let isLastItem: Bool
    @EnvironmentObject var viewConfig: AmityViewConfigController

    let width: CGFloat = 84
    private let lineX: CGFloat = 70
    private let kneeY: CGFloat = 16
    private let strokeWidth: CGFloat = 2
    private let cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: lineX, y: 0))
                path.addLine(to: CGPoint(x: lineX, y: isLastItem ? kneeY - cornerRadius : geo.size.height))
            }
            .stroke(Color(viewConfig.theme.baseColorShade4), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: lineX, y: kneeY - cornerRadius))
                path.addQuadCurve(
                    to: CGPoint(x: lineX + cornerRadius, y: kneeY),
                    control: CGPoint(x: lineX, y: kneeY)
                )
                path.addLine(to: CGPoint(x: geo.size.width, y: kneeY))
            }
            .stroke(Color(viewConfig.theme.baseColorShade4), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width)
    }
}

struct ViewMoreRepliesButton: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 4) {
                    Image(AmityIcon.viewMoreReplyArrowIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    Text(AmityLocalizedStringSet.Comment.viewMoreReplyText.localizedString)
                        .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade1)))
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 4)
                .frame(height: 28, alignment: .leading)
                Spacer()
            }
            .padding(.leading, 12)
        }
        .buttonStyle(.plain)
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
