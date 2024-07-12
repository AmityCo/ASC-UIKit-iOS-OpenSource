//
//  CommunityProfileViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import AmitySDK

class CommunityProfileViewModel: ObservableObject {
    @Published var community: AmityCommunityModel?
    @Published var pinnedPostIds: AmityCommunityModel?
    
    private let communityManger = CommunityManager()
    private let communityId: String
    
    private var token: AmityNotificationToken?
    
    public init(communityId: String) {
        self.communityId = communityId
        
        token = communityManger.getCommunity(withId: communityId).observe { [weak self] community, error in
            guard let communityObject = community.snapshot else { return }
            self?.community = AmityCommunityModel(object: communityObject)
        }
        
    }
    
    func getPendingPostCount() -> Int {
        guard let community = community, community.isPostReviewEnabled else {
            return 0
        }
        return community.object.getPostCount(feedType: .reviewing)        
    }
    
    @MainActor
    func joinCommunity() async throws {
        try await communityManger.joinCommunity(withId: communityId)
    }
    
    func hasModeratorRole() -> Bool {
        if let communityMember = community?.object.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId) {
            return communityMember.hasModeratorRole
        }
        return false
    }
}
