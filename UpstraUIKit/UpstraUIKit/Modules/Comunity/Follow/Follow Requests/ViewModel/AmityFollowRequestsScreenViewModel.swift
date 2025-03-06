//
//  AmityFollowRequestsScreenViewModel.swift
//  AmityUIKit
//
//  Created by Hamlet on 17.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityFollowRequestsScreenViewModel: AmityFollowRequestsScreenViewModelType {
    
    weak var delegate: AmityFollowRequestsScreenViewModelDelegate?
    
    // MARK: - Properties
    let userId: String
    private let userRepository: AmityUserRepository
    private let followManager: AmityUserRelationship
    private var followToken: AmityNotificationToken?
    private var followRequests: [AmityFollowRelationship] = []
    private var followRequestCollection: AmityCollection<AmityFollowRelationship>?
    
    // MARK: - Initializer
    init(userId: String) {
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        followManager = userRepository.userRelationship
        self.userId = userId
    }
}

// MARK: - DataSource
extension AmityFollowRequestsScreenViewModel {
    func numberOfRequests() -> Int {
        return followRequests.count
    }
    
    func item(at indexPath: IndexPath) -> AmityFollowRelationship {
        return followRequests[indexPath.row]
    }
}

// MARK: - Action
extension AmityFollowRequestsScreenViewModel {
    func getFollowRequests() {
        followToken?.invalidate()
        followRequestCollection = followManager.getMyFollowers(with: AmityFollowQueryOption.pending)
        followToken = followRequestCollection?.observe { [weak self] collection, _, error in
            self?.prepareDataSource(collection: collection, error: error)
        }
    }
    
    func acceptRequest(at indexPath: IndexPath) {
        let request = self.item(at: indexPath)
        Task { @MainActor in
            do {
                let result = try await followManager.acceptMyFollower(withUserId: request.sourceUserId)
                let isSuccessful = result.0
                if isSuccessful {
                    self.removeRequest(at: indexPath)
                    self.delegate?.screenViewModel(self, didAcceptRequestAt: indexPath)
                }
            } catch let error {
                self.delegate?.screenViewModel(self, didFailToAcceptRequestAt: indexPath)
            }
        }
    }
    
    func declineRequest(at indexPath: IndexPath) {
        let request = self.item(at: indexPath)
        Task { @MainActor in
            do {
                let result = try await followManager.declineMyFollower(withUserId: request.sourceUserId)
                let isSuccessful = result.0
                if isSuccessful {
                    self.removeRequest(at: indexPath)
                    self.delegate?.screenViewModel(self, didDeclineRequestAt: indexPath)
                }
            } catch let error {
                self.delegate?.screenViewModel(self, didFailToDeclineRequestAt: indexPath)
            }
        }
    }
    
    func removeRequest(at indexPath: IndexPath) {
        if indexPath.row < followRequests.count {
            followRequests.remove(at: indexPath.row)
            delegate?.screenViewModel(self, didRemoveRequestAt: indexPath)
        }
    }
    
    func reload() {
        getFollowRequests()
    }
}

private extension AmityFollowRequestsScreenViewModel {
    func prepareDataSource(collection: AmityCollection<AmityFollowRelationship>, error: Error?) {
        if let error = error {
            delegate?.screenViewModel(self, failure: AmityError(error: error) ?? .unknown)
            followToken?.invalidate()
            return
        }
        
        switch collection.dataStatus {
        case .fresh:
            var newRequests: [AmityFollowRelationship] = []
            for i in 0..<collection.count() {
                guard let follow = collection.object(at: i) else { continue }
                newRequests.append(follow)
            }
            
            followRequests = newRequests
            delegate?.screenViewModelDidGetRequests()
        default: break
        }
    }
}
