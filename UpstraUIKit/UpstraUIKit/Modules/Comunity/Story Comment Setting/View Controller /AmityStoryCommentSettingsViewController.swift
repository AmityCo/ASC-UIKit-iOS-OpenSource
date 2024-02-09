//
//  AmityStoryCommentSettingsViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 11/3/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

final class AmityStoryCommentSettingsViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var settingTableView: AmitySettingsItemTableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityStoryCommentSettingsScreenViewModelType!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
        setupSettingsItems()
    }
    
    static func make(communityId: String) -> AmityStoryCommentSettingsViewController {
        let viewModel = AmityStoryCommentSettingsScreenViewModel(communityId: communityId)
        let vc = AmityStoryCommentSettingsViewController(nibName: AmityStoryCommentSettingsViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - Setup view
    private func setupView() {
        title = AmityLocalizedStringSet.StoryCommentSettings.title.localizedString
    }
    
    private func setupViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.getCommunity()
    }
    
    private func setupSettingsItems() {
        settingTableView.actionHandler = { [weak self] settingsItem in
            self?.handleActionItem(settingsItem: settingsItem)
        }
    }
    
    private func handleActionItem(settingsItem: AmitySettingsItem) {
        switch settingsItem {
        case .toggleContent(let content):
            guard let item = AmityStoryCommentSettingsItem(rawValue: content.identifier) else { return }
            switch item {
            case .allowComment:
                if !content.isToggled {
                    screenViewModel.action.turnOffApproveMemberPost(content: content)
                } else {
                    screenViewModel.action.turnOnApproveMemberPost(content: content)
                }
            }
        default:
            break
        }
    }
}

extension AmityStoryCommentSettingsViewController: AmityStoryCommentSettingsScreenViewModelDelegate {
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFinishWithAction action: AmityStoryCommentSettingsAction) {
        switch action {
        case .showMenu(let settingItem):
            settingTableView.settingsItems = settingItem
        case .turnOnAllowStoryComment(let content):
            content.isToggled = true
        case .turnOffAllowStoryComment(let content):
            content.isToggled = false
        }
    }
    
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFailWithAction action: AmityStoryCommentSettingsAction) {
        switch action {
        case .turnOnAllowStoryComment(let content):
            AmityAlertController.present(title: AmityLocalizedStringSet.StoryCommentSettings.alertFailTitleTurnOn.localizedString,
                                         message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString,
                                         actions: [.ok(handler: {
                                            content.isToggled = false
                                         })],
                                         from: self)
        case .turnOffAllowStoryComment(let content):
            AmityAlertController.present(title: AmityLocalizedStringSet.StoryCommentSettings.alertFailTitleTurnOff.localizedString,
                                         message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString,
                                         actions: [.ok(handler: {
                                            content.isToggled = true
                                         })],
                                         from: self)
        default:
            break
        }
    }
    
    func screenViewModel(_ viewModel: AmityStoryCommentSettingsScreenViewModelType, didFailWithError error: AmityError) {
        
    }
}
