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
    
    @Published var currentState: PageState = .viewer
    @Published var showInvitedAsCoHostSheet: Bool = false
    
    private var roomManager = RoomManager()
    private var postManager = PostManager()
    private var invitationManager = InvitationManager()
    @Published var post: AmityPostModel?
    @Published var room: AmityRoom?
    private var cancellable: AnyCancellable?
    
    // ViewModels
    @Published var broadcasterViewModel: LiveStreamBroadcasterViewModel?
    @Published var livestreamViewerViewModel: LiveStreamViewerViewModel?
    @Published var conferenceViewModel: LiveStreamConferenceViewModel?
    
    // live object notification
    private var roomNotification: AmityNotificationToken?
    private var postNotification: AmityNotificationToken?
    
    // Loading state
    @Published var isLoading: Bool = false
    
    @Published var coHostInvitation: AmityInvitation?
    @Published var isJoinSheetDismissedOnAction: Bool = false
    
    
    public init(post: AmityPostModel) {
        self.post = post
        self.room = post.room
        
        setupViewModels(post)
        
        // Observe invitation for co-host
        if let room {
            observeCoHostEvents(room: room)
        }
    }
    
    public init(roomId: String) {
        self.isLoading = true
        roomNotification = roomManager.getRoom(roomId: roomId)
            .observeOnce({ [weak self] object, error in
                guard let self, let room = object.snapshot else { return }
                
                postNotification = postManager.getPost(withId: room.referenceId ?? "")
                    .observeOnce({ [weak self] object, error in
                        guard let self, let post = object.snapshot else { return }
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
                                
                                if invitation?.status == .pending {
                                    self.showInvitedAsCoHostSheet = true
                                } else {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationNoLongerValid.localizedString, bottomPadding: 60)
                                }
                            }
                        }
                        
                        postNotification?.invalidate()
                        roomNotification?.invalidate()
                    })
            })
    }
    
    private func setupViewModels(_ postModel: AmityPostModel) {
        let broadcasterViewModel = LiveStreamBroadcasterViewModel(role: .coHost)
        
        self.broadcasterViewModel = broadcasterViewModel
        self.conferenceViewModel = LiveStreamConferenceViewModel(targetId: postModel.targetId, targetType: postModel.postTargetType, participantRole: .coHost, broadcasterViewModel: broadcasterViewModel)
        self.livestreamViewerViewModel = LiveStreamViewerViewModel(post: postModel)
    }
    
    private func observeCoHostEvents(room: AmityRoom) {
        cancellable = nil
        cancellable = roomManager.getCoHostEvent(roomId: room.roomId)
            .sink(receiveValue: { [weak self] event in
                
                // Handle co-host removed event when current user is in backstage
                // we can assume that the current user is co-host if they are in backstage
                if event.type == .coHostRemoved && self?.currentState == .inBackstage {
                    self?.currentState = .viewer
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamLeftStageToast.localizedString, bottomPadding: 60)
                }
                
                // Ensure the invitation is for the current user since BE is sending events to all users in the room
                guard event.invitation?.invitedUserId == AmityUIKitManagerInternal.shared.client.currentUserId else { return }
                
                Log.add(event: .info, "Received co-host invitation with status: \(event.invitation?.status.rawValue ?? "nil")")
                self?.coHostInvitation = event.invitation
                
                // Handle UI state accordingly
                if event.type == .invitationInvited {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
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
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamAcceptInvitationFailed.localizedString, bottomPadding: 60)
            }
        }
    }
    
    func declineCoHostInvitation() {
        Task.runOnMainActor {
            do {
                self.showInvitedAsCoHostSheet = false
                try await self.coHostInvitation?.reject()
                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationDeclinedToast.localizedString, bottomPadding: 60)
            } catch {
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamDeclineInvitationFailed.localizedString, bottomPadding: 60)
            }
        }
    }
    
    func leaveRoom() {
        Task.runOnMainActor {
            do {
                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamLeftStageToast.localizedString, bottomPadding: 60)
                try await self.roomManager.leaveRoom(roomId: self.room?.roomId ?? "")
            } catch {
                Log.add(event: .error, "Error when levaing the room: \(error.localizedDescription)")
            }
        }
    }
}
