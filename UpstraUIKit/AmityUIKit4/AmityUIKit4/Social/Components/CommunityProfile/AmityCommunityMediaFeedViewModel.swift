//
//  AmityCommunityMediaFeedViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import Foundation
import AmitySDK
import Combine
import UIKit

enum MediaFeedType: Equatable {
    case community(communityId: String)
    case user(userId: String)
}

class MediaFeedViewModel: ObservableObject {
    @Published var medias: [AmityMedia] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    private let feedType: MediaFeedType
    private var cancellable: AnyCancellable?
    private var loadingCancellable: AnyCancellable?
    private let postManager = PostManager()
    private var postCollection: AmityCollection<AmityPost>?
    
    @Published var showMediaViewer: Bool = false
    var selectedMediaIndex: Int = 0
    var videoURL: URL? = nil
    
    init(feedType: MediaFeedType) {
        self.feedType = feedType
    }
    
    func loadMediaFeed(_ type: PostTypeFilter) {
        let queryOptions: AmityPostQueryOptions
        
        switch feedType {
        case .community(let communityId):
            queryOptions = AmityPostQueryOptions(targetType: .community, targetId: communityId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: [type.rawValue])
        case .user(let userId):
            queryOptions = AmityPostQueryOptions(targetType: .user, targetId: userId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: [type.rawValue])
        }
        
        postCollection = postManager.getPosts(options: queryOptions)
        cancellable = postCollection?.$snapshots
            .sink(receiveValue: { [weak self] posts in
                self?.medias.removeAll()
            
                // Traverse all post to prepare the data soruce.
                self?.medias.append(contentsOf: posts.flatMap { post -> [AmityMedia] in
                    let model = AmityPostModel(post: post)
                    return model.medias
                })
                
            })
        
        loadingCancellable = postCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
    
    func loadMore() {
        guard let postCollection, postCollection.hasNext else { return }
        postCollection.nextPage()
    }
}
