//
//  AmityCommunitySettingPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/20/24.
//

import Foundation
import AmitySDK

class AmityCommunitySettingPageViewModel: ObservableObject {
    @Published var shouldShowEditProfile: Bool = false
    @Published var shouldShowNotifications: Bool = false
    @Published var isNotificationEnabled: Bool = false
    @Published var shouldShowPostPermissions: Bool = false
    @Published var shouldShowStoryComments: Bool = false
    @Published var shouldShowCloseCommunity: Bool = false
    
    private let communityManager = CommunityManager()
    private let notificationManger = NotificationManager()
    private let community: AmityCommunity
    private let dispatchGroup = DispatchGroup()
    private var hasEditCommunityPermission: Bool = false
    private var hasDeleteCommunityPermission: Bool = false
    private var isSocialUserNotificationEnabled: Bool = false
    private var isSocialNetworkEnabled: Bool = false
    
    init(community: AmityCommunity) {
        self.community = community
        checkPermissionAndSetupData()
    }
 
    func deleteCommunity(completion: ((AmityError?) -> Void)?) {
        communityManager.deleteCommunity(withId: community.communityId, completion: completion)
    }
    
    func leaveCommunity() async throws {
        try await communityManager.leaveCommunity(withId: community.communityId)
    }
    
    private func checkPermissionAndSetupData() {
        dispatchGroup.enter()
        hasEditCommunityPermisison() { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        hasDeleteCommunityPermission() { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        isSocialUserNotificationEnabled { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        isSocialNetworkEnabled { [weak self] in
            self?.dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.setupData()
        }
    }
    
    private func setupData() {
        let isModerator = community.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
        self.shouldShowEditProfile = hasEditCommunityPermission || isModerator
        self.shouldShowNotifications = isSocialUserNotificationEnabled && isSocialNetworkEnabled
        self.shouldShowPostPermissions = hasEditCommunityPermission || isModerator
        self.shouldShowStoryComments = hasEditCommunityPermission || isModerator
        self.shouldShowCloseCommunity = hasDeleteCommunityPermission || isModerator
    }
    
    private func hasEditCommunityPermisison(_ completion: (() -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: community.communityId) { [weak self] status in
            self?.hasEditCommunityPermission = status
            completion?()
        }
    }
    
    private func hasDeleteCommunityPermission(_ completion: (() -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunity, forCommunity: community.communityId) { [weak self] (status) in
            self?.hasDeleteCommunityPermission = status
            completion?()
        }
    }
    
    private func isSocialUserNotificationEnabled(_ completion: (() -> Void)?) {
        notificationManger.getUserNotificationSetting { [weak self] settings, error in
            if let socialModule = settings?.modules.first(where: { $0.moduleType == .social }) {
                self?.isSocialUserNotificationEnabled = socialModule.isEnabled
                completion?()
                return
            }
            
            self?.isSocialUserNotificationEnabled = false
            completion?()
        }
    }
    
    func isSocialNetworkEnabled(_ completion: (() -> Void)?) {
        notificationManger.getCommunityNotificationSetting(withId: community.communityId) { [weak self] settings, error in
            if let settings {
                self?.isSocialNetworkEnabled = settings.isSocialNetworkEnabled
                self?.isNotificationEnabled = settings.isEnabled
                completion?()
                return
            }
            
            self?.isSocialNetworkEnabled = false
            self?.isNotificationEnabled = false
            completion?()
        }
    }
}
