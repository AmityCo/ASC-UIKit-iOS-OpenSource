//
//  AmityMemberListRepositoryManager.swift
//  AmityUIKit
//
//  Created by Hamlet on 11.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityMemberListRepositoryManagerProtocol {
    func search(withText text: String, sortyBy: AmityUserSortOption, _ completion: (([AmityUserModel]) -> Void)?)
    func loadMore()
}

final class AmityMemberListRepositoryManager: AmityMemberListRepositoryManagerProtocol {
    
    private let repository: AmityUserRepository
    private var collection: AmityCollection<AmityUser>?
    private var token: AmityNotificationToken?
    
    init() {
        repository = AmityUserRepository()
    }
    
    func search(withText text: String, sortyBy: AmityUserSortOption, _ completion: (([AmityUserModel]) -> Void)?) {
        collection = repository.searchUsers(text, sortBy: sortyBy)
        token?.invalidate()
        token = collection?.observe { [weak self] (collection, error) in
            if collection.dataStatus == .fresh {
                var membersList: [AmityUserModel] = []
                for index in 0..<collection.snapshots.count {
                    let object = collection.snapshots[index]
                    let model = AmityUserModel(user: object)
                    membersList.append(model)
                }
                completion?(membersList)
                self?.token?.invalidate()
            }
        }
    }
    
    func loadMore() {
        guard let collection = collection else { return }
        switch collection.loadingStatus {
        case .loaded:
            if collection.hasNext {
                collection.nextPage()
            }
        default:
            break
        }
    }
}
