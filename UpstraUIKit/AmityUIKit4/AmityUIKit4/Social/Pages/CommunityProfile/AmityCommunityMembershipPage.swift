//
//  AmityCommunityMembershipPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommunityMembershipPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = [
        AmityLocalizedStringSet.Social.communitySettingMembers.localizedString,
        AmityLocalizedStringSet.Social.communityMembershipTabModerators.localizedString
    ]
    @StateObject private var viewModel = AmityCommunityMembershipPageViewModel()
    private let community: AmityCommunity
    
    /// Members need to be invited if network setting is invitation mode
    @State private var isMembershipInvitationEnabled: Bool = false
    @State private var hasEditMemberPermission: Bool = false
    @State private var refreshTrigger = 0
    
    public var id: PageId {
        .communityMembershipPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityMembershipPage))
        self.community = community
        
        if let setting = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.membershipAcceptance {
            self._isMembershipInvitationEnabled = State(initialValue: setting == .invitation)
        }
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            navigationBarView
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                    .selectedTabColor(viewConfig.theme.highlightColor)
                    .onChange(of: tabIndex) { value in

                    }   
                    .padding(.leading, 5)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            .padding([.leading, .trailing], 16)
            
            TabView(selection: $tabIndex) {
                CommunityMemberTabView(viewConfig: viewConfig, community: community, refreshTrigger: $refreshTrigger, onTapAction: { member in
                    goToUserProfilePage(member.userId)
                }, onMenuAction: { member in
                    viewModel.communityMember = member
                    viewModel.showBottomSheet.toggle()
                })
                .tag(0)
                
                CommunityModeratorTabView(viewConfig: viewConfig, community: community, onTapAction: { member in
                    goToUserProfilePage(member.userId)
                }, onMenuAction: { member in
                    viewModel.communityMember = member
                    viewModel.showBottomSheet.toggle()
                })
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .bottomSheet(isShowing: $viewModel.showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            getBottomSheetView()
        }
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            
            let communityId = community.communityId
            Task {
                self.hasEditMemberPermission = await CommunityPermissionChecker.hasEditCommunityUserPermission(communityId: communityId)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    
    private var navigationBarView: some View {
        return AmityNavigationBar(title: AmityLocalizedStringSet.Social.communityMembershipAllMembersTitle.localizedString, showBackButton: true) {
            Image(AmityIcon.plusIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 22, height: 20)
                .isHidden(!hasEditMemberPermission)
                .onTapGesture {
                    if isMembershipInvitationEnabled && hasEditMemberPermission {
                        goToInviteMemberPage()
                    } else {
                        goToAddUserPage()
                    }
                }
        }
    }
    
    @ViewBuilder
    func getBottomSheetView() -> some View {
        if let member = viewModel.communityMember {
            CommunityMembershipBottomSheetView(showBottomSheet: $viewModel.showBottomSheet, community: community, communityMember: member, onMemberRemoved: {
                
                Toast.showToast(style: .loading, message: AmityLocalizedStringSet.Social.communityMemberRemoveLoadingToast.localizedString)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    refreshTrigger += 1

                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMemberRemovedToast.localizedString)
                }
            })
            .environmentObject(viewConfig)
        }
    }
    
    private func goToAddUserPage() {
        let onAddedAction: ([AmityUserModel]) -> Void = { users in
            Task { @MainActor in
                do {
                    let _ = try await community.membership.addMembers(users.map {$0.userId})
                    
                    Toast.showToast(style: .loading, message: AmityLocalizedStringSet.Social.communityMemberAddLoadingToast.localizedString)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        refreshTrigger += 1

                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMembershipAddSuccess.localizedString)
                    }
                    
                } catch {
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.communityMembershipAddFailed.localizedString)
                }
            }
        }
        
        let context = AmityCommunityMembershipPageBehavior.Context(page: self, addUserPageCompletion: onAddedAction)
        AmityUIKitManagerInternal.shared.behavior.communityMembershipPageBehavior?.goToAddMemberPage(context)
    }
    
    private func goToInviteMemberPage() {
        let onInvitedAction: ([AmityUserModel]) -> Void = { users in
            Task { @MainActor in
                do {
                    try await community.createInvitations(users.map { $0.userId })
                    self.host.controller?.presentedViewController?.dismiss(animated: true)
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.communityMembershipInviteSuccess.localizedString)
                } catch {
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.communityMembershipInviteFailed.localizedString)
                }
            }
        }
        
        let context = AmityCommunityMembershipPageBehavior.Context(page: self, inviteMemberPageCompletion: onInvitedAction)
        AmityUIKitManagerInternal.shared.behavior.communityMembershipPageBehavior?.goToInviteMemberPage(context)
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let page = AmityUserProfilePage(userId: userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

class AmityCommunityMembershipPageViewModel: ObservableObject {
    @Published var showBottomSheet: Bool = false
    var communityMember: AmityCommunityMember?
}
