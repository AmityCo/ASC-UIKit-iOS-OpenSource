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
    var showJoinButton = true
    
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
            
            CommunityInfoView(community: community, showJoinButton: showJoinButton)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
    }
}

struct CommunityInfoView: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel = CommunityInfoViewModel()
    
    let community: AmityCommunityModel
    var showJoinButton: Bool = true
    
    @State private var showLeaveCommunityAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                if !community.isPublic {
                    Image(AmityIcon.lockBlackIcon.imageResource)
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
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
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 4)
                    .opacity(community.isOfficial ? 1 : 0)
            }
            
            HStack(alignment: .bottom, spacing: 0) {
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
                
                if showJoinButton {
                    CommunityJoinButton(community: community, tapAction: {
                        let communityId = community.communityId
                        let isJoined = community.isJoined
                        let requiresJoinApproval = community.requiresJoinApproval
                        
                        Task { @MainActor in
                            if isJoined {
                                if requiresJoinApproval {
                                    showLeaveCommunityAlert.toggle()
                                } else {
                                    let isSuccess = try await viewModel.leaveCommunity(communityId: communityId)
                                    Log.add(event: .info, "Leaving Community Status: \(isSuccess)")
                                }
                            } else {
                                let joinStatus = community.joinRequestStatus
                                
                                if joinStatus == .pending {
                                    do {
                                        try await community.joinRequest?.cancel()
                                        Log.add(event: .success, "Join request cancelled for community \(community.displayName)")
                                    } catch let error {
                                        Log.warn("Error while cancelling join request \(error)")
                                        Toast.showToast(style: .success, message: "Failed to cancel your request. Please try again.")
                                    }
                                } else {
                                    do {
                                        let result = try await community.object.join()
                                        
                                        switch result {
                                        case .success:
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityJoinToastSuccessMessage.localized(arguments: community.displayName))
                                        case .pending(_):
                                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityJoinToastRequestSuccessMessage.localizedString)
                                        default:
                                            break
                                        }
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.communityJoinToastErrorMessage.localizedString)
                                    }
                                }
                            }
                        }
                    })
                }
            }
            .frame(height: 48)
            .alert(isPresented: $showLeaveCommunityAlert) {
                
                Alert(title: Text(AmityLocalizedStringSet.Social.communityLeaveAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.communityLeaveAlertPendingRequestMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.leave.localizedString), action: {
                    
                    Task { @MainActor in
                        let isSuccess = try await viewModel.leaveCommunity(communityId: community.communityId)
                        Log.add(event: .info, "Leaving Community Status: \(isSuccess)")
                    }
                }))
            }
        }
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
        self._isJoined = State(initialValue: community.isJoined)
    }
    
    var body: some View {
        if community.isJoined {
            joinedButton
        } else {
            // if it requires join approval, state can be in pending
            if community.requiresJoinApproval, let status = community.joinRequestStatus, status == .pending {
                pendingButton
            } else {
                joinButton
            }
        }
    }
    
    @ViewBuilder
    var pendingButton: some View {
        Button {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            
            tapAction()
        } label: {
            HStack(spacing: 4) {
                Image(AmityIcon.cancelRequestIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text("Pending")
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
            }
        }
        .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .compact, hPadding: 8, vPadding: 6, radius: 6))
        .accessibilityIdentifier(AccessibilityID.Social.Explore.communityJoinButton)
    }
    
    @ViewBuilder
    var joinButton: some View {
        Button {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            
            tapAction()
        } label: {
            HStack(spacing: 4) {
                Image(AmityIcon.plusIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(.white))
                
                Text(AmityLocalizedStringSet.Social.communityPageJoinTitle.localizedString)
                    .applyTextStyle(.captionBold(.white))
                    .padding(.trailing, 4)
            }
        }
        .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig, size: .compact, hPadding: 8, vPadding: 6, radius: 6))
        .onChange(of: community.isJoined, perform: { value in
            withAnimation {
                self.isJoined = value
            }
        })
    }
    
    @ViewBuilder
    var joinedButton: some View {
        Button {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            
            tapAction()
        } label: {
            HStack(spacing: 4) {
                Image(AmityIcon.tickIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(AmityLocalizedStringSet.Social.communityPageJoinedTitle.localizedString)
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                    .padding(.trailing, 4)
            }
        }
        .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig, size: .compact, hPadding: 8, vPadding: 6, radius: 6))
        .onChange(of: community.isJoined, perform: { value in
            withAnimation {
                self.isJoined = value
            }
        })
    }
}


class CommunityInfoViewModel: ObservableObject {
    
    let repository = AmityCommunityRepository(client: AmityUIKit4Manager.client)
    
    func leaveCommunity(communityId: String) async throws -> Bool {
        try await repository.leaveCommunity(withId: communityId)
    }
}
