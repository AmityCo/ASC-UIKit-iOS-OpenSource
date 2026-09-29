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
    
    /// Comment can be switched off while the post around it stays on, and this
    /// view renders the post as its own header — so the module is asked here
    /// rather than around the whole view. Switching Comment off removed the
    /// count and the button and left every comment on the post still
    /// readable. The composer asks for itself (`CommentComposerView.isShown`).
    private var commentEnabled: Bool {
        AmityUIKitConfigController.shared.isFeatureEnabled(AmityUIKitFeature.comment)
    }

    var body: some View {
        ZStack {
            CommentListView(headerView: headerView,
                            commentItems: commentEnabled ? viewModel.commentItems : [],
                            hideCommentButtons: viewModel.hideCommentButtons,
                            commentButtonAction: commentButtonAction ?? { _ in })
            .environmentObject(viewModel)
            
            Text(AmityLocalizedStringSet.Comment.noCommentAvailable.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                .isHidden(viewModel.commentItems.count != 0)
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.emptyTextView)
                // With Comment off the surface does not exist, so it must not
                // read as "no comments yet" either.
                .visibleWhen(commentEnabled && !viewModel.hideEmptyText && viewModel.commentItems.isEmpty && viewModel.loadingStatus == .loaded)
        }
    }
}
