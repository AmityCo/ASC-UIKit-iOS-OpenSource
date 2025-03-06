//
//  AmityUserProfileHeaderScreenViewModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 29/9/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK

final class AmityUserProfileHeaderScreenViewModel: AmityUserProfileHeaderScreenViewModelType {
    // MARK: - Properties
    
    weak var delegate: AmityUserProfileHeaderScreenViewModelDelegate?
    
    let userId: String
    private(set) var user: AmityUserModel?
    private(set) var followInfo: AmityFollowInfo?
    private(set) var followStatus: AmityFollowStatus?
    
    private let userRepository: AmityUserRepository
    private let channelRepository: AmityChannelRepository
    private let followManager: AmityUserRelationship
    private var userToken: AmityNotificationToken?
    private var channelToken: AmityNotificationToken?
    private var followToken: AmityNotificationToken?
    private var pendingRequestsToken: AmityNotificationToken?
    
    // MARK: - Initializer
    
    init(userId: String) {
        userRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
        channelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
        followManager = userRepository.userRelationship
        self.userId = userId
    }
}

// MARK: Action
extension AmityUserProfileHeaderScreenViewModel {
    func fetchUserData() {
        userToken?.invalidate()
        userToken = userRepository.getUser(userId).observe { [weak self] object, error in
            guard let strongSelf = self else { return }
            // Due to `observeOnce` doesn't guarantee if the data is fresh or local.
            // So, this is a workaround to execute code specifically for fresh data status.
            switch object.dataStatus {
            case .fresh:
                if let user = object.snapshot {
                    strongSelf.prepareUserData(user: user)
                }
                strongSelf.userToken?.invalidate()
            case .error:
                strongSelf.delegate?.screenViewModel(strongSelf, didReceiveError: AmityError(error: error) ?? .unknown)
                strongSelf.userToken?.invalidate()
            case .local:
                if let user = object.snapshot {
                    strongSelf.prepareUserData(user: user)
                }
            case .notExist:
                strongSelf.userToken?.invalidate()
            @unknown default:
                break
            }
        }
    }
    
    func fetchFollowInfo() {
        followToken?.invalidate()
        
        if userId == AmityUIKitManagerInternal.shared.client.currentUserId {
            followToken = followManager.getMyFollowInfo().observe { [weak self] liveObject, error in
                guard let strongSelf = self else { return }
                
                if let object = liveObject.snapshot {
                    strongSelf.handleFollowInfo(followInfo: AmityFollowInfo(followInfo: object))
                } else {
                    strongSelf.delegate?.screenViewModel(strongSelf, didReceiveError: AmityError(error: error) ?? .unknown)
                }
            }
            
            return
        }
                
        followToken = followManager.getFollowInfo(withUserId: userId).observe { [weak self] liveObject, error in
            
            guard let strongSelf = self else { return }
            
            if let result = liveObject.snapshot {
                strongSelf.handleFollowInfo(followInfo: AmityFollowInfo(followInfo: result))
            } else {
                strongSelf.delegate?.screenViewModel(strongSelf, didReceiveError: AmityError(error: error) ?? .unknown)
            }
        }
    }
    
    func createChannel() {
        let builder = AmityConversationChannelBuilder()
        builder.setUserId(userId)
        builder.setDisplayName(user?.displayName ?? "")
        
        AmityAsyncAwaitTransformer.toCompletionHandler(asyncFunction: channelRepository.createChannel, parameters: builder) { [weak self] channelObject, _ in
            guard let strongSelf = self else { return }
            if let channel = channelObject {
                strongSelf.delegate?.screenViewModel(strongSelf, didCreateChannel: channel)
            }
        }
    }
    
    func follow() {
        Task { @MainActor in
            do {
                let result = try await followManager.follow(withUserId: userId)
                self.followStatus = result.1.status
                self.delegate?.screenViewModel(self, didFollowUser: result.1.status, error: nil)
            } catch let error {
                self.delegate?.screenViewModel(self, didFollowUser: .none, error: AmityError(error: error))
            }
        }
    }
    
    func unfollow() {
        Task { @MainActor in
            do {
                let result = try await followManager.unfollow(withUserId: userId)
                self.followStatus = result.1.status
                self.delegate?.screenViewModel(self, didUnfollowUser: result.1.status, error: nil)

            } catch let error {
                self.delegate?.screenViewModel(self, didUnfollowUser: .pending, error: AmityError(error: error))
            }
        }
    }
    
    @MainActor
    func unblockUser() {
        Task {
            do {
                try await followManager.unblockUser(userId: userId)
                
                self.followStatus = AmityFollowStatus.none
                self.delegate?.screenViewModel(self, didUnblockUser: nil)
            } catch let error {
                self.delegate?.screenViewModel(self, didUnblockUser: AmityError(error: error))
            }
        }
    }
}

private extension AmityUserProfileHeaderScreenViewModel {
    func handleFollowInfo(followInfo: AmityFollowInfo) {
        self.followInfo = followInfo
        followStatus = followInfo.status
        delegate?.screenViewModel(self, didGetFollowInfo: followInfo)
    }
    
    func prepareUserData(user: AmityUser) {
        let userModel = AmityUserModel(user: user)
        self.user = userModel
        delegate?.screenViewModel(self, didGetUser: userModel)
    }
}
