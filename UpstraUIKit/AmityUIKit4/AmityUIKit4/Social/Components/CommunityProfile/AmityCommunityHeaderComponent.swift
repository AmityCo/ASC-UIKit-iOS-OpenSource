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
    private var onMemberListTapAction: (() -> Void)?
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel: CommunityProfileViewModel
    
    public init(community: AmityCommunityModel, pageId: PageId? = nil, viewModel: CommunityProfileViewModel? = nil, onPendingPostsTapAction: (() -> Void)? = nil, onMemberListTapAction: (() -> Void)? = nil) {
        self.community = community
        self.pageId = pageId
        self.onPendingPostsTapAction = onPendingPostsTapAction
        self.onMemberListTapAction = onMemberListTapAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .communityHeader))
        if let viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: CommunityProfileViewModel(communityId: community.communityId))
        }
        
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.communityProfilePlaceholder.imageResource, url: URL(string: community.largeAvatarURL) , contentMode: .fill)
                .frame(height: 188)
                .isHidden(viewConfig.isHidden(elementId: .communityCover))
            
            HStack(alignment: .top, spacing: 3) {
                if !community.isPublic {
                    let lockIcon = AmityIcon.lockBlackIcon.imageResource
                    Image(lockIcon)
                        .renderingMode(.template)
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                }
                
                Text(community.displayName)
                    .padding(.bottom, 10)
                    .lineLimit(2)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .isHidden(viewConfig.isHidden(elementId: .communityName))
                
                if community.isOfficial {
                    let verifiedBadgeIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityVerifyBadge, key: "image", of: String.self) ?? "")

                    Image(verifiedBadgeIcon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 4)
                        .isHidden(viewConfig.isHidden(elementId: .communityVerifyBadge))
                }
                
            }
            .padding([.horizontal, .top], 16)
            
            getCategoryView(community.categories)
                .isHidden(community.categories.isEmpty || viewConfig.isHidden(elementId: .communityCategory))
            
            Text(community.description)
                .font(.system(size: 15))
                .lineLimit(4)
                .isHidden(community.description.isEmpty || viewConfig.isHidden(elementId: .communityDescription))
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
                
                HStack(spacing: 0) {
                    Text(community.membersCount.formattedCountString)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                    
                    Text(community.membersCount == 1 ? "member" : "members")
                        .padding(.leading, 4)
                        .font(.system(size: 13))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))

                }                        
                .onTapGesture {
                    onMemberListTapAction?()
                }
                
                Spacer()
            }
            .padding([.horizontal, .bottom], 16)
            .isHidden(viewConfig.isHidden(elementId: .communityInfo))
            
            Button(action: {
                Task { @MainActor in
                    try await viewModel.joinCommunity()
                }
            }, label: {
                HStack(spacing: 8) {
                    let plusIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityJoinButton, key: "image", of: String.self) ?? "")

                    Image(plusIcon)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                    Text(AmityLocalizedStringSet.Social.communityPageJoinTitle.localizedString)
                        .foregroundColor(Color(viewConfig.theme.backgroundColor))
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            })
            .background(Color(viewConfig.theme.primaryColor))
            .cornerRadius(8)
            .padding(.all, 16)
            .isHidden(community.isJoined || viewConfig.isHidden(elementId: .communityJoinButton))
            
            AmityStoryTabComponent(type: .communityFeed(community.communityId))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .isHidden(!(!viewModel.stories.isEmpty || viewModel.hasStoryManagePermission))
            
            VStack(alignment: .center) {
                let pendingPostCountString = viewModel.pendingPostCount == 1 ? "" : "s"
                HStack(alignment: .center,spacing: 7) {
                    Image(AmityIcon.communityPendingPostIcon.imageResource)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 6, height: 6)
                        .foregroundColor(Color(viewConfig.theme.primaryColor))
                    Text(AmityLocalizedStringSet.Social.communityPagePendingPostTitle.localizedString + pendingPostCountString)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                }
                .padding(.top, 12)
                
                Text(community.hasModeratorRole ? "\(viewModel.pendingPostCount) post\(pendingPostCountString) need approval" : "Your posts are pending for review")
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Color(viewConfig.theme.baseColorShade4))
            .cornerRadius(4)
            .padding([.horizontal, .bottom], 16)
            .isHidden(!viewModel.shouldShowPendingBanner || !community.isPostReviewEnabled || viewConfig.isHidden(elementId: .communityPendingPost))
            .onTapGesture {
                onPendingPostsTapAction?()
            }
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .background(GeometryReader {
            Color.clear.preference(key: ViewHeightKey.self, value: $0.frame(in: .global).size.height)
        })
        .onPreferenceChange(ViewHeightKey.self) { height in
            viewModel.updateHeaderHeight(height: height)
        }
        
    }
    
    
    @ViewBuilder
    private func getCategoryView(_ categories: [String]) -> some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                    
                    HStack {
                        Text(category)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(Color(viewConfig.theme.baseColorShade4))
                    .clipShape(RoundedCorner())
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
}

