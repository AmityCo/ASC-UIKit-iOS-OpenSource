//
//  AmityChannelMemberSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 1/11/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import Foundation

final class AmityChannelMemberSettingsScreenViewModel: AmityChannelMemberSettingsScreenViewModelType {
    
    // MARK: - Delegate
    weak var delegate: AmityChannelMemberSettingsScreenViewModelDelegate?
    
    // MARK: - Properties
    var channel: AmityChannelModel
    var isModerator: Bool = false
    var shouldShowAddMemberButton: Bool = false
    
    // MARK: - initial
    init(channel: AmityChannelModel) {
        self.channel = channel
    }
}

// MARK: - DataSource
extension AmityChannelMemberSettingsScreenViewModel {
    
}

// MARK: - Action
extension AmityChannelMemberSettingsScreenViewModel {
    func getUserRoles() {
        Task { @MainActor in
            let hasPermission = await AmityUIKitManagerInternal.shared.client.hasPermission(.editChannel, forChannel: channel.channelId)
            
            self.isModerator = hasPermission
            self.delegate?.screenViewModelShouldShowAddButtonBarItem(status: hasPermission)
        }
    }
}
