//
//  CommunityListItemView.swift
//  AmityUIKit4
//
//  Created by Nishan on 9/9/2567 BE.
//

import SwiftUI
import AmitySDK

struct CommunityListItemView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var community: AmityCommunityModel
    var shouldOverlayImage: Bool = false
    
    var body: some View {
        HStack {
            AsyncImage(placeholder: AmityIcon.communityThumbnail.imageResource, url: URL(string: community.avatarURL), contentMode: .fill)
                .accessibilityLabel(AccessibilityID.Social.Explore.communityImage)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8, corners: .allCorners)
                .overlay(
                    LinearGradient(colors: [Color.black.opacity(0.4), Color.black.opacity(0)], startPoint: .bottom, endPoint: .top)
                        .cornerRadius(8, corners: .allCorners).opacity(shouldOverlayImage ? 1 : 0)
                    , alignment: .center)
            
            CommunityInfoView(community: community)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
    }
}

struct CommunityJoinButton: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let community: AmityCommunityModel
    let tapAction: DefaultTapAction
    
    @State private var isJoined = false
    
    init(community: AmityCommunityModel, tapAction: @escaping DefaultTapAction) {
        self.community = community
        self.tapAction = tapAction
    }
    
    var body: some View {
        Button {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            
            tapAction()
        } label: {
            HStack(spacing: 0) {
                Image(isJoined ? AmityIcon.tickIcon.imageResource : AmityIcon.plusIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(isJoined ? viewConfig.theme.baseColor : .white))
                
                Text(isJoined ? AmityLocalizedStringSet.Social.communityPageJoinedTitle.localizedString : AmityLocalizedStringSet.Social.communityPageJoinTitle.localizedString)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(isJoined ? viewConfig.theme.baseColor : .white))
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(Color(isJoined ? viewConfig.theme.backgroundColor : viewConfig.theme.primaryColor))
        .cornerRadius(4, corners: .allCorners)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color(isJoined ? viewConfig.theme.baseColorShade4 : viewConfig.theme.primaryColor), lineWidth: 1)
        )
        .onChange(of: community.isJoined, perform: { value in
            withAnimation {
                self.isJoined = value
            }
        })
        .accessibilityIdentifier(AccessibilityID.Social.Explore.communityJoinButton)
    }
}

struct CommunityInfoView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel = CommunityInfoViewModel()
    
    let community: AmityCommunityModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                if !community.isPublic {
                    Image(AmityIcon.lockBlackIcon.imageResource)
                        .renderingMode(.template)
                        .frame(width: 20, height: 12)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                        .padding(.trailing, 4)
                }
                
                Text(community.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .lineLimit(1)
                
                Image(AmityIcon.verifiedBadge.imageResource)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 4)
                    .opacity(community.isOfficial ? 1 : 0)
            }
            
            HStack(alignment: community.categories.isEmpty ? .bottom : .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    if !community.categories.isEmpty {
                        CategoryListView(community: community)
                            .padding(.bottom, 5)
                    }
                    
                    let memberCountInfo = community.membersCount > 1 ? AmityLocalizedStringSet.Social.communityMemberCountPlural.localized(arguments: "\(community.membersCount.formattedCountString)") : AmityLocalizedStringSet.Social.communityMemberCountSingular.localized(arguments: "\(community.membersCount.formattedCountString)")
                    Text(memberCountInfo)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .accessibilityLabel(AccessibilityID.Social.Explore.communityMemberCount)
                    
                   Spacer()
                }
                
                Spacer()
                
                CommunityJoinButton(community: community, tapAction: {
                    let communityId = community.communityId
                    let isJoined = community.isJoined
                    Task { @MainActor in
                        if isJoined {
                            let isSuccess = try await viewModel.leaveCommunity(communityId: communityId)
                            Log.add(event: .info, "Leaving Community Status: \(isSuccess)")
                        } else {
                            let isSuccess = try await viewModel.joinCommunity(communityId: communityId)
                            Log.add(event: .info, "Joining Community Status: \(isSuccess)")
                        }
                    }
                })
            }
            .frame(height: 48)
        }
    }
}

class CommunityInfoViewModel: ObservableObject {
    
    let repository = AmityCommunityRepository(client: AmityUIKit4Manager.client)
    
    func joinCommunity(communityId: String) async throws -> Bool {
        try await repository.joinCommunity(withId: communityId)
    }
    
    func leaveCommunity(communityId: String) async throws -> Bool {
        try await repository.leaveCommunity(withId: communityId)
    }
}
