//
//  AmityRecommendedCommunitiesComponent.swift
//  AmityUIKit4
//
//  Created by Nishan on 28/8/2567 BE.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityRecommendedCommunitiesComponent: AmityComponentView {
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        return .recommendedCommunities
    }
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = RecommendedCommunityViewModel()
    
    public init(pageId: PageId? = .socialHomePage) {
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .recommendedCommunities))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            if viewModel.communities.isEmpty && viewModel.queryState == .loading {
                ExploreRecommendedSkeletonView()
            }
            
            content
                .opacity(viewModel.communities.isEmpty ? 0 : 1)
        }
        .onAppear {
            viewModel.observeState()
            viewModel.fetchCommunities(limit: 4)
        }
        .onDisappear {
            viewModel.unObserveState()
        }
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AmityLocalizedStringSet.Social.exploreRecommendedComponentTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .padding(.bottom, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    LazyHStack(spacing: 0) {
                        ForEach(viewModel.communities) { community in
                            RecommendedCommunityView(community: community)
                                .onTapGesture {
                                    host.controller?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: AmityCommunityProfilePage(communityId: community.communityId)), animated: true)
                                }
                                .padding(.leading, 8)
                        }
                    }
                    .frame(height: 222)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct RecommendedCommunityView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let community: AmityCommunityModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.communityPlaceholder.imageResource, url: URL(string: community.avatarURL), contentMode: .fill)
                .frame(height: 125)
            
            CommunityInfoView(community: community)
                .padding(10)
            
            Spacer()
        }
        .frame(width: 270)
        .frame(height: 220)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
#Preview {
    AmityRecommendedCommunitiesComponent()
}
#endif
