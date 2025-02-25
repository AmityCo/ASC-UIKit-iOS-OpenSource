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
}
