//
//  AmityCommunitySettingPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/20/24.
//

import Foundation
import AmitySDK

@MainActor
class AmityCommunitySettingPageViewModel: ObservableObject {
    @Published var shouldShowEditProfile: Bool = false
    @Published var shouldShowPendingInvitations: Bool = false
    @Published var shouldShowNotifications: Bool = false
    @Published var isNotificationEnabled: Bool = false
    @Published var shouldShowPostPermissions: Bool = false
    @Published var shouldShowStoryComments: Bool = false
    @Published var shouldShowCloseCommunity: Bool = false
    
    private let communityManager = CommunityManager()
    private let notificationManger = NotificationManager()
    var community: AmityCommunity
    private let dispatchGroup = DispatchGroup()
    private var hasEditCommunityPermission: Bool = false
    private var hasDeleteCommunityPermission: Bool = false
    private var isSocialUserNotificationEnabled: Bool = false
    private var isSocialNetworkEnabled: Bool = false
    
    init(community: AmityCommunity) {
        self.community = community
        checkPermissionAndSetupData()
    }
 
    func deleteCommunity() async throws {
        try await communityManager.deleteCommunity(withId: community.communityId)
    }
    
    func leaveCommunity() async throws {
        try await communityManager.leaveCommunity(withId: community.communityId)
    }
    
    private func checkPermissionAndSetupData() {
        Task {
            await hasEditCommunityPermisison()
            await hasDeleteCommunityPermission()
            await isSocialUserNotificationEnabled()
            await isSocialNetworkEnabled()
            
            self.setupData()
        }
    }
    
    private func setupData() {
        let isModerator = community.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
        self.shouldShowEditProfile = hasEditCommunityPermission || isModerator
        self.shouldShowPendingInvitations = isModerator
        self.shouldShowNotifications = isSocialUserNotificationEnabled && isNotificationEnabled && isSocialNetworkEnabled
        self.shouldShowPostPermissions = hasEditCommunityPermission || isModerator
        self.shouldShowStoryComments = hasEditCommunityPermission || isModerator
        self.shouldShowCloseCommunity = hasDeleteCommunityPermission || isModerator
    }
    
    private func hasEditCommunityPermisison() async {
        self.hasEditCommunityPermission = await AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: community.communityId)
    }
    
    private func hasDeleteCommunityPermission() async {
        self.hasDeleteCommunityPermission = await AmityUIKitManagerInternal.shared.client.hasPermission(.deleteCommunity, forCommunity: community.communityId)
    }
    
    private func isSocialUserNotificationEnabled() async {
        let settings = try? await notificationManger.getUserNotificationSetting()
        if let socialModule = settings?.modules.first(where: { $0.moduleType == .social }) {
            self.isSocialUserNotificationEnabled = socialModule.isEnabled
            return
        }
        
        self.isSocialUserNotificationEnabled = false
    }
    
    func isSocialNetworkEnabled() async {
        let settings = try? await notificationManger.getCommunityNotificationSetting(withId: community.communityId)
        self.isSocialNetworkEnabled = settings?.isSocialNetworkEnabled ?? false
        self.isNotificationEnabled = settings?.isEnabled ?? false
    }
    
    func refreshCommunitySnapshot() {
        let communityId = community.communityId
        
        // Get latest snapshot from local repository
        if let updatedCommunity = communityManager.getCommunity(withId: communityId).snapshot {
            self.community = updatedCommunity
        }
    }
}
