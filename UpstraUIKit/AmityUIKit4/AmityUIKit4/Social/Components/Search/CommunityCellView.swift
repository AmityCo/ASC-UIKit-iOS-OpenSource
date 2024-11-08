//
//  CommunityCellView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/21/24.
//

import SwiftUI

struct CommunityCellView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let community: AmityCommunityModel
    private let pageId: PageId?
    private let componentId: ComponentId?
    
    init(community: AmityCommunityModel, pageId: PageId? = nil, componentId: ComponentId? = nil) {
        self.community = community
        self.pageId = pageId
        self.componentId = componentId
    }
    
    var body: some View {
        getCommunityView(community)
    }
    
    @ViewBuilder
    private func getCommunityView(_ model: AmityCommunityModel) -> some View {
        
        HStack(spacing: 16) {
            AsyncImage(placeholder: AmityIcon.communityThumbnail.imageResource, url: URL(string: model.avatarURL))
                .frame(size: CGSize(width: 80, height: 80))
                .clipped()
                .cornerRadius(8, corners: .allCorners)
                .isHidden(viewConfig.isHidden(elementId: .communityAvatar))
                .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityAvatar)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 2) {
                    if !model.isPublic {
                        let lockIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityPrivateBadge, key: "icon", of: String.self) ?? "")
                        Image(lockIcon)
                            .renderingMode(.template)
                            .frame(width: 20, height: 20)
                            .offset(y: -1)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                            .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityPrivateBadge)
                    }
                    
                    Text(model.displayName)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                        .isHidden(viewConfig.isHidden(elementId: .communityDisplayName))
                        .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityDisplayName)
                    
                    if model.isOfficial {
                        let verifiedBadgeIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityOfficialBadge, key: "icon", of: String.self) ?? "")
                        Image(verifiedBadgeIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 12)
                            .offset(x: 5,y: -1)
                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                            .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityOfficialBadge)
                    }
                }
                
                if !model.categories.isEmpty {
                    CategoryListView(community: model)
                        .isHidden(viewConfig.isHidden(elementId: .communityCategoryName))
                        .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityCategoryName)
                }
                
                Text("\(model.membersCount.formattedCountString) members")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .lineLimit(1)
                    .isHidden(viewConfig.isHidden(elementId: .communityMembersCount))
                    .accessibilityIdentifier(AccessibilityID.Social.MyCommunities.communityMembersCount)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
