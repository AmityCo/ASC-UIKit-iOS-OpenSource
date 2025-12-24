//
//  LiveStreamCoHostInviteViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/10/25.
//

import Foundation
import AmitySDK

class LiveStreamCoHostInviteViewModel: ObservableObject {
    private var room: AmityRoom?
    private let invitationManager = InvitationManager()
    let conferenceViewModel: LiveStreamConferenceViewModel
    private var presenceRepository: AmityRoomPresenceRepository
    private let roomManager = RoomManager()
    
    @Published var viewers: [AmityUser] = []
    
    init(conferenceViewModel: LiveStreamConferenceViewModel) {
        self.room = conferenceViewModel.createdRoom
        self.conferenceViewModel = conferenceViewModel
        self.presenceRepository = AmityRoomPresenceRepository(client: AmityUIKitManagerInternal.shared.client, roomId: room?.roomId ?? "")
    }
    
    func loadViewers() {
        Task.runOnMainActor {
            let viewers = try await self.presenceRepository.getRoomOnlineUsers()
            self.viewers = viewers.filter { $0.userId != self.conferenceViewModel.invitedCoHost.user?.userId }
        }
    }
    
    @MainActor
    func inviteAsCoHost(user: AmityUserModel) async throws {
        guard let room else { return }
        try await room.createInvitation(user.userId)
        conferenceViewModel.invitedCoHost = (true, user, false)
    }
    
    @MainActor
    func declineAsCoHost(user: AmityUserModel) async throws {
        guard let invitation = conferenceViewModel.coHostInvitation, let room else { return }
        try await room.cancelInvitation(invitation.invitationId)
        conferenceViewModel.invitedCoHost = (false, nil, false)
    }
    
    @MainActor
    func removeCoHostFromStream(userId: String) async throws {
        guard let room else { return }
        try await roomManager.removeCohost(roomId: room.roomId, userId: userId)
    }
}
