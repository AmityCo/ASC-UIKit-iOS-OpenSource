//
//  AmityPostTargetPickerScreenViewModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 27/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK
import UIKit

class AmityPostTargetPickerScreenViewModel: AmityPostTargetPickerScreenViewModelType {
    
    weak var delegate: AmityPostTargetPickerScreenViewModelDelegate?
    
    private let communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    private var communityCollection: AmityCollection<AmityCommunity>?
    private var communities: [AmityCommunity] = []
    private var categoryCollectionToken:AmityNotificationToken?
    
    func observe() {
        let queryOptions = AmityCommunityQueryOptions(displayName: "", filter: .userIsMember, sortBy: .displayName, includeDeleted: false)
        communityCollection = communityRepository.getCommunities(with: queryOptions)
        categoryCollectionToken = communityCollection?.observe({ [weak self] (collection, _, _) in
            self?.communities = []

            guard let strongSelf = self else { return }
            let dispatchGroup = DispatchGroup()

            switch collection.dataStatus {
            case .fresh:
                for item in collection.snapshots {
                    dispatchGroup.enter()
                    
                    if item.onlyAdminCanPost {
                        AmityUIKitManager.client.hasPermission(.createPrivilegedPost, forCommunity: item.communityId) { success in
                            if success {
                                self?.communities.append(item)
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        self?.communities.append(item)
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.screenViewModelDidUpdateItems(strongSelf)
                }
            default: break
            }
        })
    }
    
    func numberOfItems() -> Int {
        return communities.count
    }
    
    func community(at indexPath: IndexPath) -> AmityCommunity? {
        return communities[indexPath.row]
    }
    
    func loadNext() {
        guard let collection = communityCollection else { return }
        switch collection.loadingStatus {
        case .loaded:
            collection.nextPage()
        default:
            break
        }
    }
    
}
