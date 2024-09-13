//
//  AmityCommentTrayComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/29/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommentTrayComponent: AmityComponentView {
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .commentTrayComponent
    }
    
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    @StateObject private var commentComposerViewModel: CommentComposerViewModel
    @StateObject private var commentBottomSheetViewModel = CommentBottomSheetViewModel()
    
    private let avatarURL: URL? = URL(string: AmityUIKitManagerInternal.shared.client.user?.snapshot?.getAvatarInfo()?.fileURL ?? "")
    @StateObject private var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    
    public init(referenceId: String, 
                referenceType: AmityCommentReferenceType,
                community: AmityCommunity? = nil,
                shouldAllowInteraction: Bool = false,
                shouldAllowCreation: Bool = false,
                pageId: PageId? = nil) {
        
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: referenceId, referenceType: referenceType, hideEmptyText: false, hideCommentButtons: !shouldAllowInteraction, communityId: community?.communityId))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: referenceId, referenceType: referenceType, community: community, allowCreateComment: shouldAllowCreation))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .commentTrayComponent))
        self.pageId = pageId
        
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
            
            Text(AmityLocalizedStringSet.Comment.commentTrayComponentTitle.localizedString)
                .font(.system(size: 17, weight: .semibold))
                .padding(.bottom, 17)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.titleTextView)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
            
            CommentCoreView(viewModel: commentCoreViewModel, commentButtonAction: self.commentButtonAction(_:))
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
    
            CommentComposerView(viewModel: commentComposerViewModel)
                .isHidden(commentCoreViewModel.hideCommentButtons, remove: true)
        }
        .bottomSheet(isShowing: $commentBottomSheetViewModel.sheetState.isShown,
                     height: commentBottomSheetViewModel.sheetState.comment?.isOwner ?? false ? .fixed(204) : .fixed(148),
                     backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            CommentBottomSheetView(viewModel: commentBottomSheetViewModel) { comment in
                commentCoreViewModel.editingComment = comment
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .environmentObject(viewConfig)
        .onChange(of: colorScheme) { value in
            viewConfig.updateTheme()
        }
    }
    
    
    func commentButtonAction(_ type: AmityCommentButtonActionType) {
        switch type {
        case .react(_): break
            // Do nothing since it has rendering orchestration issue.
        case .reply(let comment):
            commentComposerViewModel.replyState = (true, comment)
        case .meatball(let comment):
            hideKeyboard() 
            
            commentBottomSheetViewModel.sheetState.isShown.toggle()
            commentBottomSheetViewModel.sheetState.comment = comment
        }
    }
}

#if DEBUG
#Preview {
    AmityCommentTrayComponent(referenceId: "", referenceType: .story)
}
#endif
