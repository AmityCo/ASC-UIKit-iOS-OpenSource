//
//  AmityMyCommunitiesComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/8/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityMyCommunitiesComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .myCommunitiesComponent
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = AmityMyCommunitiesComponentViewModel()
    
    public init(pageId: PageId? = nil) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .myCommunitiesComponent))
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.loadingStatus == .loading && viewModel.communities.isEmpty {
                    ForEach(0..<8, id: \.self) { _ in
                        VStack {
                            CommunityCellSkeletonView()
                            
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(height: 1)
                                .padding([.leading, .trailing], 16)
                        }
                    }
                } else {
                    ForEach(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                        VStack {
                            let model = AmityCommunityModel(object: community)
                            CommunityCellView(community: model, pageId: pageId, componentId: id)
                           
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(height: 1)
                                .padding([.leading, .trailing], 16)
                        }
                        .onTapGesture {
                            let context = AmityMyCommunitiesComponentBehavior.Context(component: self, communityId: community.communityId)
                            AmityUIKitManagerInternal.shared.behavior.myCommunitiesComponentBehavior?.goToCommunityProfilePage(context: context)
                        }
                        .onAppear {
                            if index == viewModel.communities.count - 1 {
                                viewModel.loadMore()
                            }
                        }
                        
                    }
                }
            }
            .background(Color(viewConfig.theme.backgroundColor))
        }
        .updateTheme(with: viewConfig)
    }
    
}

class AmityMyCommunitiesComponentViewModel: ObservableObject {
    @Published var communities: [AmityCommunity] = []
    @Published var loadingStatus: AmityLoadingStatus = .loading
    private let communityManager = CommunityManager()
    private let communityCollection: AmityCollection<AmityCommunity>
    private var cancellable: AnyCancellable?
    private var loadingCancellable: AnyCancellable?
    
    init() {
        communityCollection = communityManager.searchCommunitites(keyword: "", filter: .userIsMember)
        loadingCancellable = communityCollection.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
        
        cancellable = communityCollection.$snapshots
            .sink { [weak self] communities in
                self?.communities = communities
            }
    }
    
    
    func loadMore() {
        if communityCollection.hasNext {
            communityCollection.nextPage()
        }
    }
}
