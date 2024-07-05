//
//  AmityPostDetailPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/10/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityPostDetailPage: AmityPageView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject private var viewModel: AmityPostDetailPageViewModel
    
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    @StateObject private var commentComposerViewModel: CommentComposerViewModel
    @StateObject private var commentBottomSheetViewModel = CommentBottomSheetViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showBottomSheet: Bool = false
    
    public var id: PageId {
        .postDetailPage
    }
    
    public init(id: String) {
        self._viewModel = StateObject(wrappedValue: AmityPostDetailPageViewModel(id: id))
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: id, referenceType: .post, hideEmptyText: true, hideCommentButtons: false))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: id, referenceType: .post, community: nil, allowCreateComment: true))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postDetailPage))
    }
    
    /// Convenience initializer
    public init(post: AmityPost) {
        self._viewModel = StateObject(wrappedValue: AmityPostDetailPageViewModel(post: post))
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: post.postId, referenceType: .post, hideEmptyText: true, hideCommentButtons: false))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: post.postId, referenceType: .post, community: nil, allowCreateComment: true))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postDetailPage))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                let backIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "icon", of: String.self) ?? "")
                Image(backIcon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 20)
                    .onTapGesture {
                        host.controller?.navigationController?.popViewController(animated: true)
                    }
                    .isHidden(viewConfig.isHidden(elementId: .backButtonElement))
                
                Spacer()
                
                Text(AmityLocalizedStringSet.Social.postDetailPageTitle.localizedString)
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                if let post = viewModel.post {
                    let model = AmityPostModel(post: post)
                    let bottomSheetHeight = calculateBottomSheetHeight(post: model)
                    Button(action: {
                        showBottomSheet.toggle()
                    }, label: {
                        let menuIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .menuButton, key: "icon", of: String.self) ?? "")
                        Image(menuIcon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 24)
                    })
                    .isHidden(viewConfig.isHidden(elementId: .menuButton))
                    .bottomSheet(isShowing: $showBottomSheet, height: bottomSheetHeight, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                        PostBottomSheetView(isShown: $showBottomSheet, post: model) {
                            host.controller?.navigationController?.popViewController(animated: true)
                        } editPostActionCompletion: {
                            
                            showBottomSheet.toggle()
                            
                            // Dismiss bottomsheet
                            host.controller?.dismiss(animated: false)
                            
                            let editOption = AmityPostComposerOptions.editOptions(post: model)
                            let view = AmityPostComposerPage(options: editOption)
                            let controller = AmitySwiftUIHostingController(rootView: view)
                            
                            let navigationController = UINavigationController(rootViewController: controller)
                            navigationController.modalPresentationStyle = .fullScreen
                            navigationController.navigationBar.isHidden = true
                            host.controller?.present(navigationController, animated: true)
                            
                        }
                        
                    }
                }
            }
            .padding(EdgeInsets(top: 19, leading: 16, bottom: 16, trailing: 16))
            
            if let post = viewModel.post {
                CommentCoreView(headerView: {
                    VStack(spacing: 4) {
                        AmityPostContentComponent(post: post, style: .postDetail, hideMenuButton: true)
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 1)
                    }
                },
                viewModel: commentCoreViewModel,
                commentButtonAction: self.commentButtonAction(_:))
                .bottomSheet(isShowing: $commentBottomSheetViewModel.sheetState.isShown,
                             height: commentBottomSheetViewModel.sheetState.comment?.isOwner ?? false ? 204 : 148,
                             backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                    CommentBottomSheetView(viewModel: commentBottomSheetViewModel) { comment in
                        commentCoreViewModel.editingComment = comment
                    }
                }
            } else { Spacer() }
            
            CommentComposerView(viewModel: commentComposerViewModel)
        }
        .sheet(isPresented: $commentCoreViewModel.adSeetState.isShown, content: {
            if let ad = commentCoreViewModel.adSeetState.ad {
                AmityAdInfoView(advertiserName: ad.advertiser?.companyName ?? "-")
            }
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    func calculateBottomSheetHeight(post: AmityPostModel) -> CGFloat {
        
        let baseBottomSheetHeight: CGFloat = 68
        let itemHeight: CGFloat = 48
        let additionalItems = [
            true,  // Always add one item
            post.isModerator || post.isOwner,
        ].filter { $0 }
        
        let additionalHeight = CGFloat(additionalItems.count) * itemHeight
        
        
        return baseBottomSheetHeight + additionalHeight
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

class AmityPostDetailPageViewModel: ObservableObject {
    private var postObject: AmityObject<AmityPost>?
    private var postId: String = ""
    private var cancellable: AnyCancellable?
    private let postManager = PostManager()
    
    @Published var post: AmityPost?
    
    init(id: String) {
        self.postId = id
        postObject = postManager.getPost(withId: id)
        cancellable = postObject?.$snapshot
            .sink { [weak self] post in
                self?.post = post
            }
    }
    
    init(post: AmityPost) {
        self.post = post
        postObject = postManager.getPost(withId: post.postId)
        cancellable = postObject?.$snapshot
            .sink { [weak self] post in
                self?.post = post
            }
    }
}

#if DEBUG
#Preview(body: {
    AmityPostDetailPage(id: "")
})
#endif
