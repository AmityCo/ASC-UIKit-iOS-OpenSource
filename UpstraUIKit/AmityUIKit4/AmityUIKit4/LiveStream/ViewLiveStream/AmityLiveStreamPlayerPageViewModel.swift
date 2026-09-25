//
//  AmityLiveStreamPlayerPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/24/25.
//

import Foundation
import Combine
import AmitySDK

public class AmityLiveStreamPlayerPageViewModel: ObservableObject {

    enum PageState: Equatable {
        case viewer
        case inBackstage
        case streamingAsCoHost
    }
    
    @Published var currentState: PageState = .viewer {
        didSet {
            handleStateTransition(from: oldValue, to: currentState)
        }
    }
    @Published var showInvitedAsCoHostSheet: Bool = false {
        didSet {
            // While the co-host invitation sheet is visible, PiP must not start
            // (a floating window would cover the sheet / duplicate the stream).
            // Suppresses the OS auto-start; re-enabled when the sheet dismisses.
            PiPState.shared.setAutoPiPSuppressed(showInvitedAsCoHostSheet)
        }
    }

    deinit {
        if showInvitedAsCoHostSheet {
            PiPState.shared.setAutoPiPSuppressed(false)
        }
    }
    
    private var roomManager = RoomManager()
    private var postManager = PostManager()
    private var invitationManager = InvitationManager()
    @Published var post: AmityPostModel?
    @Published var room: AmityRoom? {
        didSet {
            if room?.status == .live || room?.status == .waitingReconnect {
                wasEverLive = true
            }
        }
    }
    @Published private(set) var wasEverLive = false
    private var cancellable: AnyCancellable?
    
    // Watch minute tracking for role transitions
    private let watchMinuteTracker = WatchMinuteTracker()
    
    // ViewModels
    @Published var broadcasterViewModel: LiveStreamBroadcasterViewModel?
    @Published var livestreamViewerViewModel: LiveStreamViewerViewModel?
    @Published var conferenceViewModel: LiveStreamConferenceViewModel?
    
    // live object notification
    private var roomNotification: AmityNotificationToken?
    private var postNotification: AmityNotificationToken?
    
    // Loading state
    @Published var isLoading: Bool = false

    // Set to true when the room/post backing this player cannot be loaded
    // (e.g. the parent post was hidden or deleted). Drives the error state.
    @Published var loadingFailed: Bool = false
    
    @Published var coHostInvitation: AmityInvitation?
    @Published var isJoinSheetDismissedOnAction: Bool = false
    @Published var isProductTagEnabled: Bool = false
    @Published var updatedChildPost: AmityPost? = nil
    @Published var taggedProducts: [AmityProduct] = []
    @Published var pinnedProductId: String? = nil
    var previousProductCount: Int = 0
    
    public init(post: AmityPostModel) {
        self.post = post
        self.room = post.room
        
        setupViewModels(post)
        
        // Observe invitation for co-host
        if let room {
            observeCoHostEvents(room: room)
        }
    }
    
    public init(roomId: String, isCohostInvited: Bool = false) {
        self.isLoading = true
        roomNotification = roomManager.getRoom(roomId: roomId)
            .observeOnce({ [weak self] object, error in
                guard let self else { return }

                // Room could not be loaded (e.g. parent post hidden/deleted) -> show error state
                guard error == nil, let room = object.snapshot else {
                    self.handleLoadFailure()
                    return
                }

                postNotification = postManager.getPost(withId: room.referenceId ?? "")
                    .observeOnce({ [weak self] object, error in
                        guard let self else { return }

                        // Backing post could not be loaded (e.g. it was hidden/deleted) -> show error state
                        guard error == nil, let post = object.snapshot, !post.isDeleted else {
                            self.handleLoadFailure()
                            return
                        }

                        let postModel = AmityPostModel(post: post)
                        self.post = postModel
                        self.room = postModel.room
                        
                        setupViewModels(postModel)
                        
                        // Observe invitation for co-host
                        self.observeCoHostEvents(room: room)
                        
                        self.isLoading = false
                        
                        // check invitaion is pending if the room is live
                        if room.status == .live || room.status == .waitingReconnect {
                            Task.runOnMainActor {
                                let invitation = await room.getInvitation()
                                self.coHostInvitation = invitation
                                if let invitation, invitation.status == .pending  {
                                    self.showInvitedAsCoHostSheet = true
                                } else if let invitation, invitation.status == .canceled ||  invitation.status == .rejected {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationNoLongerValid.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
                                }
                              else if isCohostInvited, invitation == nil {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationNoLongerValid.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
                                }
                            }
                        }
                        
                        postNotification?.invalidate()
                        roomNotification?.invalidate()
                    })
            })
    }
    
    /// Surfaces the unavailable-content error state when the room/post cannot be loaded.
    private func handleLoadFailure() {
        isLoading = false
        loadingFailed = true
        postNotification?.invalidate()
        roomNotification?.invalidate()
    }

    private func setupViewModels(_ postModel: AmityPostModel) {
        let broadcasterViewModel = LiveStreamBroadcasterViewModel(role: .coHost)
        
        self.broadcasterViewModel = broadcasterViewModel
        self.conferenceViewModel = LiveStreamConferenceViewModel(targetId: postModel.targetId, targetType: postModel.postTargetType, participantRole: .coHost, broadcasterViewModel: broadcasterViewModel)
        let livestreamPostModel: AmityPostModel
        if let childPost = postModel.childrenPosts.first {
            livestreamPostModel = AmityPostModel(post: childPost)
        } else {
            livestreamPostModel = postModel
        }
        self.livestreamViewerViewModel = LiveStreamViewerViewModel(post: livestreamPostModel, tracker: watchMinuteTracker)
    }
    
    private func observeCoHostEvents(room: AmityRoom) {
        cancellable = nil
        cancellable = roomManager.getCoHostEvent(roomId: room.roomId)
            .sink(receiveValue: { [weak self] event in
                
                // Handle co-host removed event when current user is in backstage
                // we can assume that the current user is co-host if they are in backstage
                if event.type == .coHostRemoved && self?.currentState == .inBackstage {
                    self?.currentState = .viewer
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamLeftStageToast.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
                }
                
                // Display co-host left toast if the user is a viewer when co-host left
                if event.type == .coHostLeft && self?.currentState == .viewer && event.room.status == .live {
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamCoHostLeftToast.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
                }
                
                // Ensure the invitation is for the current user since BE is sending events to all users in the room
                guard event.invitation?.invitedUserId == AmityUIKitManagerInternal.shared.client.currentUserId else { return }
                
                Log.add(event: .info, "Received co-host invitation with status: \(event.invitation?.status.rawValue ?? "nil")")
                self?.coHostInvitation = event.invitation
                
                // Handle UI state accordingly
                if event.type == .invitationInvited {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    // The co-host invitation sheet is about to show on this page —
                    // close any floating window so it doesn't cover the sheet or
                    // duplicate the stream. Only while in the foreground: an invite
                    // arriving while the user watches in background PiP must not
                    // kill their playback.
                    if UIApplication.shared.applicationState == .active {
                        PiPState.shared.stopActivePiPForExcludedSurface()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self?.showInvitedAsCoHostSheet = true
                    }
                } else if event.type == .invitationCancelled {
                    self?.isJoinSheetDismissedOnAction = true
                    self?.showInvitedAsCoHostSheet = false
                }
            })
    }

    func acceptCoHostInvitation() {
        Task.runOnMainActor {
            do {
                self.showInvitedAsCoHostSheet = false
                try await self.coHostInvitation?.accept()
                self.currentState = .inBackstage
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamAcceptInvitationFailed.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
            }
        }
    }
    
    func declineCoHostInvitation() {
        Task.runOnMainActor {
            do {
                self.showInvitedAsCoHostSheet = false
                try await self.coHostInvitation?.reject()
                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationDeclinedToast.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamDeclineInvitationFailed.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
            }
        }
    }
    
    func leaveRoom() {
        Task.runOnMainActor {
            do {
                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamLeftStageToast.localizedString, aboveBottomBarHeight: AmityLiveStreamChatViewModel.viewerComposeBarHeight)
                try await self.roomManager.leaveRoom(roomId: self.room?.roomId ?? "")
            } catch {
                Log.add(event: .error, "Error when levaing the room: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Watch Minute Tracking State Transitions
    
    /// Handle watch minute tracking when user transitions between viewer and co-host roles
    private func handleStateTransition(from oldState: PageState, to newState: PageState) {
        guard let room = room else { return }
        
        // User became co-host (accepted invitation)
        if oldState == .viewer && (newState == .inBackstage || newState == .streamingAsCoHost) {
            // Stop tracking when user becomes co-host
            watchMinuteTracker.stopTracking()
            Log.add(event: .info, "Watch tracking stopped: User became co-host")

            // Backstage/co-host is a broadcaster surface — excluded from PiP.
            // Close any floating window carried over from the viewer session.
            PiPState.shared.stopActivePiPForExcludedSurface()
        }
        
        // User returned to viewer (left co-host role)
        if (oldState == .inBackstage || oldState == .streamingAsCoHost) && newState == .viewer {
            // Start new tracking session when user returns to viewer
            watchMinuteTracker.startTracking(for: room)
            Log.add(event: .info, "Watch tracking started: User returned to viewer")
        }
    }
    
    @MainActor
    func updateProductTagsAPI(childPost: AmityPost) async {
        do {
            let productTagsArray: [AmityMediaProductTag] = taggedProducts.map { product in
                let productTag = AmityMediaProductTag(productId: product.productId)
                return productTag
            }
            
            let updatedPost = try await postManager.updateProductTags(postId: childPost.postId, productTags: productTagsArray)
            self.updatedChildPost = updatedPost
            
            // Sync local state with BE response
            let productTags = updatedPost.getMediaProductTags()
            taggedProducts = productTags.compactMap { $0.product }
            pinnedProductId = updatedPost.pinnedProductId
        } catch {
            Log.add(event: .error, "[Playback] Failed to update product tags: \(error.localizedDescription)")
        }
    }
    
    /// Checks if product catalogue/tag is enabled from network settings
    func checkProductCatalogueSettings() async {
        do {
            let productSettings = try await AmityUIKitManagerInternal.shared.client.getProductCatalogueSetting()
            await MainActor.run {
                self.isProductTagEnabled = productSettings.enabled
            }
        } catch {
            // Default to false if error or not available
            await MainActor.run {
                self.isProductTagEnabled = false
                Log.add(event: .error, "Product Catalogue setting not available: \(error.localizedDescription)")
            }
        }
    }
}
