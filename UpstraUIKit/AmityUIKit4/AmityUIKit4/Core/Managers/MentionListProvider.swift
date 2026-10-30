//
//  MentionListProvider.swift
//  AmityUIKit4
//
//  Created by Nishan on 27/3/2567 BE.
//

import Foundation
import AmitySDK
import Combine

// Work In Progress: Decoupled class which provides list of users to mention from live collection.
class MentionListProvider {
    
    // Mention Configuration
    // We can use this to determine if mention @all is enabled or not.
    private var mentionConfiguration: AmityMentionConfigurations? = AmityUIKitManagerInternal.shared.client.mentionConfigurations
    private var mentionType: MentionManagerType
    private var canMentionAll = false // Mention all members in a channel
    
    // Repositories
    private var userRepository: AmityUserRepository = AmityUserRepository()
    private var channelMembersRepo: AmityChannelMembership?
    private var communityMembersRepo: AmityCommunityMembership?
    private var communityRepository: AmityCommunityRepository = AmityCommunityRepository()
    
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
    private var currentSearchText: String = ""

    // True from the moment a search is issued until its first page settles.
    public private(set) var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }
            didChangeLoadingState?(isLoading)
        }
    }
    private var loadingGeneration = 0
    private var loadingStatusCancellable: AnyCancellable?

    // Callback
    public var didGetMentionList: (([AmityMentionUserModel]) -> Void)?
    public var didChangeLoadingState: ((Bool) -> Void)?

    public init(type: MentionManagerType) {
        self.mentionType = type
        let client = AmityUIKitManagerInternal.shared.client
        
        switch type {
        case .post(let communityId), .comment(let communityId):
            if let communityId {
                setupCommunity(withId: communityId)
            }
        case .message(let subChannelId):
            if let channelId = subChannelId {
                channelMembersRepo = AmityChannelMembership(channelId: channelId)
            }
        }
        
        self.checkMentionPermission()
    }
    
    func checkMentionPermission() {
        if case .message = mentionType {
            canMentionAll = mentionConfiguration?.isMentionAllEnabled ?? false
        }
    }
    
    public func searchUser(text: String) {
        switch mentionType {
        case .post(let communityId), .comment(let communityId):
            if let communityId, !(community?.isPublic ?? true) {
                // Search for members in that community
                searchCommunityMembers(with: text, communityId: communityId)
                return
            }
            
            // Search for users
            // Don't search if the text count is 1 or 2, as sdk doesn't return any result for that query.
            // Maintain the existing searched user list in that case.
            if !(1...2 ~= text.count) {
                searchUsers(with: text)
            }
        case .message:
            searchChannelMembers(with: text)
        }
    }
    
    func loadMore() {
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
    
    func reset() {
        mentionList = []
        currentSearchText = ""

        mentionListToken?.invalidate()
        mentionListToken = nil

        channelMembersCollection = nil
        usersCollection = nil
        communityMembersCollection = nil

        loadingGeneration += 1
        loadingStatusCancellable = nil
        isLoading = false
    }

    private func trackLoading<T>(of collection: AmityCollection<T>?) {
        loadingGeneration += 1
        let generation = loadingGeneration
        isLoading = collection != nil

        // A new collection reports `.notLoading` until its request starts, so wait for `.loading` first.
        // Settling on the status covers searches that end without an `observe` callback (errors, and
        // empty results for an empty keyword), which would otherwise leave the skeleton up.
        loadingStatusCancellable = collection?.$loadingStatus
            .drop(while: { $0 != .loading })
            .first(where: { $0 != .loading })
            .sink { [weak self] _ in
                // The page's results reach `observe` one main-queue hop after the status settles;
                // hop past them so the list never renders empty in between.
                DispatchQueue.main.async {
                    DispatchQueue.main.async {
                        guard let self, self.loadingGeneration == generation else { return }
                        self.isLoading = false
                    }
                }
            }
    }
    
    private func setupCommunity(withId communityId: String) {
        communityMembersRepo = AmityCommunityMembership(communityId: communityId)
        communityToken = communityRepository.getCommunity(withId: communityId).observe { [weak self] liveObject, error in
            if liveObject.dataStatus == .fresh {
                self?.communityToken?.invalidate()
            }
            
            guard let community = liveObject.snapshot else { return }
            self?.community = AmityCommunityModel(object: community)
        }
    }
    
    private func searchChannelMembers(with displayName: String) {
        self.currentSearchText = displayName

        let builder = AmityChannelMembershipFilterBuilder()
        builder.add(filter: .member)
        builder.add(filter: .mute)

        // Invalidate existing token
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        channelMembersCollection = channelMembersRepo?.searchMembers(displayName: displayName, searchBy: [.displayName], filterBuilder: builder, roles: [], includeDeleted: false)
        mentionListToken = channelMembersCollection?.observe({ [weak self] liveCollection, error in
            self?.handleSearchResponse(with: liveCollection)
        })
        trackLoading(of: channelMembersCollection)
    }
    
    private func searchUsers(with displayName: String) {
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        usersCollection = userRepository.searchUsers(displayName, searchBy: [.displayName], sortBy: .displayName, matchType: .partial)
        mentionListToken = usersCollection?.observe { [weak self] liveCollection, error in
            self?.handleSearchResponse(with: liveCollection)
        }
        trackLoading(of: usersCollection)
    }
    
    private func searchCommunityMembers(with displayName: String, communityId: String) {
        mentionListToken = nil
        mentionListToken?.invalidate()
        
        communityMembersCollection = communityMembersRepo?.searchMembers(keyword: displayName, filter: [.member], roles: [], sortBy: .lastCreated, includeDeleted: false)
        mentionListToken = communityMembersCollection?.observe { [weak self] liveCollection, error in
            self?.handleSearchResponse(with: liveCollection)
        }
        trackLoading(of: communityMembersCollection)
    }
    
    private func handleSearchResponse<T>(with collection: AmityCollection<T>) {
        switch collection.dataStatus {
        case .fresh:
            var updatedList = [AmityMentionUserModel]()
            
            for i in 0..<collection.snapshots.count {
                let object = collection.snapshots[i]
                
                if T.self == AmityCommunityMember.self {
                    guard let member = object as? AmityCommunityMember, let user = member.user else { continue }
                    updatedList.append(AmityMentionUserModel(user: user))
                    
                } else if T.self == AmityChannelMember.self {
                    guard let memberObject = object as? AmityChannelMember, let user = memberObject.user, user.isGlobalBanned == false else { continue }
                    updatedList.append(AmityMentionUserModel(user: user))
                    
                } else {
                    guard let userObject = object as? AmityUser else { continue }
                    updatedList.append(AmityMentionUserModel(user: userObject))
                }
            }
            
            // Incase of message, if @all mention is allowed, append it to the top
            if case .message = mentionType {
                if self.canMentionAll && self.currentSearchText.isEmpty {
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
