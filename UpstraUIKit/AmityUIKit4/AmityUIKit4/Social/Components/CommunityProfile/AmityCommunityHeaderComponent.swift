//
//  AmityCommunityHeaderComponent.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 12/7/2567 BE.
//

import SwiftUI

public struct AmityCommunityHeaderComponent: AmityComponentView {
    
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    private let community: AmityCommunityModel
    
    public var pageId: PageId?
    public var id: ComponentId {
        return .communityHeader
    }
    private var onPendingPostsTapAction: (() -> Void)?
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel: CommunityProfileViewModel
    
    public init(community: AmityCommunityModel, pageId: PageId? = nil, onPendingPostsTapAction: (() -> Void)? = nil) {
        self.community = community
        self.pageId = pageId
        self.onPendingPostsTapAction = onPendingPostsTapAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityHeader))
        self._viewModel = StateObject(wrappedValue: CommunityProfileViewModel(communityId: community.communityId))
        
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.communityProfilePlaceholder.imageResource, url: URL(string: community.largeAvatarURL) , contentMode: .fill)
                    .frame(height: 188)
                
            HStack(alignment: .top, spacing: 0) {
                if !community.isPublic {
                    let lockIcon = AmityIcon.lockBlackIcon.imageResource
                    Image(lockIcon)
                        .frame(width: 20, height: 20)
                        .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                }
                
                Text(community.displayName)
                    .padding(.bottom, 10)
                    .lineLimit(2)
                    .font(.system(size: 18, weight: .semibold))
                
                if community.isOfficial {
                    let verifiedBadgeIcon = AmityIcon.verifiedBadge.imageResource
                    Image(verifiedBadgeIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 4)
                        .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                }
                
            }
            .padding([.horizontal, .top], 16)
            
            getCategoryView(community.categories)
                .isHidden(community.categories.isEmpty)
            
            Text(community.description)
                .font(.system(size: 15))
                .isHidden(community.description.isEmpty)
                .padding(.all, 16)
            
            HStack(spacing: 0) {
                Text(community.postsCount.formattedCountString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                Text(community.postsCount == 1 ? "post" : "posts")
                    .padding(.leading, 4)
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                
                Rectangle().frame(width: 1, height: 20)
                    .foregroundColor(Color(UIColor(hex: "#E5E5E5", alpha: 1)))
                    .padding(.horizontal, 16)
                
                Text(community.membersCount.formattedCountString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                Text(community.postsCount == 1 ? "member" : "members")
                    .padding(.leading, 4)
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                Spacer()
            }
            .padding([.horizontal, .bottom], 16)
            
            Button(action: {
                Task { @MainActor in
                    try await viewModel.joinCommunity()
                }
            }, label: {
                HStack(spacing: 8) {
                    Image(AmityIcon.plusIcon.imageResource)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                    Text("Join")
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            })
            .background(Color(viewConfig.theme.primaryColor))
            .cornerRadius(8)
            .padding(.all, 16)
            .isHidden(community.isJoined)
            
            AmityStoryTabComponent(type: .communityFeed(community.communityId))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
            VStack(alignment: .center) {
                HStack(alignment: .center,spacing: 7) {
                    Image(AmityIcon.communityPendingPostIcon.imageResource)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 6, height: 6)
                        .foregroundColor(Color(viewConfig.theme.primaryColor))
                    Text("Pending Post")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }
                .padding(.top, 12)
                
                Text("\(viewModel.getPendingPostCount()) posts need approval")
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Color(viewConfig.theme.baseColorShade4))
            .cornerRadius(4)
            .padding([.horizontal, .bottom], 16)
            .isHidden(!(viewModel.hasModeratorRole() && viewModel.getPendingPostCount() != 0))
            .onTapGesture {
                onPendingPostsTapAction?()
            }
            
            
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        
    }
    
    
    @ViewBuilder
    private func getCategoryView(_ categories: [String]) -> some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                    
                    Text(category)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                        .background(
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .clipShape(RoundedCorner())
                                .padding(EdgeInsets(top: -3, leading: -8, bottom: -3, trailing: -8))
                            
                        )
                        .padding([.leading, .trailing], 5)
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
}

