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
    var isPublic: Bool
    var userIds: [String] = []
}


class AmityCommunitySetupPageViewModel: ObservableObject {
    let communityManager: CommunityManager = CommunityManager()
    let fileRepostiory: AmityFileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    let postManager: PostManager = PostManager()
    let mode: AmityCommunitySetupPageMode
    var token: AmityNotificationToken?
    var hasGlobalPinnedPost = false
    var communityId: String?
    
    init(mode: AmityCommunitySetupPageMode, communityId: String?) {
        self.mode = mode
        self.communityId = communityId
        self.checkGlobalPinnedPostPresence()
    }
    
    func createCommunity(_ model: CommunityModel) async throws -> AmityCommunity {
        let createOptions = AmityCommunityCreateOptions()
        createOptions.setDisplayName(model.displayName)
        createOptions.setCategoryIds(model.categoryIds)
        createOptions.setIsPublic(model.isPublic)
        createOptions.setUserIds(model.userIds)
        
        if let description = model.description {
            createOptions.setCommunityDescription(description)
        }
        
        
        if let avatar = model.avatar {
            let imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
            createOptions.setAvatar(imageData)
        }

        return try await communityManager.createCommunity(createOptions)
    }
    
    func editCommunity(id: String, _ model: CommunityModel) async throws -> AmityCommunity {
        let updateOptions = AmityCommunityUpdateOptions()
        updateOptions.setDisplayName(model.displayName)
        updateOptions.setCategoryIds(model.categoryIds)
        updateOptions.setIsPublic(model.isPublic)
        
        if let description = model.description {
            updateOptions.setCommunityDescription(description)
        }
        
        
        if let avatar = model.avatar {
            let imageData = try await fileRepostiory.uploadImage(avatar, progress: nil)
            updateOptions.setAvatar(imageData)
        }
        
        return try await communityManager.editCommunity(withId: id, updateOptions: updateOptions)
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
}
