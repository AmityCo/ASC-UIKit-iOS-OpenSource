//
//  TrendingCommunitiesComponent.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityTrendingCommunitiesComponent: AmityComponentView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    @StateObject var viewConfig: AmityViewConfigController
    @StateObject var viewModel = TrendingCommunityViewModel()
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .trendingCommunities
    }
    
    public init(pageId: PageId? = .socialHomePage) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .trendingCommunities))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            ExploreTrendingSkeletonView()
                .opacity(viewModel.communities.isEmpty && viewModel.queryState == .loading ? 1 : 0)
            
            content
                .opacity(viewModel.communities.isEmpty ? 0 : 1)
            
        }
        .onAppear(perform: {
            viewModel.observeState()
            viewModel.fetchCommunities(limit: 5)
        })
        .updateTheme(with: viewConfig)
        .onDisappear {
            viewModel.unObserveState()
        }
    }
    
    @ViewBuilder
    var content: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            Text(AmityLocalizedStringSet.Social.exploreTrendingComponentTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .padding(.bottom, 12)
            
            ForEach(Array(viewModel.communities.enumerated()), id: \.element.id) { index, community in
                VStack(spacing: 0) {
                    CommunityListItemView(community: community, shouldOverlayImage: true)
                        .onTapGesture {
                            host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: AmityCommunityProfilePage(communityId: community.communityId)), animated: true)
                        }
                        .overlay(
                            Text(viewModel.digitFormatter.string(from: NSNumber(value: index + 1)) ?? "")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .offset(x: 8, y: -8)
                                .shadow(radius: 2, x: 0, y: 0)
                            , alignment: .bottomLeading)
                }
            }
        }
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    AmityTrendingCommunitiesComponent()
}
#endif
