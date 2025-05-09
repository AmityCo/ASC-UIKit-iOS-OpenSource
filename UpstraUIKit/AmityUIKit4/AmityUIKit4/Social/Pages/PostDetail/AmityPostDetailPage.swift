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
    
    private var context: AmityPostContentComponent.Context?
    private var commentId: String?
    
    public var id: PageId {
        .postDetailPage
    }
    
    public init(id: String, commentId: String? = nil, parentId: String? = nil) {
        let postDetailViewModel = AmityPostDetailPageViewModel(id: id)
        self.commentId = commentId
        self.context = AmityPostContentComponent.Context()
        self._viewModel = StateObject(wrappedValue: postDetailViewModel)
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: id, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: postDetailViewModel.post?.targetCommunity?.communityId, targetCommentId: commentId, targetCommentParentId: parentId))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: id, referenceType: .post, community: postDetailViewModel.post?.targetCommunity, allowCreateComment: true))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postDetailPage))
    }
    
    // Post with context
    public init(post: AmityPost, context: AmityPostContentComponent.Context?) {
        self.context = context
        self._viewModel = StateObject(wrappedValue: AmityPostDetailPageViewModel(post: post))
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: post.postId, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: post.targetCommunity?.communityId))
        self._commentComposerViewModel = StateObject(wrappedValue: CommentComposerViewModel(referenceId: post.postId, referenceType: .post, community: post.targetCommunity, allowCreateComment: true))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postDetailPage))
    }
    
    public var body: some View {
        ZStack {
            
            PostDetailEmptyStateView()
                .opacity(viewModel.isPostDeleted ? 1 : 0)
            
            VStack(spacing: 0) {
                navigationBarView
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                    .isHidden(!commentCoreViewModel.hasScrolledToTop)
                
                if viewModel.isLoading {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                SkeletonRectangle(height: 8, width: 180)
                                SkeletonRectangle(height: 8, width: 64)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        
                        SkeletonRectangle(height: 8, width: 240)
                        SkeletonRectangle(height: 8, width: 180)
                        SkeletonRectangle(height: 8, width: 290)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 0) {
                        CommentCoreView(headerView: {
                            VStack(spacing: 4) {
                                if let postModel = viewModel.post {
                                    AmityPostContentComponent(post: postModel.object, style: .detail, context: getPostComponentContext())
                                    Rectangle()
                                        .fill(Color(viewConfig.theme.baseColorShade4))
                                        .frame(height: 1)
                                } else {
                                    PostContentSkeletonView()
                                }
                            }
                        },viewModel: commentCoreViewModel, commentButtonAction: self.commentButtonAction(_:))
                        .bottomSheet(isShowing: $commentBottomSheetViewModel.sheetState.isShown,
                                     height: commentBottomSheetViewModel.sheetState.comment?.isOwner ?? false ? .fixed(204) : .fixed(148),
                                     backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                            CommentBottomSheetView(viewModel: commentBottomSheetViewModel) { comment in
                                commentCoreViewModel.editingComment = comment
                            } reportAction: { comment in
                                let commentId = comment?.commentId ?? ""
                                
                                // Dismiss bottom sheet
                                host.controller?.dismiss(animated: false)
                                
                                let page = AmityContentReportPage(type: .comment(id: commentId))
                                    .updateTheme(with: viewConfig)
                                let vc = AmitySwiftUIHostingNavigationController(rootView: page)
                                vc.isNavigationBarHidden = true
                                self.host.controller?.present(vc, animated: true)
                            }
                        }
                        
                        CommentComposerView(viewModel: commentComposerViewModel)
                            .isHidden(!(viewModel.post?.targetCommunity?.isJoined ?? true))
                    }
                    .opacity(viewModel.isPostDeleted ? 0 : 1)
                }
            }
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
    
    private var navigationBarView: some View {
        return AmityNavigationBar(title: AmityLocalizedStringSet.Social.postDetailPageTitle.localizedString, showBackButton: true) {
            
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
                    
                    PostBottomSheetView(isShown: $showBottomSheet, post: postModel) { postAction in
                        
                        switch postAction {
                        case .editPost:
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
                        case .deletePost:
                            host.controller?.navigationController?.popViewController(animated: true)
                        case .closePoll:
                            break
                        case .reportPost:
                            // Dismiss toggle
                            showBottomSheet.toggle()
                            
                            // Dismiss bottom sheet
                            host.controller?.dismiss(animated: false)
                            
                            let postId = postModel.postId
                            
                            let page = AmityContentReportPage(type: .post(id: postId))
                                .updateTheme(with: viewConfig)
                            let vc = AmitySwiftUIHostingNavigationController(rootView: page)
                            vc.isNavigationBarHidden = true
                            self.host.controller?.present(vc, animated: true)
                        }
                    }
                }
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 24, height: 24)
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
        case .userProfile(let userId):
            let context = AmityPostDetailPageBehavior.Context(page: self, userId: userId)
            AmityUIKitManagerInternal.shared.behavior.postDetailPageBehavior?.goToUserProfilePage(context: context)
        }
    }
    
    func getPostComponentContext() -> AmityPostContentComponent.Context {
        let componentContext = context ?? AmityPostContentComponent.Context(category: context?.category ?? .general, shouldHideTarget: context?.hidePostTarget ?? false)
        componentContext.hideMenuButton = true
        return componentContext
    }
}
