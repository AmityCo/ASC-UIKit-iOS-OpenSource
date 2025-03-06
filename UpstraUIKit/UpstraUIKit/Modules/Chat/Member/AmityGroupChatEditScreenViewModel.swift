//
//  GroupChatScreenViewModel.swift
//  AmityUIKit
//
//  Created by min khant on 13/05/2021.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityGroupChatEditorScreenViewModelAction {
    func update(displayName: String)
    func update(avatar: UIImage, completion: @escaping (Bool) -> ())
}

protocol AmityGroupChatEditorViewModelDataSource {
    var channel: AmityChannel? { get }
    func getChannelEditUserPermission(_ completion: ((Bool) -> Void)?)
}

protocol AmityGroupChatEditorScreenViewModelDelegate: AnyObject {
    func screenViewModelDidUpdate(_ viewModel: AmityGroupChatEditorScreenViewModelType)
    func screenViewModelDidUpdateFailed(_ viewModel: AmityGroupChatEditorScreenViewModelType, withError error: String)
    func screenViewModelDidUpdateSuccess(_ viewModel: AmityGroupChatEditorScreenViewModelType)
    
}

protocol AmityGroupChatEditorScreenViewModelType: AmityGroupChatEditorScreenViewModelAction, AmityGroupChatEditorViewModelDataSource {
    var action: AmityGroupChatEditorScreenViewModelAction { get }
    var dataSource: AmityGroupChatEditorViewModelDataSource { get }
    var delegate: AmityGroupChatEditorScreenViewModelDelegate? { get set }
}

extension AmityGroupChatEditorScreenViewModelType {
    var action: AmityGroupChatEditorScreenViewModelAction { return self }
    var dataSource: AmityGroupChatEditorViewModelDataSource { return self }
}

class AmityGroupChatEditScreenViewModel: AmityGroupChatEditorScreenViewModelType {
    
    private var channelNotificationToken: AmityNotificationToken?
    private let channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    private var channelUpdateBuilder: AmityChannelUpdateBuilder!
    private let fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)

    var channel: AmityChannel?
    weak var delegate: AmityGroupChatEditorScreenViewModelDelegate?
    var user: AmityUserModel?
    var channelId = String()
    
    init(channelId: String) {
        self.channelId = channelId
        channelUpdateBuilder = AmityChannelUpdateBuilder(channelId: channelId)
        channelNotificationToken = channelRepository.getChannel(channelId)
            .observe({ [weak self] channel, error in
                guard let weakself = self,
                      let channel = channel.snapshot else{ return }
                weakself.channel = channel
                weakself.delegate?.screenViewModelDidUpdate(weakself)
            })
    }
    
    func update(displayName: String) {
        // Update
        channelUpdateBuilder.setDisplayName(displayName)
                
        Task { @MainActor in
            do {
                let result = try await channelRepository.editChannel(with: channelUpdateBuilder)
                self.delegate?.screenViewModelDidUpdateSuccess(self)
            } catch let error {
                self.delegate?.screenViewModelDidUpdateFailed(self, withError: error.localizedDescription)
            }
        }
    }
    
    func update(avatar: UIImage, completion: @escaping (Bool) -> ()) {
        // Update user avatar
        Task { @MainActor in
            do {
                let uploadedData = try await fileRepository.uploadImage(avatar, progress: nil)
                let updateResult = try await channelRepository.editChannel(with: channelUpdateBuilder)
                completion(true)
            } catch let error {
                completion(false)
            }
        }
    }
    
    func getChannelEditUserPermission(_ completion: ((Bool) -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editChannel, forChannel: channelId, completion: { hasPermission in
            completion?(hasPermission)
        })
    }
}
