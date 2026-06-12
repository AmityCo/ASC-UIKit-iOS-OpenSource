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
    private let onMemberRemoved: (() -> Void)?

    init(showBottomSheet: Binding<Bool>, community: AmityCommunity, communityMember: AmityCommunityMember, onMemberRemoved: (() -> Void)? = nil) {
        self._showBottomSheet = showBottomSheet
        self._viewModel = StateObject(wrappedValue: CommunityMembershipBottomSheetViewModel(community, communityMember))
        self.onMemberRemoved = onMemberRemoved
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.shouldShowModeratorItems {
                getItemView(viewModel.isModerator ? AmityIcon.communityMemberIcon.getImageResource() : AmityIcon.communityModeratorIcon.getImageResource(), text: viewModel.isModerator ? AmityLocalizedStringSet.Social.communityMemberDemoteToMember.localizedString : AmityLocalizedStringSet.Social.communityMemberPromoteToModerator.localizedString)
                    .onTapGesture {
                        Task { @MainActor in
                            showBottomSheet.toggle()
                            if viewModel.isModerator {
                                do {
                                    let _ = try await viewModel.demoteToMember()
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberDemoteSuccessToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.communityMemberDemoteFailedToast.localizedString)
                                }
                                
                            } else {
                                do {
                                    let _ = try await viewModel.promoteToModerator()
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberPromoteSuccessToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberPromoteFailedToast.localizedString)
                                }
                            }
                        }
                    }
            }
            
            getItemView(viewModel.isReportedByMe ? AmityIcon.unflagIcon.getImageResource() : AmityIcon.flagIcon.getImageResource(), text: viewModel.isReportedByMe ? AmityLocalizedStringSet.Social.unreportUser.localizedString : AmityLocalizedStringSet.Social.reportUser.localizedString)
                .onTapGesture {
                    
                    AmityUserAction.perform {
                        showBottomSheet.toggle()
                        
                        Task { @MainActor in
                            if viewModel.isReportedByMe {
                                do {
                                    let _ = try await viewModel.unReportUser()
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberUnreportedToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.communityMemberUnreportFailedToast.localizedString)
                                }
                                
                            } else {
                                do {
                                    let _ = try await viewModel.reportUser()
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberReportedToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberReportFailedToast.localizedString)
                                }
                            }
                        }
                    }
                }
            
            
            if viewModel.shouldShowModeratorItems {
                getItemView(AmityIcon.trashBinIcon.getImageResource(), text: AmityLocalizedStringSet.Social.communityRemoveMember.localizedString, isDestructive: true)
                    .onTapGesture {
                        Task { @MainActor in
                            showBottomSheet.toggle()
                            do {
                                try await viewModel.removeMember()
                                onMemberRemoved?()
                            } catch {
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberRemoveFailedToast.localizedString)
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
                .applyTextStyle(.bodyBold(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor)))
                
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
       Task { @MainActor in
           await hasEditCommunityPermisison()
           setupData()
           self.isReportedByMe = try await isReportedByMe()
       }
    }
    
    private func setupData() {
        let isModerator = community.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId)?.hasModeratorRole ?? false
        self.shouldShowModeratorItems = hasEditCommunityPermisison || isModerator
    }
    
    func promoteToModerator() async throws {
        try await community.moderate.addRoles([AmityCommunityRole.communityModerator.rawValue], userIds: [communityMember.userId])
    }
    
    func demoteToMember() async throws {
        try await community.moderate.removeRoles([AmityCommunityRole.communityModerator.rawValue], userIds: [communityMember.userId])
    }
    
    func reportUser() async throws {
        try await userManager.flagUser(withId: communityMember.userId)
    }
    
    func unReportUser() async throws {
        try await userManager.unflagUser(withId: communityMember.userId)
    }
    
    @discardableResult
    func isReportedByMe() async throws -> Bool {
        try await userManager.isUserFlaggedByMe(withId: communityMember.userId)
    }
    
    func removeMember() async throws {
        try await community.membership.removeMembers([communityMember.userId])
    }
    
    private func hasEditCommunityPermisison() async {
        self.hasEditCommunityPermisison = await AmityUIKitManagerInternal.shared.client.hasPermission(.editCommunity, forCommunity: community.communityId)
    }
}
