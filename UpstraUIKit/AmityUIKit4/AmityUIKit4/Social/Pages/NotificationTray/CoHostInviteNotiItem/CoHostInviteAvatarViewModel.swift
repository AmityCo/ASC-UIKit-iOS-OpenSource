//
//  CoHostInviteAvatarViewModel.swift
//  AmityUIKit4
//
//  Created by Prisa on 21/7/2569 BE.
//

import Foundation
import AmitySDK

class CoHostInviteAvatarViewModel: ObservableObject {

    @Published var isLive: Bool = false

    private let roomManager = RoomManager()
    private var token: AmityNotificationToken?

    func observeIfNeeded(roomId: String) {
        guard token == nil, !roomId.isEmpty else { return }
        token = roomManager.getRoom(roomId: roomId).observe { [weak self] liveObject, _ in
            guard let self, let room = liveObject.snapshot else { return }
            self.isLive = room.status == .live || room.status == .waitingReconnect
        }
    }
}

