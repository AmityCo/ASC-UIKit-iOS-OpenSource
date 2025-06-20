//
//  AmityCommunitySetupPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/7/24.
//

import AmitySDK
import UIKit

enum AddMemberModelType {
    case user, create
}

struct AddMemberModel {
    var id: String {
        return user?.userId ?? "AddMember"
    }
    var user: AmityUserModel?
    var type: AddMemberModelType
}

struct CommunityModel {
    var avatar: UIImage?
    var displayName: String
    var description: String?
    var categoryIds: [String] = []
    var userIds: [String] = []
    var privacy: CommunityPrivacyType
    var requiresModeratorApproval: Bool
}

class AmityCommunitySetupPageViewModel: ObservableObject {
    let communityManager: CommunityManager = CommunityManager()
    let fileRepostiory: AmityFileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    let postManager: PostManager = PostManager()
    let mode: AmityCommunitySetupPageMode
    var token: AmityNotificationToken?
    var hasGlobalPinnedPost = false
    var communityId: String?
    var isMembershipInvitationEnabled: Bool = false
    
    var joinRequestToken: AmityNotificationToken?
    var hasPendingJoinRequests: Bool = false
    
    init(mode: AmityCommunitySetupPageMode, communityId: String?) {
        self.mode = mode
        self.communityId = communityId
        self.checkGlobalPinnedPostPresence()
        self.checkPendingJoinRequests()
        if let setting = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.membershipAcceptance {
            isMembershipInvitationEnabled = setting == .invitation
        }
    }
    
    func createCommunity(_ model: CommunityDraft) async throws -> AmityCommunity {
        let createOptions = AmityCommunityCreateOptions()
        createOptions.setDisplayName(model.name)
        
        let categoryIds = model.categories.map { $0.categoryId }
        createOptions.setCategoryIds(categoryIds)
        
        switch model.privacy {
        case .public:
            createOptions.setIsPublic(true)
            createOptions.setRequiresJoinApproval(model.requiresModeratorApproval)
        case .privateAndVisible:
            createOptions.setIsPublic(false)
            createOptions.setIsDiscoverable(true)
            createOptions.setRequiresJoinApproval(model.requiresModeratorApproval)
        case .privateAndHidden:
            createOptions.setIsPublic(false)
            createOptions.setIsDiscoverable(false)
            createOptions.setRequiresJoinApproval(true)
        }
        
        if !isMembershipInvitationEnabled {
            createOptions.setUserIds(model.userIds)
        }
        
        if !model.about.isEmpty {
            createOptions.setCommunityDescription(model.about)
        }
        
        if let avatar = model.avatar {
            let imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
            createOptions.setAvatar(imageData)
        }
        
        return try await communityManager.createCommunity(createOptions)
    }
    
    func editCommunity(id: String, _ model: CommunityDraft) async throws -> AmityCommunity {
        let updateOptions = AmityCommunityUpdateOptions()
        updateOptions.setDisplayName(model.name)
        let categoryIds = model.categories.map { $0.categoryId }
        updateOptions.setCategoryIds(categoryIds)
        
        switch model.privacy {
        case .public:
            updateOptions.setIsPublic(true)
            updateOptions.setRequiresJoinApproval(model.requiresModeratorApproval)
        case .privateAndVisible:
            updateOptions.setIsPublic(false)
            updateOptions.setIsDiscoverable(true)
            updateOptions.setRequiresJoinApproval(model.requiresModeratorApproval)
        case .privateAndHidden:
            updateOptions.setIsPublic(false)
            updateOptions.setIsDiscoverable(false)
            updateOptions.setRequiresJoinApproval(true)
        }
        
        if !model.about.isEmpty {
            updateOptions.setCommunityDescription(model.about)
        }
        
        if let avatar = model.avatar {
            let imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
            updateOptions.setAvatar(imageData)
        }
        
        return try await communityManager.editCommunity(withId: id, updateOptions: updateOptions)
    }
    
    func inviteMembers(_ userIds: [String], toCommunity community: AmityCommunity) async throws {
        try await community.createInvitations(userIds)
    }
    
    func checkGlobalPinnedPostPresence() {
        guard case .edit = mode else {
            return
        }
        
        token = postManager.getGlobalPinnedPost().observe({ [weak self] liveCollection, _, error in
            guard let self, liveCollection.dataStatus == .fresh else { return }
            
            let snapshots = liveCollection.snapshots
            snapshots.forEach { pinnedPost in
                if let post = pinnedPost.post, let communityId = self.communityId, post.targetId == communityId {
                    self.hasGlobalPinnedPost = true
                }
            }
            
            self.token?.invalidate()
            self.token = nil
        })
    }
    
    func checkPendingJoinRequests() {
        guard case .edit(let community) = mode else {
            return
        }
        
        joinRequestToken = community.getJoinRequests(status: .pending).observe { [weak self] liveCollection, _, error in
            guard let self, liveCollection.dataStatus == .fresh else { return }
            
            self.hasPendingJoinRequests = liveCollection.count() > 0
            
            self.joinRequestToken?.invalidate()
            self.joinRequestToken = nil
        }
    }
}

enum CommunityPrivacyType: String {
    case `public` = "public" // default public
    case privateAndVisible = "privateAndVisible" // Discoverable private community
    case privateAndHidden = "privateAndHidden" // default private
}

class CommunityDraft: ObservableObject, Equatable {
    
    @Published var name: String = ""
    @Published var about: String = ""
    @Published var requiresModeratorApproval = false
    @Published var privacy: CommunityPrivacyType = .public
    @Published var categories: [AmityCommunityCategoryModel] = []
    
    // Not used in comparison at the moment
    @Published var avatar: UIImage? = nil
    @Published var userIds: [String] = []
    
    init(
        name: String = "",
        about: String = "",
        requiresModeratorApproval: Bool = false,
        privacy: CommunityPrivacyType = .public
    ) {
        self.name = name
        self.about = about
        self.requiresModeratorApproval = requiresModeratorApproval
        self.privacy = privacy
    }
    
    init(community: AmityCommunity) {
        self.name = community.displayName
        self.about = community.communityDescription
        self.requiresModeratorApproval = community.requiresJoinApproval
        self.categories = community.categories.map { AmityCommunityCategoryModel(object: $0) }
        if community.isPublic {
            self.privacy = .public
        } else if !community.isPublic && community.isDiscoverable {
            self.privacy = .privateAndVisible
        } else {
            self.privacy = .privateAndHidden
        }
    }
    
    static func == (lhs: CommunityDraft, rhs: CommunityDraft) -> Bool {
        return lhs.name == rhs.name
        && lhs.about == rhs.about
        && lhs.requiresModeratorApproval == rhs.requiresModeratorApproval
        && lhs.privacy == rhs.privacy
        && (lhs.categories.elementsEqual(
            rhs.categories,
            by: { lhs, rhs in
                lhs.categoryId == rhs.categoryId
            }))
    }
    
    func hasChanges(with draft: CommunityDraft) -> Bool {
        return self != draft
    }
    
    func requiresConfirmationForPrivacyChanges(with initial: CommunityDraft) -> [CommunitySetupConfirmation] {
        var confirmations: [CommunitySetupConfirmation] = []
        let final = self
        
        // Rule 0: No privacy changes, no confirmations required
        if initial.privacy == final.privacy && initial.requiresModeratorApproval == final.requiresModeratorApproval {
            return []
        }

        // Rule 1: When moderator approval is being removed, show pending join requests confirmation
        if initial.requiresModeratorApproval && !final.requiresModeratorApproval {
            confirmations.append(.pendingJoinRequests)
        }
        
        // Rule 2: When making community private (from public), show featured posts warning
        if initial.privacy == .public && (final.privacy == .privateAndVisible || final.privacy == .privateAndHidden) {
            confirmations.append(.globalFeaturedPosts)
        }
        
        return confirmations
    }
}

enum CommunitySetupConfirmation {
    case pendingJoinRequests
    case globalFeaturedPosts
    case discard
}
