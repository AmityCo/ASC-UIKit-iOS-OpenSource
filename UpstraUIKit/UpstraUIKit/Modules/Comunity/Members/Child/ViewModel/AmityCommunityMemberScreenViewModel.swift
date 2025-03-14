//
//  AmityCommunityMemberScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 15/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityCommunityMemberScreenViewModel: AmityCommunityMemberScreenViewModelType {
    
    weak var delegate: AmityCommunityMemberScreenViewModelDelegate?
    
    private let flagger: AmityUserRepository
    
    // MARK: - Controller
    private let fetchMemberController: AmityCommunityFetchMemberControllerProtocol
    private let removeMemberController: AmityCommunityRemoveMemberControllerProtocol
    private let addMemberController: AmityCommunityAddMemberControllerProtocol
    private let roleController: AmityCommunityRoleControllerProtocol
    
    // MARK: - Properties
    private var members: [AmityCommunityMembershipModel] = []
    let community: AmityCommunityModel
    
    init(community: AmityCommunityModel,
         fetchMemberController: AmityCommunityFetchMemberControllerProtocol,
         removeMemberController: AmityCommunityRemoveMemberControllerProtocol,
         addMemberController: AmityCommunityAddMemberControllerProtocol,
         roleController: AmityCommunityRoleControllerProtocol) {
        self.community = community
        self.fetchMemberController = fetchMemberController
        self.removeMemberController = removeMemberController
        self.addMemberController = addMemberController
        self.roleController = roleController
        self.flagger = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    }
    
}

// MARK: - DataSource
extension AmityCommunityMemberScreenViewModel {    
    func numberOfMembers() -> Int {
        return members.count
    }
    
    func member(at indexPath: IndexPath) -> AmityCommunityMembershipModel {
        return members[indexPath.row]
    }
    
    func getReportUserStatus(at indexPath: IndexPath, completion: ((Bool) -> Void)?) {
        guard let user = member(at: indexPath).user else { return }
        
        Task { @MainActor in
            do {
                let result = try await flagger.isUserFlaggedByMe(withId: user.userId)
                completion?(result)
            } catch let error {
                completion?(false)
            }
        }
    }
    
    func prepareData() -> [AmitySelectMemberModel] {
        return members
            .filter { !$0.isCurrentUser }
            .map { AmitySelectMemberModel(object: $0) }
    }
}
// MARK: - Action
extension  AmityCommunityMemberScreenViewModel{
    func getCommunityEditUserPermission(_ completion: ((Bool) -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunityUser, forCommunity: community.communityId) { hasPermission in
            completion?(hasPermission)
        }
    }
}
/// Get Member of community
extension AmityCommunityMemberScreenViewModel {
    func getMember(viewType: AmityCommunityMemberViewType) {
        switch viewType {
        case .member:
            fetchMemberController.fetch(roles: []) { [weak self] (result) in
                switch result {
                case .success(let members):
                    self?.members = members
                    self?.delegate?.screenViewModelDidGetMember()
                case .failure:
                    break
                }
            }
        case .moderator:
            fetchMemberController.fetch(roles: [AmityCommunityRole.moderator.rawValue, AmityCommunityRole.communityModerator.rawValue]) { [weak self] (result) in
                switch result {
                case .success(let members):
                    self?.members = members
                    self?.delegate?.screenViewModelDidGetMember()
                case .failure:
                    break
                }
            }
        }
    }

    func loadMore() {
        fetchMemberController.loadMore { [weak self] success in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModel(strongSelf, loadingState: .loading)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, loadingState: .loaded)
            }
        }
    }
}

/// Add user
extension AmityCommunityMemberScreenViewModel {
    func addUser(users: [AmitySelectMemberModel]) {
        addMemberController.add(currentUsers: members, newUsers: users) { [weak self] addMemberError, removeMemberError in
            guard let strongSelf = self else { return }

            // Both failed
            if let addMemberError, let removeMemberError {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: addMemberError)
                return
            }
            
            if let addMemberError {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: addMemberError)
                return
            }
            
            if let removeMemberError {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: removeMemberError)

                return
            }
            
            // Else there was success
            self?.delegate?.screenViewModelDidAddMemberSuccess()
        }
    }
}

// MARK: Options

/// Report/Unreport user
extension AmityCommunityMemberScreenViewModel {
    func reportUser(at indexPath: IndexPath) {
        guard let user = member(at: indexPath).user else { return }
        Task { @MainActor in
            do {
                let isSuccess = try await flagger.flagUser(withId: user.userId)
                
                if isSuccess {
                    AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.reportSent.localizedString))
                }
            } catch let error {
                AmityHUD.show(.error(message: error.localizedDescription))
            }
        }
    }
    
    func unreportUser(at indexPath: IndexPath) {
        guard let user = member(at: indexPath).user else { return }
        Task { @MainActor in
            do {
                let isSuccess = try await flagger.unflagUser(withId: user.userId)
                
                if isSuccess {
                    AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.unreportSent.localizedString))
                }
            } catch let error {
                AmityHUD.show(.error(message: error.localizedDescription))
            }
        }
    }
    
    
}
/// Remove user
extension AmityCommunityMemberScreenViewModel {
    func removeUser(at indexPath: IndexPath) {
        // remove user role and remove user from community
        removeRole(at: indexPath)
        removeMemberController.remove(users: members, at: indexPath) { [weak self] (error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: error)
            } else {
                strongSelf.delegate?.screenViewModelDidRemoveRoleSuccess()
            }
        }
    }
}

/// Community Role action
extension AmityCommunityMemberScreenViewModel {
    func addRole(at indexPath: IndexPath) {
        let userId = member(at: indexPath).userId
        roleController.add(roles: [AmityCommunityRole.communityModerator.rawValue, AmityChannelRole.channelModerator.rawValue], userIds: [userId]) { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: error)
            } else {
                strongSelf.delegate?.screenViewModelDidAddRoleSuccess()
            }
        }
    }
    
    func removeRole(at indexPath: IndexPath) {
        let user = member(at: indexPath)
        var roles: [String] = []
        let currentRoles = user.roles
        if !currentRoles.isEmpty {
            if currentRoles.contains(AmityCommunityRole.moderator.rawValue) {
                roles.append(AmityCommunityRole.moderator.rawValue)
            }
            
            if currentRoles.contains(AmityCommunityRole.communityModerator.rawValue) {
                roles.append(AmityCommunityRole.communityModerator.rawValue)
                roles.append(AmityChannelRole.channelModerator.rawValue)
            }
        }
        
        roleController.remove(roles: roles, userIds: [user.userId]) { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: error)
            } else {
                strongSelf.delegate?.screenViewModelDidRemoveRoleSuccess()
            }
        }
    }
}
