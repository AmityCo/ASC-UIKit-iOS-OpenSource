//
//  AmityCommunityFetchMemberController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 22/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityCommunityFetchMemberControllerProtocol {
    func fetch(roles: [String], _ completion: @escaping (Result<[AmityCommunityMembershipModel], Error>) -> Void)
    func loadMore(_ completion: (Bool) -> Void)
}

final class AmityCommunityFetchMemberController: AmityCommunityFetchMemberControllerProtocol {
    
    private var membership: AmityCommunityMembership?
    private var memberCollection: AmityCollection<AmityCommunityMember>?
    private var memberToken: AmityNotificationToken?
    
    init(communityId: String) {
        membership = AmityCommunityMembership(communityId: communityId)
    }
    
    func fetch(roles: [String], _ completion: @escaping (Result<[AmityCommunityMembershipModel], Error>) -> Void) {
        memberCollection = membership?.getMembers(filter: .member, roles: roles, sortBy: .lastCreated, includeDeleted: false)
        memberToken = memberCollection?.observe { (collection, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                var members: [AmityCommunityMembershipModel] = []
                for index in 0..<collection.snapshots.count {
                    let member = collection.snapshots[index]
                    members.append(AmityCommunityMembershipModel(member: member))
                }
                completion(.success(members))
            }
        }
    }
    
    func loadMore(_ completion: (Bool) -> Void) {
        guard let collection = memberCollection else {
            completion(true)
            return
        }
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                collection.nextPage()
                completion(true)
            }
        default:
            completion(false)
        }
    }   
}
