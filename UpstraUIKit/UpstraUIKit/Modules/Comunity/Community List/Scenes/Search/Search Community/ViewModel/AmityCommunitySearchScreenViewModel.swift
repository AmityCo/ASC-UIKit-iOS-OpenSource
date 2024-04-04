//
//  AmityCommunitySearchScreenViewModel.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 26/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

final class AmityCommunitySearchScreenViewModel: AmityCommunitySearchScreenViewModelType {
    
    enum SearchState {
        case initial
        case loading
        case loaded(success: Bool)
    }
    
    weak var delegate: AmityCommunitySearchScreenViewModelDelegate?
    
    // MARK: - Manager
    private let communityListRepositoryManager: AmityCommunityListRepositoryManagerProtocol
    
    // MARK: - Properties
    private let debouncer = Debouncer(delay: 0.2)
    private var communityList: [AmityCommunityModel] = []
    
    init(communityListRepositoryManager: AmityCommunityListRepositoryManagerProtocol) {
        self.communityListRepositoryManager = communityListRepositoryManager
    }
}

// MARK: - DataSource
extension AmityCommunitySearchScreenViewModel {
    
    func numberOfCommunity() -> Int {
        return communityList.count
    }
    
    func item(at indexPath: IndexPath) -> AmityCommunityModel? {
        guard !communityList.isEmpty else { return nil }
        return communityList[indexPath.row]
    }
    
}

// MARK: - Action
extension AmityCommunitySearchScreenViewModel {
    
    func search(withText text: String?) {
        communityList = []
        guard let text = text, !text.isEmpty else {
            debouncer.cancel()
            communityListRepositoryManager.invalidate()
            delegate?.screenViewModelDidSearch(self, state: .initial)
            return
        }

        delegate?.screenViewModelDidSearch(self, state: .loading)
        debouncer.run { [weak self] in
            self?.searchCommunities(with: text)
        }
    }
    
    private func searchCommunities(with text: String) {
        self.communityListRepositoryManager.search(withText: text, filter: .all) { [weak self] (communityList) in
            guard let self else { return }
            self.communityList = communityList
            self.delegate?.screenViewModelDidSearch(self, state: .loaded(success: !communityList.isEmpty))
        }
    }
    
    func loadMore() {
        communityListRepositoryManager.loadMore()
    }
    
}
