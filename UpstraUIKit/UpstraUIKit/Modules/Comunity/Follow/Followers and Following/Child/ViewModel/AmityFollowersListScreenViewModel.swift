//
//  AmityFollowersListScreenViewModel.swift
//  AmityUIKit
//
//  Created by Hamlet on 14.06.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityFollowersListScreenViewModel: AmityFollowersListScreenViewModelType {

    weak var delegate: AmityFollowersListScreenViewModelDelegate?

    // MARK: - Properties
    let userId: String
    let type: AmityFollowerViewType
    let isCurrentUser: Bool
    private let userRepository: AmityUserRepository
    private let followManager: AmityUserRelationship
    private var followToken: AmityNotificationToken?
    private var followersList: [AmityFollowRelationship] = []
    private var followersCollection: AmityCollection<AmityFollowRelationship>?
    
    private var moderationManager = UserModerationManager()
    private var relationshipManager = UserRelationshipManager()
    
    // MARK: - Initializer
    init(userId: String, type: AmityFollowerViewType) {
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        followManager = userRepository.userRelationship
        self.userId = userId
        self.isCurrentUser = userId == AmityUIKitManagerInternal.shared.client.currentUserId
        self.type = type
    }
}

// MARK: - DataSource
extension AmityFollowersListScreenViewModel {
    func numberOfItems() -> Int {
        return followersList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityUserModel? {
        guard let model = getUser(at: indexPath) else { return nil }
        return AmityUserModel(user: model)
    }
}

// MARK: - Action
extension AmityFollowersListScreenViewModel {
    func getFollowsList() {
        if userId == AmityUIKitManagerInternal.shared.client.currentUserId {
            followersCollection = type == .followers ? followManager.getMyFollowers(with: .accepted) : followManager.getMyFollowers(with: .accepted)
        } else {
            followersCollection = type == .followers ? followManager.getFollowers(withUserId: userId) : followManager.getFollowings(withUserId: userId)
        }
        
        followToken = followersCollection?.observe { [weak self] collection, _, error in
            self?.prepareDataSource(collection: collection, error: error)
        }
    }
    
    func loadMoreFollowingList() {
        guard let collection = followersCollection else { return }
        
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                collection.nextPage()
            }
        default: break
        }
    }
    
    func reportUser(at indexPath: IndexPath) {
        guard let user = getUser(at: indexPath) else { return }
        moderationManager.flagUser(userId: user.userId) { [weak self] success, error in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModel(strongSelf, didReportUserSuccess: indexPath)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func unreportUser(at indexPath: IndexPath) {
        guard let user = getUser(at: indexPath) else { return }
        moderationManager.unflagUser(userId: user.userId) { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModel(strongSelf, didUnreportUserSuccess: indexPath)
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func getReportUserStatus(at indexPath: IndexPath) {
        guard let user = getUser(at: indexPath) else { return }
        moderationManager.isFlaggedByMe(userId: user.userId) { [weak self] isReported, error in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.screenViewModel(strongSelf, didGetReportUserStatus: isReported, at: indexPath)
        }
    }
    
    func removeUser(at indexPath: IndexPath) {
        guard let user = getUser(at: indexPath) else { return }
        relationshipManager.declineUser(userId: user.userId) { [weak self] success, response, error in
            guard let strongSelf = self else { return }
            if success {
                strongSelf.delegate?.screenViewModel(strongSelf, didRemoveUser: indexPath)
                strongSelf.getFollowsList()
            } else if let error = error {
                strongSelf.delegate?.screenViewModel(strongSelf, failure: AmityError(error: error) ?? .unknown)    
            }
        }
    }
    
}

private extension AmityFollowersListScreenViewModel {
    func getUser(at indexPath: IndexPath) -> AmityUser? {
        let recordAtRow = followersList[indexPath.row]
        return type == .followers ? recordAtRow.sourceUser : recordAtRow.targetUser
    }
    
    private func prepareDataSource(collection: AmityCollection<AmityFollowRelationship>, error: Error?) {
        if let _ = error {
            followToken?.invalidate()
            delegate?.screenViewModelDidGetListFail()
            return
        }
        
        switch collection.dataStatus {
        case .fresh:
            var followers: [AmityFollowRelationship] = []
            for i in 0..<collection.count() {
                guard let follow = collection.object(at: i) else { continue }
                followers.append(follow)
            }
            
            followersList = followers
            delegate?.screenViewModelDidGetListSuccess()
        default: break
        }
    }
}
