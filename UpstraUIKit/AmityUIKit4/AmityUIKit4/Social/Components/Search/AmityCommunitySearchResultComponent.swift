//
//  AmityCommunitySearchResultComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommunitySearchResultComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .communitySearchResultComponent
    }
    
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(viewModel: AmityGlobalSearchViewModel, pageId: PageId? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communitySearchResultComponent))
        self.viewModel = viewModel
        
        UITableView.appearance().separatorStyle = .none
    }
    
    public var body: some View {
        ZStack {
            if viewModel.communities.isEmpty && viewModel.loadingState == .loaded {
                VStack(spacing: 15) {
                    Image(AmityIcon.noSearchableIcon.getImageResource())
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                        .frame(width: 60, height: 60)
                    
                    Text("No results found")
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                }
            }
            
            if viewModel.loadingState == .loading && viewModel.communities.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { index in
                            CommunityCellSkeletonView()
                                .padding(.top, index == 0 ? 8 : 0)
                        }
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                            let model = AmityCommunityModel(object: community)
                            CommunityCellView(community: model, pageId: pageId, componentId: id)
                                .padding(.top, index == 0 ? 8 : 0)
                                .onTapGesture {
                                    let context = AmityCommunitySearchResultComponentBehavior.Context(component: self, communityId: community.communityId)
                                    AmityUIKitManagerInternal.shared.behavior.communitySearchResultComponentBehavior?.goToCommunityProfilePage(context: context)
                                }
                                .onAppear {
                                    if index == viewModel.communities.count - 1 {
                                        viewModel.loadMoreCommunities()
                                    }
                                }
                        }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
}


