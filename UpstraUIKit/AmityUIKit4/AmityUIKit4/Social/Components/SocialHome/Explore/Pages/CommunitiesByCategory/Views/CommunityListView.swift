//
//  CommunityListView.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import AmitySDK

struct CommunityListView: View {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject public var viewConfig: AmityViewConfigController
    @StateObject var viewModel: CommunityListViewModel
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(viewModel.communities) { community in
                        VStack(spacing: 0) {
                            CommunityListItemView(community: community)
                                .onTapGesture {
                                    host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: AmityCommunityProfilePage(communityId: community.communityId)), animated: true)
                                }
                                .onAppear {
                                    if let lastCommunityId = viewModel.communities.last?.communityId, lastCommunityId == community.communityId {
                                        viewModel.loadMore()
                                    }
                                }
                            
                            Divider()
                                .opacity(viewModel.isLastCommunity(community: community) ? 0 : 1)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
            
            AmityEmptyStateView(configuration: .init(image: "communityNotFoundIcon", title: AmityLocalizedStringSet.Social.communityEmptyStateTitle.localizedString, subtitle: nil, iconSize: CGSize(width: 60, height: 60), renderingMode: .original, tapAction: nil))
                .opacity(viewModel.queryState == .loaded && viewModel.communities.isEmpty ? 1 : 0)

        }
        .padding(.horizontal)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .onAppear {
            viewModel.fetchCommunities()
        }
    }
}

class CommunityListViewModel: ObservableObject {

    private let repository: AmityCommunityRepository = .init(client: AmityUIKit4Manager.client)
    private var token: AmityNotificationToken?
    private var communityCollection: AmityCollection<AmityCommunity>?
    private let categoryId: String
    
    private let categoryRepository: AmityCommunityRepository = .init(client: AmityUIKit4Manager.client)
    private var categoryToken: AmityNotificationToken?
    
    @Published var communities: [AmityCommunityModel] = []
    @Published var queryState: QueryState = .idle
    @Published var categoryName: String = ""
    
    init(categoryId: String) {
        self.categoryId = categoryId
        self.categoryToken = categoryRepository.getCategory(withId: categoryId).observe({ [weak self] liveObject, error in
            guard let self else { return }
            
            if let category = liveObject.snapshot {
                self.categoryName = category.name
                
                // Invalidate token
                self.categoryToken?.invalidate()
            }
        })
    }
    
    func fetchCommunities() {
        guard queryState != .loading else { return }
        
        queryState = .loading
        
        let queryOptions = AmityCommunityQueryOptions(filter: .all, sortBy: .lastCreated, categoryId: categoryId, includeDeleted: false)
        communityCollection = repository.getCommunities(with: queryOptions)
        token = communityCollection?.observe { [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let _ = error {
                self.queryState = .error
                return
            }
            
            let items = liveCollection.snapshots.map {
                AmityCommunityModel(object: $0)
            }
            self.communities = items
            
            self.queryState = .loaded
        }
    }
    
    func isLastCommunity(community: AmityCommunityModel) -> Bool {
        if let lastCommunity = communities.last, lastCommunity.communityId == community.communityId {
            return true
        }
        return false
    }
    
    func loadMore() {
        if let communityCollection, communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
}
