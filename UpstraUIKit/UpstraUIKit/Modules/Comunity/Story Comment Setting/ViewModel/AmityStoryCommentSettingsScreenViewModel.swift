//
//  AmityStoryCommentSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 11/3/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityStoryCommentSettingsScreenViewModel: AmityStoryCommentSettingsScreenViewModelType {
    weak var delegate: AmityStoryCommentSettingsScreenViewModelDelegate?
    
    // MARK: - Repository
    private let communityRepository: AmityCommunityRepository
    
    // MARK: - Tasks
    private let communityViewModel: AmityStoryCommentSettingsCommunityViewModel
    
    let communityId: String
    
    init(communityId: String) {
        self.communityId = communityId
        communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
        communityViewModel = AmityStoryCommentSettingsCommunityViewModel(communityId: communityId, communityRepository: communityRepository)
    }
}

// MARK: - DataSource
extension AmityStoryCommentSettingsScreenViewModel {
    
}

// MARK: - Action
extension AmityStoryCommentSettingsScreenViewModel {
    
    func getCommunity() {
        communityViewModel.getCommunity { [weak self] (result) in
            switch result {
            case .success(let community):
                self?.prepareMenu(community: community)
            case .failure(let error):
                break
            }
        }
    }
    
    private func prepareMenu(community: AmityCommunityModel)  {
        var settingsItems = [AmitySettingsItem]()
        let allowStoryComment = AmitySettingsItem.ToggleContent(identifier: AmityStoryCommentSettingsItem.allowComment.identifier,
                                                                     iconContent: AmitySettingContentIcon(icon: AmityStoryCommentSettingsItem.allowComment.icon),
                                                                     title: AmityStoryCommentSettingsItem.allowComment.title,
                                                                     description: AmityStoryCommentSettingsItem.allowComment.description,
                                                                     isToggled: community.isStoryCommentsAllowed)
        settingsItems.append(.toggleContent(content: allowStoryComment))
        settingsItems.append(.separator)
        delegate?.screenViewModel(self, didFinishWithAction: .showMenu(settingItem: settingsItems))
    }
    
    func turnOnApproveMemberPost(content: AmitySettingsItem.ToggleContent) {
        performAction(content: .turnOnAllowStoryComment(content: content), allowComment: true)
    }
    
    func turnOffApproveMemberPost(content: AmitySettingsItem.ToggleContent) {
        performAction(content: .turnOffAllowStoryComment(content: content), allowComment: false)
    }
    
    private func performAction(content: AmityStoryCommentSettingsAction, allowComment: Bool) {
        if Reachability.shared.isConnectedToNetwork {
            let updateOptions = AmityCommunityUpdateOptions()
            
            updateOptions.setStorySettings(allowComment: allowComment)
            communityRepository.updateCommunity(withId: communityId, options: updateOptions) { [weak self] (community, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    strongSelf.delegate?.screenViewModel(strongSelf, didFailWithAction: content)
                } else {
                    
                }
            }
        } else {
            delegate?.screenViewModel(self, didFailWithAction: content)
        }
    }
}
