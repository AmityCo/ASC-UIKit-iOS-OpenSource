//
//  AmityUserSettingsScreenViewModel.swift
//  AmityUIKit
//
//  Created by Hamlet on 28.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import AmitySDK

final class AmityUserSettingsScreenViewModel: AmityUserSettingsScreenViewModelType {
    
    weak var delegate: AmityUserSettingsScreenViewModelDelegate?
    
    // MARK: - Controller
    private let userNotificationController: AmityUserNotificationSettingsControllerProtocol
    
    // MARK: - SubViewModel
    private var menuViewModel: AmityUserSettingsCreateMenuViewModelProtocol?
    
    // MARK: - Properties
    private(set) var user: AmityUser?
    let userId: String
    private let userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    private var userToken: AmityNotificationToken?
    private let followManager: AmityUserRelationship
    private var isFlaggedByMe: Bool?
    private var followStatus: AmityFollowStatus?
    private var dispatchGroup = DispatchGroup()
    private var followToken: AmityNotificationToken?
    
    let relationshipManager = UserRelationshipManager()
    let moderationManager = UserModerationManager()
    
    init(userId: String, userNotificationController: AmityUserNotificationSettingsControllerProtocol) {
        self.userId = userId
        self.userNotificationController = userNotificationController
        followManager = userRepository.userRelationship
    }
}

// MARK: - Action
extension AmityUserSettingsScreenViewModel {
    
    func unfollowUser() {
        relationshipManager.unfollowUser(userId: userId) { [weak self] status, followResponse, error in
            guard let self else { return }
            if !status {
                self.delegate?.screenViewModel(self, didCompleteAction: .unfollow, error: AmityError(error: error))
                return
            }
            
            self.followStatus = AmityFollowStatus.none
            self.createMenuViewModel()
        }
    }
    
    @MainActor
    func blockUser() {
        Task {
            do {
                try await followManager.blockUser(userId: userId)
                
                self.followStatus = .blocked
                self.createMenuViewModel()
                
                self.delegate?.screenViewModel(self, didCompleteAction: .blockUser, error: nil)
            } catch let error {
                self.delegate?.screenViewModel(self, didCompleteAction: .blockUser, error: AmityError(error: error))
            }
        }
    }
    
    @MainActor
    func unblockUser() {
        Task {
            do {
                try await followManager.unblockUser(userId: userId)
                
                self.followStatus = AmityFollowStatus.none
                self.createMenuViewModel()
                
                self.delegate?.screenViewModel(self, didCompleteAction: .unblockUser, error: nil)
            } catch let error {
                self.delegate?.screenViewModel(self, didCompleteAction: .unblockUser, error: AmityError(error: error))
            }
        }
    }
    
    func reportUser() {
        guard let user = user else { return }
        moderationManager.flagUser(userId: user.userId) { [weak self] status, error in
            guard let strongSelf = self else { return }
            
            if let error {
                strongSelf.delegate?.screenViewModel(strongSelf, didCompleteAction: .report, error: AmityError(error: error))
            } else {
                strongSelf.isFlaggedByMe = !(strongSelf.isFlaggedByMe ?? false)
                strongSelf.createMenuViewModel()
                strongSelf.delegate?.screenViewModel(strongSelf, didCompleteAction: .report, error: nil)
            }
        }
    }

    func unreportUser() {
        guard let user = user else { return }
        moderationManager.unflagUser(userId: user.userId) { [weak self] status, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.delegate?.screenViewModel(strongSelf, didCompleteAction: .unreport, error: AmityError(error: error))
            } else {
                self?.isFlaggedByMe = !(self?.isFlaggedByMe ?? false)
                self?.createMenuViewModel()
                
                strongSelf.delegate?.screenViewModel(strongSelf, didCompleteAction: .unreport, error: nil)
            }
        }
    }
    
    func fetchUserSettings() {
        userToken = userRepository.getUser(userId).observe { [weak self] user, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.userToken?.invalidate()
                strongSelf.delegate?.screenViewModel(strongSelf, failure: AmityError(error: error) ?? .unknown)
                return
            }
            
            if let user = user.snapshot {
                strongSelf.user = user
                strongSelf.retrieveSettingsMenu()
            }
            
            strongSelf.userToken?.invalidate()
        }
    }
    
    @MainActor
    func performAction(settingsItem: AmityUserSettingsItem) {
        switch settingsItem {
        case .unfollow:
            unfollowUser()
        case .report:
            reportUser()
        case .blockUser:
            blockUser()
        case .unblockUser:
            unblockUser()
        case .unreport:
            unreportUser()
        default:
            break
        }
    }
}

private extension AmityUserSettingsScreenViewModel {
    func getReportUserStatus(completion: (() -> Void)?) {
        guard let user = user else { return }
        
        moderationManager.isFlaggedByMe(userId: user.userId) { [weak self] status, error in
            self?.isFlaggedByMe = status
            completion?()
        }
    }
    
    func getFollowInfo(completion: (() -> Void)?) {
        followToken = followManager.getFollowInfo(withUserId: userId).observeOnce {
            [weak self] liveObject, error in
            guard let result = liveObject.snapshot else { return }
            
            self?.followStatus = result.status
            completion?()
            self?.followToken?.invalidate()
        }
    }
    
    func createMenuViewModel() {
        menuViewModel = AmityUserSettingsCreateMenuViewModel()
        
        let settingsConfiguration = UserSettingsConfiguration(
            isOwner: userId == AmityUIKitManagerInternal.shared.client.currentUserId,
            isReported: isFlaggedByMe ?? false,
            isFollowing: followStatus == .accepted,
            isBlocked: followStatus == .blocked
        )
        
        guard let settingsMenu = menuViewModel?.createSettingItems(config: settingsConfiguration) else { return }
        self.delegate?.screenViewModel(self, didGetSettingMenu: settingsMenu)
    }
    
    func retrieveSettingsMenu() {
        if userId == AmityUIKitManagerInternal.shared.client.currentUserId {
            createMenuViewModel()
            return
        }
        
        dispatchGroup.enter()
        getReportUserStatus { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        getFollowInfo { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.createMenuViewModel()
        }
    }
}
