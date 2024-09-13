//
//  CommunityMembershipBottomSheetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/22/24.
//

import SwiftUI
import AmitySDK

struct CommunityMembershipBottomSheetView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @Binding private var showBottomSheet: Bool
    @StateObject private var viewModel: CommunityMembershipBottomSheetViewModel
    
    init(showBottomSheet: Binding<Bool>, community: AmityCommunity, communityMember: AmityCommunityMember) {
        self._showBottomSheet = showBottomSheet
        self._viewModel = StateObject(wrappedValue: CommunityMembershipBottomSheetViewModel(community, communityMember))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.shouldShowModeratorItems {
                getItemView(viewModel.isModerator ? AmityIcon.communityMemberIcon.getImageResource() : AmityIcon.communityModeratorIcon.getImageResource(), text: viewModel.isModerator ? "Demote to member" : "Promote to moderator")
                    .onTapGesture {
                        Task { @MainActor in
                            showBottomSheet.toggle()
                            if viewModel.isModerator {
                                do {
                                    let _ = try await viewModel.demoteToMember()
                                    Toast.showToast(style: .success, message: "Successfully demoted to member!")
                                } catch {
                                    Toast.showToast(style: .warning, message: "Failed to demote member. Please try again.")
                                }
                                
                            } else {
                                do {
                                    let _ = try await viewModel.promoteToModerator()
                                    Toast.showToast(style: .success, message: "Successfully promoted to moderator!")
                                } catch {
                                    Toast.showToast(style: .success, message: "Failed to promote member. Please try again.")
                                }
                            }
                        }
                    }
            }
            
            
            getItemView(viewModel.isReportedByMe ? AmityIcon.unflagIcon.getImageResource() : AmityIcon.flagIcon.getImageResource(), text: viewModel.isReportedByMe ? "Unreport user" : "Report user")
                .onTapGesture {
                    Task { @MainActor in
                        showBottomSheet.toggle()
                        if viewModel.isReportedByMe {
                            do {
                                let _ = try await viewModel.unReportUser()
                                Toast.showToast(style: .success, message: "Member unreported.")
                            } catch {
                                Toast.showToast(style: .warning, message: "Failed to unreport member. Please try again.")
                            }
                            
                        } else {
                            do {
                                let _ = try await viewModel.reportUser()
                                Toast.showToast(style: .success, message: "Member reported.")
                            } catch {
                                Toast.showToast(style: .success, message: "Failed to report member. Please try again.")
                            }
                        }
                    }
                }
            
            
            if viewModel.shouldShowModeratorItems {
                getItemView(AmityIcon.trashBinIcon.getImageResource(), text: "Remove from community", isDestructive: true)
                    .onTapGesture {
                        Task { @MainActor in
                            showBottomSheet.toggle()
                            do {
                                try await viewModel.removeMember()
                                Toast.showToast(style: .success, message: "Member removed from this community.")
                            } catch {
                                Toast.showToast(style: .success, message: "Failed to remove member. Please try again.")
                            }
                        }
                    }
            }
        }
        .padding(.bottom, 32)
        .onAppear {
            /// check permission and setup data after the view appeared to avoid the case of child view animation issue when the bottom sheet pop up.
            viewModel.checkPermisisonAndSetupData()
        }
    }
    
    private func getItemView(_ icon: ImageResource, text: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 24)
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}


class CommunityMembershipBottomSheetViewModel: ObservableObject {
    @Published var isReportedByMe: Bool = false
    @Published var shouldShowModeratorItems: Bool = true
    let isModerator: Bool
    
    private let community: AmityCommunity
    private let communityMember: AmityCommunityMember
    private let userManager = UserManager()
    private var hasEditCommunityPermisison: Bool = false
    
    
    init(_ community: AmityCommunity, _ communityMember: AmityCommunityMember) {
        self.community = community
        self.communityMember = communityMember
        self.isModerator = communityMember.hasModeratorRole
    }
    
   func checkPermisisonAndSetupData() {
        hasEditCommunityPermisison { [weak self] in
            self?.setupData()
        }
        
        Task { @MainActor in
            self.isReportedByMe = try await isReportedByMe()
        }
    }
    
    private func setupData() {
        let isModerator = community.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
        self.shouldShowModeratorItems = hasEditCommunityPermisison || isModerator
    }
    
    @discardableResult
    func promoteToModerator() async throws -> Bool {
        try await community.moderate.addRoles([AmityCommunityRole.communityModerator.rawValue], userIds: [communityMember.userId])
    }
    
    @discardableResult
    func demoteToMember() async throws -> Bool {
        try await community.moderate.removeRoles([AmityCommunityRole.communityModerator.rawValue], userIds: [communityMember.userId])
    }
    
    @discardableResult
    func reportUser() async throws -> Bool {
        try await userManager.flagUser(withId: communityMember.userId)
    }
    
    @discardableResult
    func unReportUser() async throws -> Bool {
        try await userManager.unflagUser(withId: communityMember.userId)
    }
    
    @discardableResult
    func isReportedByMe() async throws -> Bool {
        try await userManager.isUserFlaggedByMe(withId: communityMember.userId)
    }
    
    @discardableResult
    func removeMember() async throws -> Bool {
        try await community.membership.removeMembers([communityMember.userId])
    }
    
    private func hasEditCommunityPermisison(_ completion: (() -> Void)?) {
        AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: community.communityId) { [weak self] status in
            self?.hasEditCommunityPermisison = status
            completion?()
        }
    }
}
