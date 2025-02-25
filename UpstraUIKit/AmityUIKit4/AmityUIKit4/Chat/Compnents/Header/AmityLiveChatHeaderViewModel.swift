//
//  AmityLiveChatHeaderViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 12/3/2567 BE.
//

import Foundation
import SwiftUI
import AmitySDK
import Combine

public class AmityLiveChatHeaderViewModel: ObservableObject {
    
    private let channelId: String
    private lazy var channelManager = ChannelManager()
    private var cancellable: AnyCancellable?
    
    @Published var displayName: String = ""
    @Published var memberCount: Int = 0
    @Published var avatarURL: URL?
    
    public init(channelId: String) {
        self.channelId = channelId
    }
    
    func loadChannelInfo() {
        // Update with local information immediately
        if let localChannel = channelManager.getChannel(channelId: channelId).snapshot {
            
            updateChannelInfo(channel: localChannel)
        }
        
        // Update with fresh information when available
        let liveChannel = channelManager.getChannel(channelId: channelId)
        cancellable = nil
        cancellable = liveChannel.$snapshot.sink { [weak self] newChannel in
            guard let self else { return }
            
            if liveChannel.dataStatus == .fresh, let newChannel {
                self.updateChannelInfo(channel: newChannel)
            }
        }
    }
    
    func updateChannelInfo(channel: AmityChannel) {
        self.displayName = channel.displayName ?? "-"
        
        let channelMemberCount = channel.memberCount
        self.memberCount = channelMemberCount
        
        if let fileURL = channel.getAvatarInfo()?.fileURL, let url = URL(string: fileURL) {
            self.avatarURL = url
        }
    }
}
