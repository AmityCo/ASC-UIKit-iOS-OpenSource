//
//  CommentCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import SwiftUI
import AmitySDK
import Combine

struct CommentCoreView<Content>: View where Content:View {
    @ObservedObject private var viewModel: CommentCoreViewModel
    let commentButtonAction: AmityCommentButtonAction?
    let headerView: () -> Content
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() }, viewModel: CommentCoreViewModel, commentButtonAction: AmityCommentButtonAction? = nil) {
        self.headerView = headerView
        self.viewModel = viewModel
        self.commentButtonAction = commentButtonAction
    }
    
    var body: some View {
        ZStack {
            CommentListView(headerView: headerView,
                            commentItems: viewModel.commentItems,
                            hideCommentButtons: viewModel.hideCommentButtons,
                            commentButtonAction: commentButtonAction ?? { _ in })
                .environmentObject(viewModel)
            
            if !viewModel.hideEmptyText && viewModel.commentItems.isEmpty && viewModel.loadingStatus == .loaded {
                Text(AmityLocalizedStringSet.Comment.noCommentAvailable.localizedString)
                    .applyTextStyle(.body(Color(UIColor(hex: "#898E9E"))))
                    .isHidden(viewModel.commentItems.count != 0)
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.emptyTextView)
            }

        }
    }
}


class CommentCoreViewModel: ObservableObject {
    @Published var editingComment: AmityCommentModel?
    @Published var commentItems: [PaginatedItem<AmityCommentModel>] = []
    @Published var adSeetState: (isShown: Bool, ad: AmityAd?) = (false, nil)
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    private var commentCollection: AmityCollection<AmityComment>
    private let commentManager = CommentManager()
    var paginator: UIKitPaginator<AmityComment>
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let hideEmptyText: Bool
    @Published var hideCommentButtons: Bool
    
    private var paginatorCancellable: AnyCancellable?
    
    init(referenceId: String, referenceType: AmityCommentReferenceType, hideEmptyText: Bool, hideCommentButtons: Bool, communityId: String? = nil) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.hideEmptyText = hideEmptyText
        self.hideCommentButtons = hideCommentButtons
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        let collection = commentManager.getComments(queryOptions: queryOptions)
        commentCollection = collection
        paginator = UIKitPaginator(liveCollection: collection, adPlacement: .comment, communityId: communityId, modelIdentifier: { model in
            return model.commentId
        })
        paginator.load()
        
        paginatorCancellable = paginator.$snapshots.sink { [weak self] items in
            self?.loadingStatus = self?.commentCollection.loadingStatus ?? .error
                        
            self?.commentItems = items.map {
                switch $0.type {
                case .content(let comment):
                    return PaginatedItem(id: $0.id, type: .content(AmityCommentModel(comment: comment)))
                case .ad(let ad):
                    return PaginatedItem(id: $0.id, type: .ad(ad))
                }
            }
        }
        

    }
    
    func getChildComments(parentId: String) -> AmityCollection<AmityComment> {
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    parentId: parentId,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        return commentManager.getComments(queryOptions: queryOptions)
    }
    
    @MainActor
    func editComment(comment: AmityCommentModel) async throws {
        let updateOptions = AmityCommentUpdateOptions(text: comment.text, metadata: comment.metadata, mentioneesBuilder: comment.mentioneeBuilder)
        try await commentManager.editComment(withId: comment.id, options: updateOptions)
    }
    
}
