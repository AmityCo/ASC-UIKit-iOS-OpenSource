//
//  AmityLivestreamPlayerPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/24/25.
//


import SwiftUI
import AmitySDK

public struct AmityLivestreamPlayerPage: AmityPageView {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityLiveStreamPlayerPageViewModel
    private var displayErrorIfEnded: Bool = false
        
    public var id: PageId {
        .livestreamPlayerPage
    }
    
    public init(post: AmityPost) {
        let postModel = AmityPostModel(post: post)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .livestreamPlayerPage))
        self._viewModel = StateObject(wrappedValue: AmityLiveStreamPlayerPageViewModel(post: postModel))
    }
    
    public init(roomId: String, displayErrorIfEnded: Bool = false) {
        self.displayErrorIfEnded = displayErrorIfEnded
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .livestreamPlayerPage))
        self._viewModel = StateObject(wrappedValue: AmityLiveStreamPlayerPageViewModel(roomId: roomId))
    }
    
    public init(postModel: AmityPostModel) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .livestreamPlayerPage))
        self._viewModel = StateObject(wrappedValue: AmityLiveStreamPlayerPageViewModel(post: postModel))
    }
        
    public var body: some View {
        ZStack(alignment: .bottom) {
            // background loading view
            backgroundLoadingView
                .opacity(viewModel.isLoading ? 1 : 0)
            
            contentView
            
            // Error View
            PostDetailEmptyStateView(action: { host.controller?.dismiss(animated: true) })
                .visibleWhen(!viewModel.isLoading && (viewModel.room?.status == .ended || viewModel.room?.status == .recorded || viewModel.room?.status == .terminated) && displayErrorIfEnded)
        }
        .onAppear {
            Task {
                await viewModel.checkProductCatalogueSettings()
            }
        }
        .bottomSheet(isShowing: $viewModel.showInvitedAsCoHostSheet, height: .contentSize, backgroundColor: Color(viewConfig.defaultDarkTheme.backgroundColor), sheetContent: {
            LiveStreamCoHostJoinSheet(
                viewModel: viewModel,
                onAccept: {
                    viewModel.isJoinSheetDismissedOnAction = true
                    viewModel.acceptCoHostInvitation()
                },
                onDecline: {
                    viewModel.isJoinSheetDismissedOnAction = true
                    viewModel.declineCoHostInvitation()
                }
            )
        })
        .onChange(of: viewModel.showInvitedAsCoHostSheet) { show in
            // decline invitation when sheet is dismissed
            if show == false && !viewModel.isJoinSheetDismissedOnAction {
                viewModel.declineCoHostInvitation()
            }
            
            viewModel.isJoinSheetDismissedOnAction = false
        }
        .environmentObject(viewConfig)
        .environmentObject(host)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.currentState {
        case .viewer:
            if viewModel.room?.status == .live || viewModel.room?.status == .waitingReconnect {
                livestreamViewerView
            } else if !displayErrorIfEnded {
                playbackPlayerView
            }
        case .inBackstage:
            livestreamBackstageView
        case .streamingAsCoHost:
            livestreamConferenceView
        }
    }
    
    @ViewBuilder
    private var livestreamViewerView: some View {
        if let livestreamViewerViewModel = viewModel.livestreamViewerViewModel {
            LiveStreamViewerView(viewModel: livestreamViewerViewModel)
                .onAppear {
                    livestreamViewerViewModel.startPresenceHeartbeat()
                }
                .onDisappear {
                    livestreamViewerViewModel.stopPresenceHeartbeat()
                }
        }
    }
    
    @ViewBuilder
    private var playbackPlayerView: some View {
        if let room = viewModel.post?.room, let post = viewModel.post {
            let isHost = post.postedUserId == AmityUIKitManagerInternal.shared.client.currentUserId
            let childPost = viewModel.updatedChildPost ?? post.childrenPosts.first
            let productTagsBinding = Binding<[AmityProductTagModel]>(
                get: {
                    (viewModel.updatedChildPost ?? post.childrenPosts.first)?.getMediaProductTags().compactMap { tag -> AmityProductTagModel? in
                        guard let product = tag.product else { return nil }
                        return AmityProductTagModel(object: product, range: NSRange(), contentType: .media)
                    } ?? []
                },
                set: { _ in }
            )
            ZStack(alignment: .bottomLeading) {
                AmityPostMediaVideoPlayer(
                    pageId: id,
                    post: post,
                    playerType: .livestream(room),
                    hideActionMenu: !isHost,
                    onClose: {
                        host.controller?.dismissOrPop()
                    },
                    onTagProducts: isHost ? {
                        if let childPost = childPost {
                            showPlaybackProductList(childPost: childPost, isHost: isHost)
                        }
                    } : nil,
                    liveProductTags: productTagsBinding
                )
                .ignoresSafeArea(.all)
            }
        }
    }
    
    private func showPlaybackProductList(childPost: AmityPost, isHost: Bool = false) {
        Task {
            // Re-fetch network setting before showing any product tag UI
            await viewModel.checkProductCatalogueSettings()
            // Host can always manage products regardless of catalogue setting
            guard viewModel.isProductTagEnabled || isHost else { return }
            _showPlaybackProductList(childPost: childPost)
        }
    }
    
    private func _showPlaybackProductList(childPost: AmityPost) {
        // Check if current user is the post owner (host)
        let isHost = childPost.postedUserId == AmityUIKitManagerInternal.shared.client.currentUserId
        
        if isHost {
            // Seed viewModel state from the child post
            viewModel.taggedProducts = childPost.getMediaProductTags().compactMap { $0.product }
            viewModel.pinnedProductId = childPost.pinnedProductId
            viewModel.previousProductCount = viewModel.taggedProducts.count
            
            let manageVM = ManageProductTagViewModel()
            manageVM.taggedProducts = viewModel.taggedProducts
            manageVM.pinnedProductId = viewModel.pinnedProductId
            
            var manageComponent = ManageProductTagListComponent(
                viewModel: manageVM,
                renderMode: .playback,
                onClose: { products in
                    viewModel.taggedProducts = products
                },
                onAddProducts: {
                    viewModel.previousProductCount = manageVM.taggedProducts.count
                    let productSelectionComponent = AmityProductTagSelectionComponent(
                        pageId: .livestreamPlayerPage,
                        mode: .livestream,
                        initialSelection: [],
                        existingProducts: manageVM.taggedProducts.map { $0.productId },
                        onClose: {
                            UIApplication.topViewController()?.dismiss(animated: true)
                        },
                        onDone: {
                            if manageVM.taggedProducts.count > viewModel.previousProductCount {
                                // Sync to parent before API call
                                viewModel.taggedProducts = manageVM.taggedProducts
                                UIApplication.topViewController()?.dismiss(animated: true) {
                                    Task {
                                        await viewModel.updateProductTagsAPI(childPost: childPost)
                                    }
                                }
                            } else {
                                UIApplication.topViewController()?.dismiss(animated: true)
                            }
                        },
                        onTagChanges: { newlySelectedProducts in
                            let existingIds = Set(manageVM.taggedProducts.map { $0.productId })
                            let newProducts = newlySelectedProducts.filter { !existingIds.contains($0.productId) }
                            manageVM.taggedProducts = manageVM.taggedProducts + newProducts
                        }
                    )
                        .environmentObject(viewConfig)
                        .ignoresSafeArea(edges: .bottom)
                    let hostController = AmitySwiftUIHostingController(rootView: productSelectionComponent)
                    hostController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
                    UIApplication.topViewController()?.present(hostController, animated: true)
                },
                onPinToggle: { productId, isPinned in
                    // Pin/unpin disabled for recorded livestream
                    print("Cannot pin/unpin products in recorded livestream")
                },
                onProductRemove: { productId in
                    Task {
                        // Filter out the removed product for API call without local update to manageVM
                        viewModel.taggedProducts = manageVM.taggedProducts.filter { $0.productId != productId }
                        if viewModel.pinnedProductId == productId {
                            viewModel.pinnedProductId = nil
                        }
                        await viewModel.updateProductTagsAPI(childPost: childPost)
                        // Sync BE response back to manageVM
                        manageVM.taggedProducts = viewModel.taggedProducts
                        manageVM.pinnedProductId = viewModel.pinnedProductId
                    }
                }
            )
            manageComponent.canAddProducts = viewModel.isProductTagEnabled
            
            let vc = AmitySwiftUIHostingController(rootView: manageComponent
                .environmentObject(AmityViewConfigController(pageId: .livestreamPlayerPage, componentId: .productTagListBottomsheet)))
            vc.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            host.controller?.present(vc, animated: true)
        } else {
            // Show view-only product list for viewer
            let productTags = childPost.getMediaProductTags().compactMap { mediaTag -> AmityProductTagModel? in
                guard let product = mediaTag.product else { return nil }
                return AmityProductTagModel(object: product, range: NSRange(location: 0, length: 0), contentType: .media)
            }
            
            let component = AmityProductTagListComponent(
                pageId: .livestreamPlayerPage,
                productTags: productTags,
                renderMode: .livestream,
                sourceId: childPost.getRoomInfo()?.roomId ?? "",
                onClose: {
                    self.host.controller?.dismiss(animated: true)
                }
            )
            
            let vc = AmitySwiftUIHostingController(rootView: component
                .ignoresSafeArea(edges: .bottom))
            vc.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            if #available(iOS 15.0, *) {
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.selectedDetentIdentifier = .medium
                }
            } else {
                // Fallback on earlier versions
            }
            host.controller?.present(vc, animated: true)
        }
    }
    
    @ViewBuilder
    private var livestreamBackstageView: some View {
        if let post = viewModel.post, let conferenceViewModel = viewModel.conferenceViewModel, let broadcasterViewModel = viewModel.broadcasterViewModel {
            LiveStreamBackstageView(post: post, viewModel: broadcasterViewModel, onJoin: {
                conferenceViewModel.startStreamAsCoHost(post: post)
                viewModel.currentState = .streamingAsCoHost
            }, onDismiss: {
                let alert = UIAlertController(title: AmityLocalizedStringSet.Social.livestreamLeaveBackstageTitle.localizedString, message: AmityLocalizedStringSet.Social.livestreamLeaveBackstageMessage.localizedString, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
                let leaveAction = UIAlertAction(title: AmityLocalizedStringSet.General.leave.localizedString, style: .destructive) { _ in
                    viewModel.leaveRoom()
                    viewModel.currentState = .viewer
                }
                
                alert.addAction(cancelAction)
                alert.addAction(leaveAction)
                
                host.controller?.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    @ViewBuilder
    private var livestreamConferenceView: some View {
        if let conferenceViewModel = viewModel.conferenceViewModel, let broadcasterViewModel = viewModel.broadcasterViewModel {
            LiveStreamConferenceView(viewModel: conferenceViewModel, broadcasterViewModel: broadcasterViewModel)
                .onAppear {
                    conferenceViewModel.didCoHostLeave = { [weak viewModel] in
                        viewModel?.currentState = .viewer
                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamLeftStageToast.localizedString, bottomPadding: 60)
                    }
                    
                    conferenceViewModel.didCoHostJoined = { [weak viewModel] success in
                        if !success {
                            viewModel?.currentState = .inBackstage
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var backgroundLoadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                                .frame(width: 40, height: 40)
                Spacer()
            }
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}
