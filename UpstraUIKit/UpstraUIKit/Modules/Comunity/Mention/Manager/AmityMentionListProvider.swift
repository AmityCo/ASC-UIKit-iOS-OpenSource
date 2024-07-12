//
//  AmityMentionListProvider.swift
//  AmityUIKit
//
//  Created by Nishan on 8/7/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

// Work In Progress: Decoupled class which provides list of users to mention from live collection.
public class MentionListProvider {
    
    // Mention Configuration
    // We can use this to determine if mention @all is enabled or not.
    private var mentionConfiguration: AmityMentionConfigurations? = AmityUIKitManagerInternal.shared.client.mentionConfigurations
    private var mentionType: AmityMentionManagerType
    private var canMentionAll = false // Mention all members in a channel
    
    // Repositories
    private var userRepository: AmityUserRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    private var channelMembersRepository: AmityChannelMembership?
    private var communityRepository: AmityCommunityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    
    // Collection
    private var channelMembersCollection: AmityCollection<AmityChannelMember>? // Channel Members
    private var usersCollection: AmityCollection<AmityUser>? // All Users
    private var communityMembersCollection: AmityCollection<AmityCommunityMember>? // Private community members
    
    // Token
    private var mentionListToken: AmityNotificationToken?
    private var communityToken: AmityNotificationToken?
    
    // Models
    private var community: AmityCommunityModel?
    
    // If sdk is searching for provided display name
    public var mentionList: [AmityMentionUserModel] = []
    
    // Callback
    public var didGetMentionList: (([AmityMentionUserModel]) -> Void)?

    public init(type: AmityMentionManagerType) {
        self.mentionType = type
        let client = AmityUIKitManagerInternal.shared.client
        
        switch type {
        case .post(let communityId), .comment(let communityId):
            if let communityId {
                setupCommunity(withId: communityId)
            }
        case .message(let subChannelId):
            if let channelId = subChannelId {
                channelMembersRepository = AmityChannelMembership(client: client, andChannel: channelId)
            }
        }
        
//        self.checkMentionPermission()
    }
    
//    func checkMentionPermission() {
//        if case let .message(subChannelId)  = mentionType {
//            ChatPermissionChecker.hasModeratorPermission(for: subChannelId ?? "") { hasPermission in
//                self.canMentionAll = hasPermission
//            }
//        }
//    }
    
    public func searchUser(text: String) {
        switch mentionType {
        case .post(let communityId), .comment(let communityId):
            if let communityId, !(community?.isPublic ?? true) {
                // Search for members in that community
                searchCommunityMembers(with: text, communityId: communityId)
                return
            }
            
            // Search for users
            searchUsers(with: text)
        case .message:
            searchChannelMembers(with: text)
        }
    }
    
    public func loadMore() {
        switch mentionType {
        case .post(let communityId), .comment(let communityId):
            if let communityId, !(community?.isPublic ?? true) {
                // load more members in that community
                if let communityMembersCollection, communityMembersCollection.hasNext {
                    communityMembersCollection.nextPage()
                }
                return
            }
            
            // load more users
            if let usersCollection, usersCollection.hasNext {
                usersCollection.nextPage()
            }
        case .message:
            if let channelMembersCollection, channelMembersCollection.hasNext {
                channelMembersCollection.nextPage()
            }
        }
    }
    
    // Equivalent to reset state()
    public func reset() {
        mentionList = []
        
        mentionListToken?.invalidate()
        mentionListToken = nil
        
        channelMembersCollection = nil
        usersCollection = nil
        communityMembersCollection = nil
    }
    
    private func setupCommunity(withId communityId: String) {
        communityToken = communityRepository.getCommunity(withId: communityId).observe { [weak self] liveObject, error in
            if liveObject.dataStatus == .fresh {
                self?.communityToken?.invalidate()
            }
            
            guard let community = liveObject.snapshot else { return }
            self?.community = AmityCommunityModel(object: community)
        }
    }
    
    private func searchChannelMembers(with displayName: String) {
        let builder = AmityChannelMembershipFilterBuilder()
        builder.add(filter: .member)
        builder.add(filter: .mute)
        
        // Invalidate existing token
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        channelMembersCollection = channelMembersRepository?.searchMembers(displayName: displayName, filterBuilder: builder, roles: [])
        mentionListToken = channelMembersCollection?.observe({ [weak self] liveCollection, _, error in
            self?.handleSearchResponse(with: liveCollection)
        })
    }
    
    private func searchUsers(with displayName: String) {
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        usersCollection = userRepository.searchUsers(displayName, sortBy: .displayName)
        mentionListToken = usersCollection?.observe { [weak self] liveCollection, _, error in
            self?.handleSearchResponse(with: liveCollection)
        }
    }
    
    private func searchCommunityMembers(with displayName: String, communityId: String) {
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        communityMembersCollection = communityRepository.searchMembers(communityId: communityId, displayName: displayName, membership: .member, roles: [], sortBy: .lastCreated)
        mentionListToken = communityMembersCollection?.observe { [weak self] liveCollection, _, error in
            self?.handleSearchResponse(with: liveCollection)
        }
    }
    
    private func handleSearchResponse<T>(with collection: AmityCollection<T>) {
        switch collection.dataStatus {
        case .fresh:
            var updatedList = [AmityMentionUserModel]()
            
            for i in 0..<collection.count() {
                guard let object = collection.object(at: i) else { continue }
                
                if T.self == AmityCommunityMember.self {
                    guard let member = object as? AmityCommunityMember, let user = member.user else { continue }
                    updatedList.append(AmityMentionUserModel(user: user))
                    
                } else if T.self == AmityChannelMember.self {
                    guard let memberObject = object as? AmityChannelMember, let user = memberObject.user else { continue }
                    updatedList.append(AmityMentionUserModel(user: user))
                    
                } else {
                    guard let userObject = object as? AmityUser else { continue }
                    updatedList.append(AmityMentionUserModel(user: userObject))
                }
            }
            
            // Incase of message, if @all mention is allowed, append it to the top
            if case .message = mentionType {
                if self.canMentionAll {
                    updatedList.insert(AmityMentionUserModel.channelMention, at: 0)
                }
            }
            
            // Update & Notify
            self.mentionList = updatedList
            self.didGetMentionList?(self.mentionList)
            
        case .error:
            mentionListToken?.invalidate()
            didGetMentionList?(self.mentionList)
        default:
            break
        }
    }
}
