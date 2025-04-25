//
//  CommentCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/30/24.
//

import SwiftUI

struct CommentCoreView<Content>: View where Content:View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
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
            
            Text(AmityLocalizedStringSet.Comment.noCommentAvailable.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                .isHidden(viewModel.commentItems.count != 0)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.emptyTextView)
                .visibleWhen(!viewModel.hideEmptyText && viewModel.commentItems.isEmpty && viewModel.loadingStatus == .loaded)
        }
    }
}
