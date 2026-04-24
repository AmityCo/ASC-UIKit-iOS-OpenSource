//
//  LiveStreamConferenceView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/28/25.
//

import SwiftUI
import AmitySDK
import SafariServices

struct LiveStreamConferenceView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @ObservedObject private var viewModel: LiveStreamConferenceViewModel
    @StateObject private var permissionChecker = LiveStreamPermissionChecker()
    @StateObject private var pickerViewModel = ImageVideoPickerViewModel()
    @StateObject private var liveStreamAlert = LiveStreamAlert.shared
    @StateObject private var networkMonitor = NetworkMonitor()
            
    @State private var showThumbnailEditSheet = false
    @State private var showMediaPicker = false
    @State private var showSettingSheet = false
    @State private var showShareSheet = false
    @State private var showCoHostInviteSheet = false
    @State private var showCoHostMenuActionSheet = false
    @State private var showProductTagSheet = false
    @State private var showProductSelectionSheet = false
    @State private var previousProductCount = 0
    @State private var isPinnedProductDismissed = false
    
    @ObservedObject var broadcasterViewModel: LiveStreamBroadcasterViewModel
    
    let liveChatFeedHeight = (UIScreen.main.bounds.height - 50) / 5
    
    private var isPinnedProductVisible: Bool {
        viewModel.currentState.isStreaming &&
        (viewModel.liveStreamChatViewModel?.isProductTagEnabled ?? viewModel.isProductTagEnabled) &&
        viewModel.pinnedProductId != nil &&
        !isPinnedProductDismissed
    }
    
    private var isProductTagFeatureEnabled: Bool {
        viewModel.liveStreamChatViewModel?.isProductTagEnabled ?? viewModel.isProductTagEnabled
    }
    
    public init(viewModel: LiveStreamConferenceViewModel, broadcasterViewModel: LiveStreamBroadcasterViewModel) {
        self.viewModel = viewModel
        self.broadcasterViewModel = broadcasterViewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            
            let isPermissionGranted = permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted
            
            if isPermissionGranted {
                VStack(spacing: 0) {
                    LiveStreamBroadcasterView(viewModel: broadcasterViewModel) {
                        coHostOverlayHeaderView
                    }
                    .onChange(of: broadcasterViewModel.room.remoteParticipants.count) { count in
                        if count != 0 {
                            viewModel.invitedCoHost.isWaiting = false
                            broadcasterViewModel.switchCapturerRatio(to: .half)
                        } else {
                            broadcasterViewModel.switchCapturerRatio(to: .full)
                        }
                    }
                    .dismissKeyboardOnDrag()
                    .ignoresSafeArea(.keyboard, edges: .all)
                    
                    if viewModel.invitedCoHost.isWaiting {
                        waitingCoHostView(viewModel.invitedCoHost.user)
                    }
                }
                .padding(.bottom, 21) // footer view has 21 bottom padding
            }
            
            // Overlay State:
            // Permission Request | Denied: Transparent (0%)
            // Permission Granted: Transparent (50%)
            // Stream Started: Transparent (100%)
            let isStreaming = viewModel.currentState.isStreaming
            
            let isBroadcastConnectedState = viewModel.broadcasterState == .connected
            let overlayOpacity = isStreaming && isBroadcastConnectedState && !viewModel.isLiveStreamEndCountdownStarted ? 0 : isPermissionGranted ? 0.5 : 1
            Color.black
                .opacity(overlayOpacity)
                .edgesIgnoringSafeArea(.all)
            
            // Setup View
            let isPermissionDenied = permissionChecker.cameraPermissionState == .denied || permissionChecker.microphonePermissionState == .denied
            ZStack(alignment: .bottom) {
                
                // Stack #1
                // Overlay which covers the home button safe area
                Color.black
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(height: 50)
                    .bottomSheet(isShowing: $showSettingSheet, height: .fixed(300), backgroundColor: Color(viewConfig.defaultDarkTheme.backgroundColor)) {
                        settingBottomSheetView
                    }
                    .bottomSheet(isShowing: $showCoHostMenuActionSheet, height: .contentSize, backgroundColor: Color(viewConfig.defaultDarkTheme.backgroundColor)) {
                        coHostMenuActionSheet
                    }
                    .onChange(of: showProductTagSheet) { isShowing in
                        if isShowing {
                            Task {
                                // Re-fetch network setting before showing any product tag UI
                                await viewModel.checkProductCatalogueSettings()
                                guard viewModel.isProductTagEnabled else {
                                    showProductTagSheet = false
                                    if viewModel.currentState.isStreaming {
                                        liveStreamAlert.show(for: .productTaggingUnavailableWhileStreaming(action: {
                                            LiveStreamAlert.shared.hide()
                                        }))
                                    }
                                    return
                                }
                                
                                if let updatedAt = viewModel.createdPost?.updatedAt,
                                   Date().timeIntervalSince(updatedAt) > 60 {
                                    await viewModel.getPost()
                                }
                                
                                // Check if user can manage products (host or co-host with permission)
                                let canManageProducts = viewModel.participantRole == .host ||
                                (viewModel.participantRole == .coHost && viewModel.isCoHostManageProductTagEnable)
                                
                                if canManageProducts {
                                    // Show manage component for host or co-host with permission
                                    let manageVM = ManageProductTagViewModel()
                                    manageVM.taggedProducts = viewModel.taggedProducts
                                    manageVM.pinnedProductId = viewModel.pinnedProductId
                                    
                                    var manageComponent = ManageProductTagListComponent(
                                    viewModel: manageVM,
                                    onClose: { products in
                                        viewModel.taggedProducts = products
                                        showProductTagSheet = false
                                    },
                                    onAddProducts: {
                                        previousProductCount = manageVM.taggedProducts.count
                                        let productSelectionComponent = AmityProductTagSelectionComponent(
                                            pageId: .createLivestreamPage,
                                            mode: .livestream,
                                            initialSelection: [],
                                            existingProducts: manageVM.taggedProducts.map { $0.productId },
                                            onClose: {
                                                UIApplication.topViewController()?.dismiss(animated: true)
                                            },
                                            onDone: {
                                                if viewModel.currentState.isStreaming, manageVM.taggedProducts.count > previousProductCount {
                                                    // Sync to parent before API call
                                                    viewModel.taggedProducts = manageVM.taggedProducts
                                                    let livestreamPostId = viewModel.createdPost?.childrenPosts.first?.postId ?? viewModel.createdPost?.postId
                                                    if let postId = livestreamPostId {
                                                        Task {
                                                            await viewModel.updateProductTagsAPI(postId: postId)
                                                            // Sync API response back to manageVM
                                                            manageVM.taggedProducts = viewModel.taggedProducts
                                                            manageVM.pinnedProductId = viewModel.pinnedProductId
                                                        }
                                                    }
                                                    UIApplication.topViewController()?.dismiss(animated: true) {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.productTagToastAdded.localizedString, bottomPadding: 60)
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
                                        let hostController = AmitySwiftUIHostingController(rootView: productSelectionComponent
                                            .environmentObject(viewConfig)
                                            .ignoresSafeArea(edges: .bottom))
                                        UIApplication.topViewController()?.present(hostController, animated: true)
                                    },
                                    onPinToggle: { productId, isPinned in
                                        let livestreamPostId = viewModel.createdPost?.childrenPosts.first?.postId ?? viewModel.createdPost?.postId
                                        if viewModel.currentState.isStreaming, let postId = livestreamPostId {
                                            Task {
                                                do {
                                                    if isPinned {
                                                        try await viewModel.pinProductTagAPI(postId: postId, productId: productId)
                                                    } else {
                                                        try await viewModel.unpinProductTagAPI(postId: postId)
                                                    }
                                                    // Sync API response back to manageVM
                                                    manageVM.taggedProducts = viewModel.taggedProducts
                                                    manageVM.pinnedProductId = viewModel.pinnedProductId
                                                    Toast.showToast(style: .success, message: isPinned ? AmityLocalizedStringSet.Social.productTagToastPinned.localizedString : AmityLocalizedStringSet.Social.productTagToastUnpinned.localizedString, bottomPadding: 60)
                                                } catch {
                                                    Toast.showToast(style: .warning, message: isPinned ? AmityLocalizedStringSet.Social.productTagToastPinFailed.localizedString : AmityLocalizedStringSet.Social.productTagToastUnpinFailed.localizedString, bottomPadding: 60)
                                                }
                                            }
                                        } else {
                                            // Setup phase: update locally
                                            manageVM.togglePin(productId)
                                            viewModel.pinnedProductId = isPinned ? productId : nil
                                        }
                                    },
                                    onProductRemove: { productId in
                                        let livestreamPostId = viewModel.createdPost?.childrenPosts.first?.postId ?? viewModel.createdPost?.postId
                                        if viewModel.currentState.isStreaming, let postId = livestreamPostId {
                                            Task {
                                                // Filter out the removed product for API call without local update to manageVM
                                                viewModel.taggedProducts = manageVM.taggedProducts.filter { $0.productId != productId }
                                                if viewModel.pinnedProductId == productId {
                                                    viewModel.pinnedProductId = nil
                                                }
                                                await viewModel.updateProductTagsAPI(postId: postId)
                                                // Sync BE response back to manageVM
                                                manageVM.taggedProducts = viewModel.taggedProducts
                                                manageVM.pinnedProductId = viewModel.pinnedProductId
                                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.productTagToastRemoved.localizedString, bottomPadding: 60)
                                            }
                                        } else {
                                            // Setup phase: update locally
                                            manageVM.deleteProduct(productId)
                                            viewModel.taggedProducts = manageVM.taggedProducts
                                            viewModel.pinnedProductId = manageVM.pinnedProductId
                                        }
                                    }
                                )
                                manageComponent.canAddProducts = viewModel.isProductTagEnabled
                                
                                let hostController = AmitySwiftUIHostingController(rootView: manageComponent
                                    .environmentObject(viewConfig)
                                    .ignoresSafeArea(edges: .bottom))
                                hostController.modalPresentationStyle = .pageSheet
                                
                                let dismissHandler = PresentationDismissHandler()
                                dismissHandler.onDismiss = {
                                    showProductTagSheet = false
                                }
                                hostController.presentationController?.delegate = dismissHandler
                                objc_setAssociatedObject(hostController, "dismissHandler", dismissHandler, .OBJC_ASSOCIATION_RETAIN)
                                
                                UIApplication.topViewController()?.present(hostController, animated: true)
                            } else {
                                // Show view-only component for co-host without permission
                                let productTags = viewModel.taggedProducts.map { product in
                                    AmityProductTagModel(object: product, range: NSRange(location: 0, length: 0), contentType: .media)
                                }
                                
                                let viewOnlyComponent = AmityProductTagListComponent(
                                    pageId: .createLivestreamPage,
                                    productTags: productTags,
                                    renderMode: .livestream,
                                    pinnedProductId: viewModel.pinnedProductId,
                                    sourceId: viewModel.createdRoom?.roomId ?? "",
                                    onClose: {
                                        UIApplication.topViewController()?.dismiss(animated: true)
                                        showProductTagSheet = false
                                    }
                                )
                                
                                let hostController = AmitySwiftUIHostingController(rootView: viewOnlyComponent
                                    .ignoresSafeArea(edges: .bottom))
                                hostController.modalPresentationStyle = .pageSheet
                                
                                let dismissHandler = PresentationDismissHandler()
                                dismissHandler.onDismiss = {
                                    showProductTagSheet = false
                                }
                                hostController.presentationController?.delegate = dismissHandler
                                objc_setAssociatedObject(hostController, "dismissHandler", dismissHandler, .OBJC_ASSOCIATION_RETAIN)
                                
                                UIApplication.topViewController()?.present(hostController, animated: true)
                            }
                            } // end Task
                        }
                    }
                    .sheet(isPresented: $showCoHostInviteSheet, content: {
                        coHostInviteSheetDetentView
                            .ignoresSafeArea(edges: .bottom)
                    })
                    .onChange(of: viewModel.isLiveChatDisabled) { isDisabled in
                        viewModel.editLiveStream(chatDisabled: isDisabled)
                    }
                    .onChange(of: viewModel.isCoHostManageProductTagEnable) { isEnabled in
                        // Co-host: notify when permission is granted
                        if viewModel.participantRole == .coHost {
                            if isEnabled {
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.productTagToastCoHostManageEnabled.localizedString, bottomPadding: 60)
                            }
                            return
                        }
                        
                        // Only host should handle toggle changes with alert
                        guard viewModel.participantRole == .host else { return }
                        
                        if !isEnabled {
                            // Close the settings sheet first, then show alert after delay
                            showCoHostMenuActionSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                liveStreamAlert.show(for: .disableCoHostProductTag(action: {
                                    viewModel.updateCohostProductTag(cohostId: viewModel.invitedCoHost.user?.userId ?? "", canManageProductTag: false)
                                }))
                            }
                        } else {
                            // Enable without alert
                            viewModel.updateCohostProductTag(cohostId: viewModel.invitedCoHost.user?.userId ?? "", canManageProductTag: true)
                        }
                    }
                
                // Stack #2
                // Live Chat Feed View & flowing animated reaction view
                VStack(alignment: .trailing, spacing: 0) {
                    liveReactionView
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                        .allowsHitTesting(false)
                        .id("liveReactionView")
                    
                    liveChatFeedView
                }
                .padding(.bottom, isPinnedProductVisible ? 162 : 80)
                .background(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [Color.black.opacity(0),
                                     Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: UIScreen.main.bounds.height / 3)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                    }
                    .allowsHitTesting(false)
                )
                
                
                // Stack #3
                // Show reaction bar when reaction button in compose bar is long pressed
                if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                    reactionBarOverlay
                        .visibleWhen(liveChatViewModel.showReactionBar)
                }
                
                // Stack #4 Editor
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            headerView
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .opacity(isPermissionDenied ? 0 : 1)
                            
                            LiveStreamSetupView(viewModel: viewModel, permissionChecker: permissionChecker)
                                .onTapGesture {
                                    hideKeyboard()
                                }
                                .opacity(viewModel.currentState != .setup ? 0 : 1)
                        }
                        
                        pendingPostReviewView
                            .visibleWhen(viewModel.createdPost?.getFeedType() == .reviewing && viewModel.currentState != .started)
                        
                        liveStreamStartingState
                            .visibleWhen(viewModel.currentState == .started)
                        
                        // Previous state should be disconnected or connected
                        liveStreamReconnectingState
                            .visibleWhen(viewModel.currentState == .streaming && viewModel.isReconnecting) // We do not want to show reconnecting state when stream is about to end as live timer is still running while it tries to reconnect.
                        
                        liveStreamEndingState
                            .visibleWhen(viewModel.currentState == .ending(reason: .manual))
                        
                        liveStreamEndingCountdownState
                            .visibleWhen(viewModel.isLiveStreamEndCountdownStarted)
                        
                    }
                    
                    // Pinned Product Element (above compose bar) - Only shows during live streaming
                    if isPinnedProductVisible,
                       let pinnedId = viewModel.pinnedProductId,
                       let pinnedProduct = viewModel.taggedProducts.first(where: { $0.productId == pinnedId }) {
                        let canManageProducts = viewModel.participantRole == .host ||
                        (viewModel.participantRole == .coHost && viewModel.isCoHostManageProductTagEnable)
                        
                        LivestreamPinnedProductElement(
                            pageId: .createLivestreamPage,
                            product: pinnedProduct,
                            canManageProduct: canManageProducts,
                            onProductTap: { product, productUrl in
                                let context = AmityGlobalBehavior.Context(host: nil, product: product)
                                AmityUIKit4Manager.behaviour.globalBehavior?.onLivestreamProductTagClick(context: context)
                            },
                            onUnpin: { product in
                                // Call API to unpin during live stream
                                let livestreamPostId = viewModel.createdPost?.childrenPosts.first?.postId ?? viewModel.createdPost?.postId
                                if let postId = livestreamPostId {
                                    Task {
                                        do {
                                            try await viewModel.unpinProductTagAPI(postId: postId)
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.productTagToastUnpinned.localizedString, bottomPadding: 60)
                                        } catch {
                                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.productTagToastUnpinFailed.localizedString, bottomPadding: 60)
                                        }
                                    }
                                }
                            },
                            onDismiss: { _ in },
                            onDelete: { product in
                                let livestreamPostId = viewModel.createdPost?.childrenPosts.first?.postId ?? viewModel.createdPost?.postId
                                if viewModel.currentState.isStreaming, let postId = livestreamPostId {
                                    Task {
                                        // Filter out the removed product for API call, wait for BE response
                                        viewModel.taggedProducts = viewModel.taggedProducts.filter { $0.productId != product.productId }
                                        if viewModel.pinnedProductId == product.productId {
                                            viewModel.pinnedProductId = nil
                                        }
                                        await viewModel.updateProductTagsAPI(postId: postId)
                                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.productTagToastRemoved.localizedString, bottomPadding: 60)
                                    }
                                }
                            },
                            roomId: viewModel.createdRoom?.roomId
                        )
                        .environmentObject(viewConfig)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    Spacer()
                        .allowsHitTesting(false)
                    
                    footerView
                        .padding(.leading, 16)
                        .padding(.trailing, 24)
                        .padding(.vertical, 21)
                        .background(Color.black)
                }
            }
            
            // Stack #3 Permission View
            VStack {
                headerView
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                
                LiveStreamPermissionView(info: .cameraAndMicrophone)
            }
            .opacity(isPermissionDenied ? 1 : 0)
            
            // Stack #4 Post is not approved by moderator
            if case .ended(let reason) = viewModel.currentState, reason == .notApproved {
                PostDetailEmptyStateView(action: {
                    host.controller?.dismiss(animated: true)
                })
                .ignoresSafeArea()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            
            // Update permission status
            permissionChecker.checkCameraAndMicrophonePermissionStatus()
            
            // Check product catalogue settings
            Task {
                await viewModel.checkProductCatalogueSettings()
            }
            
            // Handle Permission Stuffs
            Task {
                if permissionChecker.shouldAskForCameraPermission() {
                    await permissionChecker.requestCameraPermission()
                }
                
                if permissionChecker.shouldAskForMicrophonePermission() && permissionChecker.cameraPermissionState == .granted {
                    await permissionChecker.requestAudioPermission()
                }
            }
        }
        .alert(isPresented: $liveStreamAlert.isPresented, content: {
            if let dismissButton = liveStreamAlert.alertState.dismissButton {
                Alert(title: Text(liveStreamAlert.alertState.title), message: Text(liveStreamAlert.alertState.message), dismissButton: dismissButton)
            } else {
                Alert(title: Text(liveStreamAlert.alertState.title), message: Text(liveStreamAlert.alertState.message), primaryButton: liveStreamAlert.alertState.primaryButton, secondaryButton: liveStreamAlert.alertState.secondaryButton)
            }
        })
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isConnected {
                Toast.showToast(style: .loading, message: "Waiting for network...", bottomPadding: 60, autoHide: false)
            } else {
                Toast.hideToastIfPresented(immediately: true)
            }
        }
        .onChange(of: viewModel.currentState) { newValue in
            switch newValue {
            case .ending(reason: .maxDuration):
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.liveStreamToastEndAtMaxDurationMessage.localizedString, bottomPadding: 60)
                
            case .ended(let reason):
                let postId = viewModel.createdPost?.postId ?? ""
                
                if reason == .manual {
                    
                    self.dismissToPostDetailPage(postId: postId)
                    
                    return
                }
                
                if reason == .connectionIssue {
                    
                    self.dismissToPostDetailPage(postId: postId)

                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.General.noInternetConnection.localizedString, bottomPadding: 60)
                    
                    return
                }
                
                if reason == .maxDuration {
                    liveStreamAlert.show(for: .streamEndedDueToMaxDuration(action: {
                        self.dismissToPostDetailPage(postId: postId)
                    }))
                    return
                }
                
                // Show terminated page
                if reason == .terminated {
                    let terminatedVc = AmitySwiftUIHostingController(rootView: AmityLivestreamTerminatedPage(type: .streamer))
                    terminatedVc.modalPresentationStyle = .overFullScreen
                    self.host.controller?.navigationController?.pushViewController(terminatedVc, animated: false)
                    return
                }
                
                if reason == .coHostLeave {
                    self.host.controller?.dismissOrPop()
                }
                
            default:
                break
            }
        }
    }
    
    func dismissToPostDetailPage(postId: String) {
        self.host.controller?.dismiss(animated: true, completion: {
            
            // Move to post detail page
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let postDetailPage = AmityPostDetailPage(id: postId)
                let topController = UIApplication.topViewController()
                topController?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: postDetailPage))
            }
        })
    }
    
    @ViewBuilder
    var liveStreamStartingState: some View {
        VStack {
            Spacer()
            
            LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                .frame(width: 40, height: 40)
            
            Text(AmityLocalizedStringSet.Social.liveStreamStartingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    var liveStreamReconnectingState: some View {
        VStack {
            Spacer()
            
            LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                .frame(width: 40, height: 40)
            
            Text(AmityLocalizedStringSet.Social.liveStreamReconnectingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            Text(AmityLocalizedStringSet.Social.liveStreamReconnectingStateMessage.localizedString)
                .applyTextStyle(.caption(Color.white))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    var liveStreamEndingState: some View {
        VStack {
            Spacer()
            
            LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                .frame(width: 40, height: 40)
            
            Text(AmityLocalizedStringSet.Social.liveStreamEndingStreamTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    var liveStreamEndingCountdownState: some View {
        VStack {
            Spacer()
            
            Text(AmityLocalizedStringSet.Social.liveStreamEndingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            LiveStreamCountdownTimer(totalCountdown: 10, currentCountdown: $viewModel.liveStreamEndCountdown)
                .frame(width: 72, height: 72)
                .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    
    @ViewBuilder
    var headerView: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Button {
                        if viewModel.currentState == .setup {
                            let dismissAction = {
                                host.controller?.dismiss(animated: true)
                            }
                            if !viewModel.streamDescription.isEmpty || !viewModel.streamTitle.isEmpty || viewModel.selectedImage != nil {
                                liveStreamAlert.show(for: .streamDiscard(action: {
                                    dismissAction()
                                }))
                            } else {
                                dismissAction()
                            }
                        } else {
                            if viewModel.participantRole == .host {

                                liveStreamAlert.show(for: .streamEndedManually(action: {
                                    viewModel.endLiveStream(reason: .manual)
                                }))
                            } else {
                                liveStreamAlert.show(for: .coHostLeave(action: {
                                    viewModel.endLiveStream(reason: .coHostLeave)
                                }))
                            }
                        }
                    } label: {
                        Image(AmityIcon.LiveStream.close.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: viewModel.createdEvent == nil ? 24 : 32, height: viewModel.createdEvent == nil ? 24 : 32)
                            .foregroundColor(Color.white)
                            .circularBackground(radius: 32, color: viewModel.createdEvent == nil ? .black.opacity(0.5) : .clear)
                            .padding(.bottom, 4)
                    }
                    
                    Image(AmityIcon.LiveStream.unmuteMic.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .circularBackground(radius: 34, color: .black.opacity(0.4))
                        .offset(x: 4, y: 46)
                        .visibleWhen(!broadcasterViewModel.enableMicrophone && viewModel.currentState == .streaming && viewModel.participantRole == .host)
                }
                
                Spacer(minLength: 8)
                
                if viewModel.currentState == .setup {
                    if let event = viewModel.createdEvent {
                        HStack(spacing: 8) {
                            AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource,
                                       url: URL(string: event.coverImage?.mediumFileURL ?? ""),
                                       contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                // Event title
                                Text(event.title)
                                    .applyTextStyle(.bodyBold(Color.white))
                                    .lineLimit(1)
                                
                                // Event Creator info
                                if let creator = event.creator {
                                    HStack(spacing: 4) {
                                        Text("By \(creator.displayName ?? "")")
                                            .applyTextStyle(.caption(Color.white))
                                            .lineLimit(1)
                                        
                                        Image(AmityIcon.brandBadge.imageResource)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .opacity(creator.isBrand ? 1 : 0)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    } else {
                        Button {
                            let context = AmityLivestreamPostTargetSelectionPage.Context(onSelection: { selectedTarget in
                                if let selectedTarget {
                                    viewModel.targetDisplayName = selectedTarget.displayName
                                    viewModel.targetType = .community
                                } else {
                                    viewModel.targetDisplayName = AmityLocalizedStringSet.Social.liveStreamMyTimelineLabel.localizedString
                                    viewModel.targetType = .user
                                }
                            }, isOpenedFromLiveStreamPage: true)
                            let view = AmityLivestreamPostTargetSelectionPage(context: context)
                            let controller = AmitySwiftUIHostingController(rootView: view)
                            controller.modalPresentationStyle = .fullScreen
                            host.controller?.navigationController?.present(controller, animated: true)
                        } label: {
                            HStack(alignment: .center, spacing: 4) {
                                Text(AmityLocalizedStringSet.Social.liveStreamTargetLiveOnLabel.localizedString)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(Color.white)
                                    .lineLimit(1)
                                
                                Text(viewModel.targetDisplayName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color.white)
                                    .lineLimit(1)
                                
                                Image(AmityIcon.LiveStream.targetSelectionArrow.imageResource)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(Color.white)
                            }
                        }
                    }
                } else {
                    // Backup view to maintain header height
                    Color
                        .clear
                        .frame(width: 1, height: 40)
                    
                    HStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(AmityIcon.Chat.membersCount.imageResource)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 16, height: 14)
                                .foregroundColor(Color.white)
                            
                            Text("\(viewModel.watchingCount.formattedCountString)")
                                .applyTextStyle(.captionBold(.white))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4, corners: .allCorners)
                        .visibleWhen(viewModel.watchingCount > 0 && viewModel.currentState.isStreaming)
                        
                        Text(AmityLocalizedStringSet.Social.liveStreamDurationLabel.localized(arguments: "\(viewModel.liveDuration)"))
                            .applyTextStyle(.captionBold(.white))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#FF305A"))
                            .cornerRadius(4, corners: .allCorners)
                            .visibleWhen(viewModel.currentState.isStreaming)
                    }
                    
                    Button {
                        showSettingSheet.toggle()
                    } label: {
                        Image(AmityIcon.threeDotIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .rotationEffect(.degrees(90))
                            .frame(width: 32, height: 28)
                            .foregroundColor(Color.white)
                    }
                    .sheet(isPresented: $showShareSheet) {
                        let profileLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .livestream, id: viewModel.createdPost?.postId ?? "")
                        ShareActivitySheetView(link: profileLink)
                    }
                    .isHidden(viewModel.targetType == .user)
                }
            }
            
            if viewModel.participantRole == .coHost {
                HStack(spacing: 0) {
                    headerMetadataView
                    Spacer(minLength: 160)
                }
                .padding(.leading, 36)
                .allowsHitTesting(false)
            }
        }
    }
    
    @ViewBuilder
    var headerMetadataView: some View {
        HStack(spacing: 8) {
            if let event = viewModel.createdEvent {
                HStack(spacing: 8) {
                    AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource,
                               url: URL(string: event.coverImage?.mediumFileURL ?? ""),
                               contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Event title
                        Text(event.title)
                            .applyTextStyle(.bodyBold(Color.white))
                            .lineLimit(1)
                        
                        // Event Creator info
                        if let creator = event.creator {
                            HStack(spacing: 4) {
                                Text("By \(creator.displayName ?? "")")
                                    .applyTextStyle(.caption(Color.white))
                                    .lineLimit(1)
                                
                                Image(AmityIcon.brandBadge.imageResource)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .opacity(creator.isBrand ? 1 : 0)
                            }
                        }
                    }
                }
            } else if case .community(_, let community) = viewModel.createdRoom?.target, let community {
                AsyncImage(placeholder: AmityIcon.defaultCommunity.imageResource,
                           url: URL(string: community.avatar?.mediumFileURL ?? ""),
                           contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    // Community name
                    HStack(spacing: 4) {
                        Image(AmityIcon.lockBlackIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 18)
                            .foregroundColor(Color.white)
                            .isHidden(community.isPublic)
                        
                        Text(community.displayName)
                            .applyTextStyle(.bodyBold(Color.white))
                            .lineLimit(1)
                        
                        Image(AmityIcon.verifiedBadge.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .opacity(community.isOfficial ? 1 : 0)
                            .layoutPriority(1)
                    }
                    
                    // Streamer info
                    if let streamer = viewModel.createdRoom?.creator {
                        HStack(spacing: 4) {
                            Text("By \(streamer.displayName ?? "")")
                                .applyTextStyle(.caption(Color.white.opacity(0.8)))
                                .lineLimit(1)
                            
                            Image(AmityIcon.brandBadge.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .opacity(streamer.isBrand ? 1 : 0)
                                .layoutPriority(1)
                        }
                    }
                }
            } else if viewModel.createdRoom?.targetType == "user", let user = viewModel.createdRoom?.creator {
                AmityUserProfileImageView(
                    displayName: user.displayName ?? "",
                    avatarURL: URL(string: user.avatar?.mediumFileURL ?? "")
                )
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                HStack(spacing: 4) {
                    Text(user.displayName ?? "")
                        .applyTextStyle(.bodyBold(Color.white))
                        .lineLimit(1)
                    
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .opacity(user.isBrand ? 1 : 0)
                        .layoutPriority(1)
                }
            }
        }
    }
    
    @ViewBuilder
    var footerView: some View {
        if viewModel.currentState == .setup {
            setupComposeBar
        } else {
            // Hide chat if it is on userfeed for now and post is in reviewing state
            if viewModel.liveStreamChatViewModel?.isStreamer ?? false && (viewModel.createdRoom?.targetType != "community" || viewModel.createdPost?.getFeedType() == .reviewing) {
                defaultComposeBar
            } else if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                AmityLiveStreamChatComposeBar(viewModel: liveChatViewModel)
                    .onAppear {
                        liveChatViewModel.inviteCoHostAction = {
                            showCoHostInviteSheet.toggle()
                        }
                        
                        liveChatViewModel.isWaitingCoHost = { [weak viewModel] in
                            return (viewModel?.invitedCoHost.isWaiting ?? false, viewModel?.invitedCoHost.user?.userId ?? "")
                        }
                        
                        liveChatViewModel.removeCoHostAction = {
                            showCoHostMenuActionSheet.toggle()
                        }
                        
                        liveChatViewModel.didFinishCoHostInvitationAction = { [weak viewModel] user in
                            viewModel?.invitedCoHost = (true, user, false)
                        }
                        
                        liveChatViewModel.swapCameraAction = { [weak viewModel] in
                            viewModel?.switchCamera()
                        }
                        
                        liveChatViewModel.isMicOn = broadcasterViewModel.enableMicrophone
                        liveChatViewModel.toggleMicAction = { [weak viewModel] in
                            viewModel?.toggleMicrophone()
                        }
                        
                        liveChatViewModel.productCount = viewModel.taggedProducts.count
                        liveChatViewModel.isProductTagEnabled = viewModel.isProductTagEnabled
                            liveChatViewModel.showProductTagAction = {
                                showProductTagSheet = true
                            }
                    }
                    .onChange(of: viewModel.taggedProducts.count) { newCount in
                        liveChatViewModel.productCount = newCount
                    }
                    .onChange(of: viewModel.isProductTagEnabled) { isEnabled in
                        liveChatViewModel.isProductTagEnabled = isEnabled
                    }
                    .onChange(of: viewModel.pinnedProductId) { newPinnedId in
                        // Reset dismissal when pinned product changes
                        isPinnedProductDismissed = false
                    }
            } else {
                defaultComposeBar
            }
        }
    }
    
    @ViewBuilder
    var thumbnailButton: some View {
        
        if let selectedImage = viewModel.selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 40)
                .clipped()
                .continuousCornerRadius(4)
                .border(radius: 4, borderColor: .white, borderWidth: 1)
                .overlay(
                    ZStack {
                        Color.black.opacity(0.5)
                        
                        LiveStreamCircularProgressBar(progress: $viewModel.thumbnailUploadProgress, config: LiveStreamCircularProgressBar.Config(backgroundColor: UIColor.white.withAlphaComponent(0.5), foregroundColor: UIColor.white, strokeWidth: 2, shouldAutoRotate: true))
                            .frame(width: 24, height: 24)
                    }
                        .opacity(viewModel.isUploadingThumbnail && viewModel.thumbnailUploadProgress <= 100 ? 1 : 0)
                )
                .onTapGesture {
                    pickerViewModel.selectedImages = []
                    
                    showThumbnailEditSheet.toggle()
                }
        } else {
            Button {
                showMediaPicker.toggle()
            } label: {
                Image(AmityIcon.LiveStream.livestreamAddThumbnailButtonIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 70, height: 40)
                    .continuousCornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(viewConfig.defaultDarkTheme.baseColorShade3), lineWidth: 1)
                    )
                    .background(Color(viewConfig.defaultDarkTheme.baseColorShade4).opacity(0.5))
            }
        }
    }
    
    @ViewBuilder
    private var liveReactionView: some View {
        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
            LiveReactionView(viewModel: liveChatViewModel.liveReactionViewModel)
                .frame(width: liveChatViewModel.liveReactionViewModel.width, height: liveChatViewModel.isTextEditorFocused ? 0.1 : liveChatViewModel.liveReactionViewModel.height)
                .visibleWhen(viewModel.createdRoom?.targetType == "community" && viewModel.currentState != .setup)
        }
    }
    
    @ViewBuilder
    private var liveChatFeedView: some View {
        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
            AmityLiveStreamChatFeed(viewModel: liveChatViewModel, pageId: .createLivestreamPage)
                .frame(height: liveChatViewModel.isTextEditorFocused ? 0.1 : liveChatFeedHeight)
                .visibleWhen(viewModel.createdRoom?.targetType == "community" && viewModel.currentState != .setup)
                .visibleWhen(liveChatViewModel.isTextEditorFocused == false)
        }
    }
    
    @ViewBuilder
    private var reactionBarOverlay: some View {
        ZStack {
            // Full screen overlay with tap gesture to dismiss
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.liveStreamChatViewModel?.showReactionBar = false
                    }
                }
            
            // Reaction bar positioned at trailing bottom
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AmityReactionBar(targetType: viewModel.createdRoom?.referenceType ?? "", targetId: viewModel.createdRoom?.referenceId ?? "", streamId: viewModel.createdRoom?.roomId ?? "", onReactionTap: { reaction in
                        if let liveChatViewModel = viewModel.liveStreamChatViewModel {
                            liveChatViewModel.liveReactionViewModel.addReaction(reaction)
                            
                            // Hide reaction bar after selection
                            withAnimation(.easeOut(duration: 0.2)) {
                                liveChatViewModel.showReactionBar = false
                            }
                        }
                    })
                    .padding(.trailing, 24)
                    .scaleEffect(viewModel.liveStreamChatViewModel?.showReactionBar ?? false  ? 1.0 : 0.0, anchor: .bottomTrailing)
                    .padding(.bottom, 58)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var setupComposeBar: some View {
        HStack(spacing: 10) {
            thumbnailButton
                .bottomSheet(isShowing: $showThumbnailEditSheet, height: .contentSize, sheetContent: {
                    VStack(spacing: 0) {
                        BottomSheetItemView(icon: AmityIcon.LiveStream.thumbnail.imageResource, text: AmityLocalizedStringSet.Social.liveStreamChangeThumbnailLabel.localizedString).onTapGesture {
                            showThumbnailEditSheet.toggle()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showMediaPicker.toggle()
                            }
                        }
                        
                        BottomSheetItemView(icon: AmityIcon.trashBinRedIcon.imageResource, text: AmityLocalizedStringSet.Social.liveStreamDeleteThumbnailLabel.localizedString, iconSize: CGSize(width: 20, height: 18), isDestructive: true).onTapGesture {
                            showThumbnailEditSheet.toggle()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.selectedImage = nil
                            }
                        }
                    }
                    .padding(.bottom, 64)
                })
                .fullScreenCover(isPresented: $showMediaPicker, content: {
                    MultiSelectionMediaPicker(viewModel: pickerViewModel, mediaType: .constant(.images), sourceType: .constant(.photoLibrary), selectionLimit: 1)
                })
                .onChange(of: pickerViewModel.selectedImages) { newValue in
                    guard !newValue.isEmpty else { return }
                    viewModel.selectedImage = newValue.first
                    
                    // Upload thumbnail
                    viewModel.uploadThumbnail(image: newValue.first)
                }
                .opacity(viewModel.createdEvent == nil ? 1 : 0)
            
            Spacer()
            
            // Product Tagging Button - only show if enabled from network settings and not on user feed
            ProductTaggingButtonElement(productCount: viewModel.taggedProducts.count) {
                showProductTagSheet = true
            }
            .isHidden(viewModel.targetType == .user || !viewModel.isProductTagEnabled)
            
            Button {
                showSettingSheet.toggle()
            } label: {
                Image(AmityIcon.settingIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
            .isHidden(viewModel.targetType == .user)
            
            Button {
                viewModel.toggleMicrophone()
            } label: {
                Image(broadcasterViewModel.enableMicrophone ? AmityIcon.LiveStream.mic.imageResource : AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
            
            Button {
                viewModel.switchCamera()
            } label: {
                Image(AmityIcon.LiveStream.switchCamera.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
        }
    }
    
    @ViewBuilder
    private var defaultComposeBar: some View {
        HStack(spacing: 10) {
            Spacer()
            
            // Show invite button if the user is main host who created the room
            // Only show when it is not user feed and post is not in reviewing state
            if viewModel.createdRoom?.creatorId == AmityUIKitManagerInternal.shared.currentUserId && viewModel.participantRole == .host &&
                viewModel.createdRoom?.post?.targetUser == nil && viewModel.createdPost?.getFeedType() != .reviewing {
                Button {
                    showCoHostInviteSheet.toggle()
                } label: {
                    Image(AmityIcon.inviteUserIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
                }
            }
            
            // Product Tagging Button - only show if enabled from network settings and not on user feed
            ProductTaggingButtonElement(productCount: viewModel.taggedProducts.count) {
                showProductTagSheet = true
            }
            .isHidden(viewModel.targetType == .user || !viewModel.isProductTagEnabled)
            
            Button {
                viewModel.toggleMicrophone()
            } label: {
                Image(broadcasterViewModel.enableMicrophone ? AmityIcon.LiveStream.mic.imageResource : AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
            
            Button {
                viewModel.switchCamera()
            } label: {
                Image(AmityIcon.LiveStream.switchCamera.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
        }
    }
    
    @ViewBuilder
    private var settingBottomSheetView: some View {
        VStack(spacing: 0) {
            if viewModel.participantRole == .host {
                SettingToggleButtonView(isEnabled: $viewModel.isLiveChatDisabled,
                                        title: AmityLocalizedStringSet.Social.liveStreamSettingReadOnlyTitle.localizedString,
                                        description: AmityLocalizedStringSet.Social.liveStreamSettingReadOnlyDescription.localizedString)
                    .contentShape(Rectangle())
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
            }
            
            if AmityUIKitManagerInternal.shared.canShareLink(for: .livestream) {
                shareableLinkItemView
            }
            
            Spacer()
        }
        .padding(.bottom, 64)
    }
    
    @ViewBuilder
    var shareableLinkItemView: some View {
        let copyLinkConfig = viewConfig.forElement(.copyLink)
        let shareLinkConfig = viewConfig.forElement(.shareLink)
        
        BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? "", tintColor: .white)
            .onTapGesture {
                showSettingSheet.toggle()
                
                let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .post, id: viewModel.createdPost?.postId ?? "")
                UIPasteboard.general.string = shareLink
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoLinkCopied.localizedString, bottomPadding: 60)
                }
            }
        
        BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? "", tintColor: .white)
            .onTapGesture {
                showSettingSheet.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showShareSheet = true
                }
            }
    }
    
    private var pendingPostReviewView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // Icon
            Image(AmityIcon.blindIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 36)
                .foregroundColor(.white)
            
            // Title
            Text(AmityLocalizedStringSet.Social.liveStreamWaitingForApprovalTitle.localizedString)
                .applyTextStyle(.titleBold(.white))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            // Description
            Text(AmityLocalizedStringSet.Social.liveStreamWaitingForApprovalMessage.localizedString)
                .applyTextStyle(.caption(.white))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private func waitingCoHostView(_ user: AmityUserModel?) -> some View {
        ZStack(alignment: .top) {
            // Center content with image and text
            VStack(spacing: 20) {
                Spacer()
                
                AmityUserProfileImageView(displayName: user?.displayName ?? "CoHost", avatarURL: URL(string: user?.avatarURL ?? ""))
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                
                Text(AmityLocalizedStringSet.Social.liveStreamWaitingForCoHost.localizedString)
                    .applyTextStyle(.custom(17, .regular, .white))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 200)
                
                Spacer()
                Spacer()
            }
            
            // Header view
            coHostOverlayHeaderView
        }
        .background(Color(viewConfig.defaultDarkTheme.baseColorShade3))
    }
    
    @ViewBuilder
    private var coHostOverlayHeaderView: some View {
        HStack(spacing: 0) {
            let displayName = viewModel.participantRole == .host ? viewModel.invitedCoHost.user?.displayName : AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName
            let isCoHostBrand = viewModel.invitedCoHost.user?.isBrand ?? false
            let isCurrentUserBrand = AmityUIKitManagerInternal.shared.client.user?.snapshot?.isBrand ?? false
            let isBrandUser = viewModel.participantRole == .host ? isCoHostBrand : isCurrentUserBrand
            
            HStack(spacing: 4) {
                Text(displayName ?? "Co-Host")
                    .applyTextStyle(.body(.white))
                    .lineLimit(1)
                
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .isHidden(!isBrandUser)
                
                Image(AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 16, height: 16)
                    .isHidden(!(!broadcasterViewModel.enableMicrophone && viewModel.currentState == .streaming && viewModel.participantRole == .coHost))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20, corners: .allCorners)
            
            Spacer()
            
            Button {
                showCoHostMenuActionSheet.toggle()
            } label: {
                Image(AmityIcon.threeDotIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(90))
                    .frame(width: 32, height: 28)
                    .foregroundColor(Color.white)
                    .circularBackground(radius: 32, color: Color.black.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.all, 16)
    }
    
    @ViewBuilder
    private var coHostMenuActionSheet: some View {
        VStack(spacing: 0) {
            if viewModel.participantRole == .host {
                
                // Show cancel invitation if the invited co-host is still waiting and has not accepted yet
                if viewModel.invitedCoHost.isWaiting && viewModel.invitedCoHost.invitationAccepted == false {
                    Text(viewModel.invitedCoHost.user?.displayName ?? "Invite co-host")
                        .applyTextStyle(.titleBold(.white))
                    
                    Rectangle()
                        .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                        .frame(height: 1)
                        .padding(.top, 12)
                    
                    BottomSheetItemView(icon: AmityIcon.unfollowingUserIcon.imageResource, text: "Cancel invitation", isDestructive: true)
                        .onTapGesture {
                            // Remove co-host action
                            showCoHostMenuActionSheet.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                liveStreamAlert.show(for: .cancelCoHostInvitation(action: {
                                    viewModel.invitedCoHost = (false, nil, false)
                                    Task.runOnMainActor {
                                        await viewModel.cancelCoHostInvitation()
                                    }
                                }))
                            }
                        }
                } else {
                    Text(viewModel.invitedCoHost.user?.displayName ?? "CoHost")
                        .applyTextStyle(.titleBold(.white))
                    
                    CoHostBadgeView()
                        .padding(.top, 8)
                    
                    Rectangle()
                        .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                        .frame(height: 1)
                        .padding(.top, 12)
                    
                    SettingToggleButtonView(isEnabled: $viewModel.isCoHostManageProductTagEnable,
                                            title: "Allow co-host to manage product tags",
                                            description: "When enabled, co-host can add or remove tagged products and pin or unpin a product during the live stream.")
                        .contentShape(Rectangle())
                        .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
                        .isHidden(!viewModel.isProductTagEnabled)
                    
                    
                    BottomSheetItemView(icon: AmityIcon.unfollowingUserIcon.imageResource, text: "Remove from live", isDestructive: true)
                        .onTapGesture {
                            // Remove co-host action
                            showCoHostMenuActionSheet.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                liveStreamAlert.show(for: .removeCoHost(action: {
                                    Task.runOnMainActor {
                                        await viewModel.removeCoHostFromStream(userId: viewModel.invitedCoHost.user?.userId ?? "")
                                    }
                                }))
                            }
                        }
                }
                    
            } else if viewModel.participantRole == .coHost {
                BottomSheetItemView(icon: AmityIcon.LiveStream.leaveIcon.imageResource, text: "Leave as co-host", isDestructive: true)
                    .onTapGesture {
                        // Co-Host leave action
                        showCoHostMenuActionSheet.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            liveStreamAlert.show(for: .leaveAsCoHost(action: {
                                viewModel.endLiveStream(reason: .leaveAsCoHost)
                            }))
                        }
                    }
            }
        }
        .padding(.bottom, 64)
    }
    
    @ViewBuilder
    private var coHostInviteSheetDetentView: some View {
        coHostInviteSheetView
            .halfSheetPresentation()
    }
    
    @ViewBuilder
    private var coHostInviteSheetView: some View {
        if let room = viewModel.createdRoom {
            LiveStreamCoHostInviteSheet(conferenceViewModel: viewModel, onDismiss: {
                showCoHostInviteSheet.toggle()
            })
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct LiveStreamSetupView: View {
    
    @ObservedObject var viewModel: LiveStreamConferenceViewModel
    @ObservedObject var permissionChecker: LiveStreamPermissionChecker
    @StateObject var networkMonitor = NetworkMonitor()
    
    private let liveStreamTitleCharLimit = 30
    
    var body: some View {
        VStack(spacing: 0) {
            let isPermissionGranted = permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    titleTextField
                        .padding(.top, 16)
                    
                    descTextField
                        .padding(.top, 12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .opacity((isPermissionGranted && viewModel.currentState == .setup && viewModel.createdEvent == nil) ? 1 : 0)
            
            Button {
                // Check product catalogue settings before starting stream
                Task {
                    await viewModel.checkProductCatalogueSettings()
                    
                    // Check if product tagging is disabled but products are tagged
                    if !viewModel.isProductTagEnabled && !viewModel.taggedProducts.isEmpty {
                        // Show specific alert for disabled product tagging with option to go live
                        viewModel.taggedProducts.removeAll()
                        viewModel.pinnedProductId = nil
                        LiveStreamAlert.shared.show(for: .productTaggingDisabled(action: {
                            // User chose to go live - remove products and start stream
                            hideKeyboard()
                            viewModel.startStream(
                                title: viewModel.streamTitle,
                                description: viewModel.streamDescription
                            )
                        }))
                        return
                    }
                    
                    guard networkMonitor.isConnected else {
                        LiveStreamAlert.shared.show(for: .streamError)
                        return
                    }
                    
                    hideKeyboard()
                    viewModel.startStream(
                        title: viewModel.streamTitle,
                        description: viewModel.streamDescription
                    )
                }
            } label: {
                let isShutterButtonDisabled = viewModel.streamTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isUploadingThumbnail
                Image(isShutterButtonDisabled ? AmityIcon.LiveStream.shutterButtonDisabled.imageResource : AmityIcon.LiveStream.shutterButtonEnabled.imageResource)
            }
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var titleTextField: some View {
        ZStack(alignment: .leading) {
            Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamTitle.localizedString)
                .foregroundColor(Color.white.opacity(0.8))
                .font(.system(size: 24, weight: .bold))
                .opacity(viewModel.streamTitle.isEmpty ? 1 : 0)
            
            TextField("", text: $viewModel.streamTitle)
                .foregroundColor(Color.white)
                .font(.system(size: 24, weight: .bold))
                .onChange(of: viewModel.streamTitle) { newValue in
                    guard newValue.count > liveStreamTitleCharLimit else { return }
                    viewModel.streamTitle = String(newValue.prefix(liveStreamTitleCharLimit))
                }
        }
    }
    
    @ViewBuilder
    private var descTextField: some View {
        if #available(iOS 16.0, *) {
            ZStack(alignment: .leading) {
                Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamDesc.localizedString)
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.system(size: 15, weight: .regular))
                    .opacity(viewModel.streamDescription.isEmpty ? 1 : 0)
                
                TextField("", text: $viewModel.streamDescription, axis: .vertical)
                    .foregroundColor(Color.white)
                    .font(.system(size: 15, weight: .regular))
            }
        } else {
            ZStack(alignment: .leading) {
                Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamDesc.localizedString)
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.system(size: 15, weight: .regular))
                    .opacity(viewModel.streamDescription.isEmpty ? 1 : 0)
                
                TextField("", text: $viewModel.streamDescription)
                    .foregroundColor(Color.white)
                    .font(.system(size: 15, weight: .regular))
            }
        }
    }
}


