//
//  AmityCommunitySearchResultComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommunitySearchResultComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .communitySearchResultComponent
    }
    
    @ObservedObject private var viewModel: AmityGlobalSearchViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    
    public init(viewModel: AmityGlobalSearchViewModel, pageId: PageId?) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communitySearchResultComponent))
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            if viewModel.communities.isEmpty && viewModel.loadingState == .loaded {
                VStack(spacing: 15) {
                    Image(AmityIcon.noSearchableIcon.getImageResource())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    
                    Text("No results found")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                }
            }
            
            List(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                getCommunityCellView(community)
                .onAppear {
                    if index == viewModel.communities.count - 1 {
                        viewModel.loadMoreCommunities()
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    
    @ViewBuilder
    func getCommunityCellView(_ community: AmityCommunity) -> some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 0) {
                let model = AmityCommunityModel(object: community)
                CommunityCellView(community: model, pageId: pageId, componentId: id)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                    .padding([.leading, .trailing], 16)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden, edges: .all)
        } else {
            VStack {
                let model = AmityCommunityModel(object: community)
                CommunityCellView(community: model, pageId: pageId, componentId: id)
            }
            .listRowInsets(EdgeInsets())
        }
    }
}


