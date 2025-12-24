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
        if let room = viewModel.post?.room {
            LiveStreamPlaybackPlayerView(room: room)
                .ignoresSafeArea(.all)
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
