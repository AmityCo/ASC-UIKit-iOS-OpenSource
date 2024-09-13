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
            AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: URL(string: model.avatarURL))
                .frame(size: CGSize(width: 64, height: 64))
                .clipShape(Circle())
                .isHidden(viewConfig.isHidden(elementId: .communityAvatar))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 2) {
                    if !model.isPublic {
                        let lockIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityPrivateBadge, key: "icon", of: String.self) ?? "")
                        Image(lockIcon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 12)
                            .offset(y: -1)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                    }
                    
                    Text(model.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .isHidden(viewConfig.isHidden(elementId: .communityDisplayName))
                    
                    if model.isOfficial {
                        let verifiedBadgeIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .communityOfficialBadge, key: "icon", of: String.self) ?? "")
                        Image(verifiedBadgeIcon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 12)
                            .offset(x: 5,y: -1)
                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                    }
                }
                
                if !model.categories.isEmpty {
                    getCategoryView(model.categories)
                        .isHidden(viewConfig.isHidden(elementId: .communityCategoryName))
                }
                
                Text("\(model.membersCount.formattedCountString) members")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .isHidden(viewConfig.isHidden(elementId: .communityMembersCount))
            }
            
            Spacer()
        }
        .padding(.all, 16)
        .background(Color(viewConfig.theme.backgroundColor))
    }
    
    
    @ViewBuilder
    private func getCategoryView(_ categories: [String]) -> some View {
        HStack {
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                if index <= 3 {
                    let name = index < 3 ? category : "+\(categories.count - 3)"
                    Text(name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                        .background(
                            Rectangle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .clipShape(RoundedCorner())
                                .padding(EdgeInsets(top: -3, leading: -7, bottom: -3, trailing: -7))
                            
                        )
                        .padding([.leading, .trailing], 5)
                }
            }
        }
    }
}
