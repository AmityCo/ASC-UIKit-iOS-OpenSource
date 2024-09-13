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
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewModel: AmityPostDetailPageViewModel
    
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    @StateObject private var commentComposerViewModel: CommentComposerViewModel
    @StateObject private var commentBottomSheetViewModel = CommentBottomSheetViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var showBottomSheet: Bool = false
    
    private var postCategory: AmityPostCategory = .general
    private var hideTarget: Bool = false
    
    public var id: PageId {
        .postDetailPage
    }
    
    public init(id: String) {
        let postDetailViewModel = AmityPostDetailPageViewModel(id: id)
        self._viewModel = StateObject(wrappedValue: postDetailViewModel)
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: id, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: postDetailViewModel.post?.targetCommunity?.communityId))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: id, referenceType: .post, community: postDetailViewModel.post?.targetCommunity, allowCreateComment: true))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postDetailPage))
    }
    
    /// Convenience initializer
    public init(post: AmityPost, category: AmityPostCategory = .general, hideTarget: Bool = false) {
        self.postCategory = category
        self.hideTarget = hideTarget
        self._viewModel = StateObject(wrappedValue: AmityPostDetailPageViewModel(post: post))
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: post.postId, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: post.targetCommunity?.communityId))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: post.postId, referenceType: .post, community: post.targetCommunity, allowCreateComment: true))
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
                
                if let postModel = viewModel.post {
                    let bottomSheetHeight = calculateBottomSheetHeight(post: postModel)
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
                    .bottomSheet(isShowing: $showBottomSheet, height: .fixed(bottomSheetHeight), backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                        PostBottomSheetView(isShown: $showBottomSheet, post: postModel) {
                            host.controller?.navigationController?.popViewController(animated: true)
                        } editPostActionCompletion: {
                            
                            showBottomSheet.toggle()
                            
                            // Dismiss bottomsheet
                            host.controller?.dismiss(animated: false)
                            
                            let editOption = AmityPostComposerOptions.editOptions(post: postModel)
                            let view = AmityPostComposerPage(options: editOption)
                            let controller = AmitySwiftUIHostingController(rootView: view)
                            
                            let navigationController = UINavigationController(rootViewController: controller)
                            navigationController.modalPresentationStyle = .fullScreen
                            navigationController.navigationBar.isHidden = true
                            host.controller?.present(navigationController, animated: true)
                            
                        }
                        
                    }
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(EdgeInsets(top: 19, leading: 16, bottom: 16, trailing: 16))
            
            CommentCoreView(headerView: {
                VStack(spacing: 4) {
                    if let postModel = viewModel.post {
                        AmityPostContentComponent(post: postModel.object, style: .detail, category: postCategory, hideTarget: hideTarget, hideMenuButton: true)
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 1)
                    } else {
                        PostContentSkeletonView()
                    }
                }
            },
                            viewModel: commentCoreViewModel,
                            commentButtonAction: self.commentButtonAction(_:))
            .bottomSheet(isShowing: $commentBottomSheetViewModel.sheetState.isShown,
                         height: commentBottomSheetViewModel.sheetState.comment?.isOwner ?? false ? .fixed(204) : .fixed(148),
                         backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                CommentBottomSheetView(viewModel: commentBottomSheetViewModel) { comment in
                    commentCoreViewModel.editingComment = comment
                }
            }

            CommentComposerView(viewModel: commentComposerViewModel)
                .isHidden(!(viewModel.post?.targetCommunity?.isJoined ?? true))
        }
        .sheet(isPresented: $commentCoreViewModel.adSeetState.isShown, content: {
            if let ad = commentCoreViewModel.adSeetState.ad {
                AmityAdInfoView(advertiserName: ad.advertiser?.companyName ?? "-")
            }
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            
            if let targetCommunity = viewModel.post?.targetCommunity {
                commentCoreViewModel.hideCommentButtons = !targetCommunity.isJoined
            }

        }
    }
    
    func calculateBottomSheetHeight(post: AmityPostModel) -> CGFloat {
        
        let baseBottomSheetHeight: CGFloat = 68
        let itemHeight: CGFloat = 48
        let additionalItems = [
            true,  // Always add one item
            post.hasModeratorPermission || post.isOwner,
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
    
    @Published var post: AmityPostModel?
    
    init(id: String) {
        self.postId = id
        
        postObject = postManager.getPost(withId: id)
        cancellable = postObject?.$snapshot
            .sink { [weak self] post in
                guard let post else { return }
                self?.post = AmityPostModel(post: post)
            }
    }
    
    init(post: AmityPost) {
        self.post = AmityPostModel(post: post)
        
        postObject = postManager.getPost(withId: post.postId)
        cancellable = postObject?.$snapshot
            .sink { [weak self] post in
                guard let post else { return }
                self?.post = AmityPostModel(post: post)
            }
    }
}

#if DEBUG
#Preview(body: {
    AmityPostDetailPage(id: "")
})
#endif
