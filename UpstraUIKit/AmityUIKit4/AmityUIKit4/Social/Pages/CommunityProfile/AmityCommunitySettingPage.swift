//
//  AmityCommunitySettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/15/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommunitySettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunitySettingPageViewModel
    
    public var id: PageId {
        .communitySettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communitySettingPage))
        self._viewModel = StateObject(wrappedValue:  AmityCommunitySettingPageViewModel(community: community))
    }
    
    public var body: some View {
        VStack(spacing: 22) {
            navigationBarView
                .padding([.top, .bottom], 16)
            
            Text(AmityLocalizedStringSet.Social.communitySettingBasicInfoTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            /// Edit Profile setting
            if viewModel.shouldShowEditProfile {
                let editProfileText = viewConfig.getText(elementId: .editProfile) ?? AmityLocalizedStringSet.Social.communitySettingEditProfile.localizedString
                getItemView(AmityIcon.penIcon.getImageResource(), editProfileText)
                    .onTapGesture {
                        AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToEditCommunityPage(getPageBehaviorContext())
                    }
                    .isHidden(viewConfig.isHidden(elementId: .editProfile))
                    .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.editProfile)
            }
            
            let communityMembersText = viewConfig.getText(elementId: .members) ?? AmityLocalizedStringSet.Social.communitySettingMembers.localizedString
            getItemView(AmityIcon.memberIcon.getImageResource(), communityMembersText)
                .onTapGesture {
                    AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToMembershipPage(getPageBehaviorContext())
                }
                .isHidden(viewConfig.isHidden(elementId: .members))
                .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.members)
            
            /// Community member pending Invitations setting
            if viewModel.shouldShowPendingInvitations {
                getItemView(AmityIcon.pendingInvitationIcon.getImageResource(), "Pending invitations")
                    .onTapGesture {
                        AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToPendingInvitationsPage(getPageBehaviorContext())
                    }
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
                                    
            /// Community Permissions header
            if viewModel.shouldShowPostPermissions || viewModel.shouldShowStoryComments {
                Text(AmityLocalizedStringSet.Social.communitySettingCommunityPermissionsTitle.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            /// Post Permissions setting
            if viewModel.shouldShowPostPermissions {
                let postPermissionText = viewConfig.getText(elementId: .postPermission) ?? AmityLocalizedStringSet.Social.communitySettingPostPermissions.localizedString
                getItemView(AmityIcon.postPermissionIcon.getImageResource(), postPermissionText)
                    .onTapGesture {
                        AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToPostPermissionPage(getPageBehaviorContext())
                    }
                    .isHidden(viewConfig.isHidden(elementId: .postPermission))
                    .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.postPermission)
            }
            
            /// Story Comments setting
            if viewModel.shouldShowStoryComments {
                let storyCommentsText = viewConfig.getText(elementId: .storySetting) ?? AmityLocalizedStringSet.Social.communitySettingStoryComments.localizedString
                getItemView(AmityIcon.createStoryMenuIcon.getImageResource(), storyCommentsText)
                    .onTapGesture {
                        AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToStorySettingPage(getPageBehaviorContext())
                    }
                    .isHidden(viewConfig.isHidden(elementId: .storySetting))
                    .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.storySetting)
            }
            
            
            /// Notifications setting
            if viewModel.shouldShowNotifications {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                
                Text(AmityLocalizedStringSet.Social.communitySettingNotificationsTitle.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let notificationText = viewConfig.getText(elementId: .notifications) ?? AmityLocalizedStringSet.Social.communitySettingNotifications.localizedString
                getItemView(AmityIcon.notificationIcon.getImageResource(), notificationText, disclosureText: viewModel.isNotificationEnabled ? AmityLocalizedStringSet.General.on.localizedString : AmityLocalizedStringSet.General.off.localizedString)
                    .onTapGesture {
                        AmityUIKitManagerInternal.shared.behavior.communitySettingPageBehavior?.goToNotificationPage(getPageBehaviorContext())
                    }
                    .onAppear {
                        /// Check notification setting to update the on/off status on view appeared...
                        viewModel.isSocialNetworkEnabled(nil)
                    }
                    .isHidden(viewConfig.isHidden(elementId: .notifications))
                    .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.notifications)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            
            if viewModel.community.isJoined {
                let leaveCommunityText = viewConfig.getText(elementId: .leaveCommunity) ?? AmityLocalizedStringSet.Social.communitySettingLeaveCommunity.localizedString
                Text(leaveCommunityText)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.alertColor)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.community.membersCount == 1 {
                            let alertController = UIAlertController(title: AmityLocalizedStringSet.Social.communitySettingLeaveCommunityAlertTitle.localizedString, message: "As you’re the last moderator and member, leaving will also close this community. All posts shared in community will be deleted. This cannot be undone.", preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
                            
                            let confirmAction = UIAlertAction(title: AmityLocalizedStringSet.General.leave.localizedString, style: .destructive) { _ in
                                closeCommunity()
                            }
                            alertController.addAction(cancelAction)
                            alertController.addAction(confirmAction)
                            
                            host.controller?.present(alertController, animated: true)
                            
                        } else {
                            let alertTitle = AmityLocalizedStringSet.Social.communitySettingLeaveCommunityAlertTitle.localizedString
                            var alertMessage = AmityLocalizedStringSet.Social.communitySettingLeaveCommunityAlertMessage.localizedString
                            
                            if viewModel.community.requiresJoinApproval {
                                alertMessage = AmityLocalizedStringSet.Social.communityLeaveAlertPendingRequestMessage.localizedString
                            }
                            
                            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
                            let confirmAction = UIAlertAction(title: AmityLocalizedStringSet.General.leave.localizedString, style: .destructive) { _ in
                                leaveCommunity()
                            }
                            alertController.addAction(cancelAction)
                            alertController.addAction(confirmAction)
                            
                            host.controller?.present(alertController, animated: true)
                        }
                    }
                    .padding(.bottom, 8)
                    .isHidden(viewConfig.isHidden(elementId: .leaveCommunity))
                    .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.leaveCommunity)
            }
            
            /// Close Community setting
            if viewModel.shouldShowCloseCommunity {
                VStack(spacing: 8) {
                    let closeCommunityText = viewConfig.getText(elementId: .closeCommunity) ?? AmityLocalizedStringSet.Social.communitySettingCloseCommunity.localizedString
                    Text(closeCommunityText)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.alertColor)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let closeCommunityDesc = viewConfig.getText(elementId: .closeCommunityDescription) ?? AmityLocalizedStringSet.Social.communitySettingCloseCommunityDescription.localizedString
                    Text(closeCommunityDesc)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let alertController = UIAlertController(title: AmityLocalizedStringSet.Social.communitySettingCloseCommunityAlertTitle.localizedString, message: AmityLocalizedStringSet.Social.communitySettingCloseCommunityAlertMessage.localizedString, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
                    let confirmAction = UIAlertAction(title: AmityLocalizedStringSet.General.confirm.localizedString, style: .destructive) { _ in
                        closeCommunity()
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(confirmAction)
                    
                    host.controller?.present(alertController, animated: true)
                }
                .isHidden(viewConfig.isHidden(elementId: .closeCommunity))
                .accessibilityIdentifier(AccessibilityID.Social.CommunitySettings.closeCommunity)
            }
            
            Spacer()
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .padding([.leading, .trailing], 16)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            Image(AmityIcon.backIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .onTapGesture {
                    host.controller?.navigationController?.popViewController()
                }
            
            Spacer()
            
            Text(viewModel.community.displayName)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
            
            Spacer()
            
            Color
                .clear
                .frame(width: 24, height: 20)
        }
    }
    
    
    func getItemView(_ icon: ImageResource, _ text: String, disclosureText: String? = nil) -> some View {
        HStack(spacing: 12) {
            Color(viewConfig.theme.baseColorShade4)
                .frame(width: 28, height: 28)
                .overlay (
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 22, height: 18)
                        .clipped()
                )
                .cornerRadius(4)
            
            Text(text)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
            
            Spacer()
            
            if let disclosureText {
                Text(disclosureText)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
            }
            
            Image(AmityIcon.arrowIcon.getImageResource())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }
        .contentShape(Rectangle())
    }
    
    
    private func leaveCommunity() {
        Toast.showToast(style: .loading, message: "Leaving the community.")
        Task { @MainActor in
            do {
                try await viewModel.leaveCommunity()
                Toast.showToast(style: .success, message: "Successfully leaved community!")
                
                // Pop to Community Profile Page
                host.controller?.navigationController?.popToViewController(AmityCommunityProfilePage.self, animated: true)
            } catch {
                if let error = AmityError(error: error), error == .unableToLeaveCommunity {
                    Toast.hideToastIfPresented()
                    
                    let alertController = UIAlertController(title: AmityLocalizedStringSet.Social.communitySettingLeaveCommunityFailedAlertTitle.localizedString, message: AmityLocalizedStringSet.Social.communitySettingLeaveCommunityFailedAlertMessage.localizedString, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: AmityLocalizedStringSet.General.okay.localizedString, style: .cancel)
                    alertController.addAction(okAction)
                    host.controller?.present(alertController, animated: true)
                    
                    return
                }
                
                Toast.showToast(style: .warning, message: error.localizedDescription)
            }
        }
    }
    
    
    private func closeCommunity() {
        Toast.showToast(style: .loading, message: "Closing the community.")
        viewModel.deleteCommunity() { error in
            if let error {
                Toast.showToast(style: .warning, message: error.localizedDescription)
                return
            }
            
            Toast.showToast(style: .success, message: "Successfully closed community!")
            host.controller?.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func getPageBehaviorContext() -> AmityCommunitySettingPageBehavior.Context {
        viewModel.refreshCommunitySnapshot()
        let context = AmityCommunitySettingPageBehavior.Context(page: self, community: viewModel.community)
        return context
    }
}
