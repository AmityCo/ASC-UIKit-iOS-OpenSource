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
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(size: CGSize(width: 80, height: 80))
                        .clipped()
                        .overlay(
                            Image(AmityIcon.plusIcon.imageResource)
                        )
                    
                    Text("Create community")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(viewConfig.theme.backgroundColor))
                .onTapGesture {
                    AmityUIKitManagerInternal.shared.behavior.myCommunitiesComponentBehavior?.goToCommunitySetupPage(context: .init(component: self))
                }
                
                if viewModel.loadingStatus == .loading && viewModel.communities.isEmpty {
                    ForEach(0..<8, id: \.self) { _ in
                        CommunityCellSkeletonView()
                    }
                } else {
                    ForEach(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                        VStack {
                            let model = AmityCommunityModel(object: community)
                            CommunityCellView(community: model, pageId: pageId, componentId: id)
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
        .onAppear{
            viewModel.loadCommunities()
        }
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
        communityCollection = communityManager.getCommunities(filter: .userIsMember)
    }
    
    func loadCommunities() {
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
