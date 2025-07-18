//
//  ChannelManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 12/3/2567 BE.
//

import Foundation
import AmitySDK

class ChannelManager {
    
    let repository: AmityChannelRepository
    
    init() {
        self.repository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
    func getChannel(channelId: String) -> AmityObject<AmityChannel> {
        return repository.getChannel(channelId)
    }
    
    func joinChannel(channelId: String) async throws -> AmityChannel? {
        return try await repository.joinChannel(channelId: channelId)
    }
    
    func muteChannel(channelId: String) async throws {
        try await repository.muteChannel(channelId: channelId, mutePeriod: 600)
    }
    
    func unmuteChannel(channelId: String) async throws {
        try await repository.unmuteChannel(channelId: channelId)
    }
}
