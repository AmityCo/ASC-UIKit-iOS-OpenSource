//
//  AmityPostReviewSettingsScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 11/3/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

enum AmityStoryCommentSettingsAction {
    case showMenu(settingItem: [AmitySettingsItem])
    case turnOnAllowStoryComment(content: AmitySettingsItem.ToggleContent)
    case turnOffAllowStoryComment(content: AmitySettingsItem.ToggleContent)
}


protocol AmityStoryCommentSettingsScreenViewModelDelegate: AnyObject {
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFinishWithAction action: AmityStoryCommentSettingsAction)
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFailWithAction action: AmityStoryCommentSettingsAction)
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFailWithError error: AmityError)
}

protocol AmityStoryCommentSettingsScreenViewModelDataSource {
    var communityId: String { get }
}

protocol AmityStoryCommentSettingsScreenViewModelAction {
    func getCommunity()
    func turnOffApproveMemberPost(content: AmitySettingsItem.ToggleContent)
    func turnOnApproveMemberPost(content: AmitySettingsItem.ToggleContent)
}

protocol AmityStoryCommentSettingsScreenViewModelType: AmityStoryCommentSettingsScreenViewModelAction, AmityStoryCommentSettingsScreenViewModelDataSource {
    var delegate: AmityStoryCommentSettingsScreenViewModelDelegate? { get set }
    var action: AmityStoryCommentSettingsScreenViewModelAction { get }
    var dataSource: AmityStoryCommentSettingsScreenViewModelDataSource { get }
}

extension AmityStoryCommentSettingsScreenViewModelType {
    var action: AmityStoryCommentSettingsScreenViewModelAction { return self }
    var dataSource: AmityStoryCommentSettingsScreenViewModelDataSource { return self }
}
