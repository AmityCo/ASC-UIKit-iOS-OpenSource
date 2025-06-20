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
    @State private var tabs: [String] = ["Members", "Moderators"]
    @StateObject private var viewModel = AmityCommunityMembershipPageViewModel()
    private let community: AmityCommunity
    
    /// Members need to be invited if network setting is invitation mode
    @State private var isMembershipInvitationEnabled: Bool = false
    
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
                CommunityMemberTabView(viewConfig: viewConfig, community: community, onTapAction: { member in
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
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    
    private var navigationBarView: some View {
        return AmityNavigationBar(title: "All members", showBackButton: true) {
            Image(AmityIcon.plusIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 22, height: 20)
                .onTapGesture {
                    if isMembershipInvitationEnabled {
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
            CommunityMembershipBottomSheetView(showBottomSheet: $viewModel.showBottomSheet, community: community, communityMember: member)
                .environmentObject(viewConfig)
        }
    }
    
    private func goToAddUserPage() {
        let onAddedAction: ([AmityUserModel]) -> Void = { users in
            Task { @MainActor in
                do {
                    let _ = try await community.membership.addMembers(users.map {$0.userId})
                    Toast.showToast(style: .success, message: "Successfully added members to this community!")
                } catch {
                    Toast.showToast(style: .warning, message: "Failed to add members to this community")
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
                    Toast.showToast(style: .success, message: "Successfully invited members to this community.")
                } catch {
                    Toast.showToast(style: .warning, message: "Failed to invite members. Please try again.")
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
