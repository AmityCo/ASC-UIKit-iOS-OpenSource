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
    
    public var id: PageId {
        .communityMembershipPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityMembershipPage))
        self.community = community
    }
    
    
    public var body: some View {
        VStack(spacing: 12) {
            navigationBarView
                .padding(.all, 16)
            
            ZStack(alignment: .bottom) {
                TabBarView(currentTab: $tabIndex, tabBarOptions: $tabs)
                    .selectedTabColor(viewConfig.theme.primaryColor)
                    .onChange(of: tabIndex) { value in

                    }   
                    .padding(.leading, 5)
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 0.5)
                    .offset(y: -1)
            }
            .padding([.leading, .trailing], 16)
            
            TabView(selection: $tabIndex) {
                CommunityMemberTabView(viewConfig: viewConfig, community: community, onTapAction: { member in
                    viewModel.communityMember = member
                    viewModel.showBottomSheet.toggle()
                })
                .tag(0)
                
                CommunityModeratorTabView(viewConfig: viewConfig, community: community, onTapAction: { member in
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
            
            Text("All members")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Image(AmityIcon.plusIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 22, height: 20)
                .onTapGesture {
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
        }
    }
    
    @ViewBuilder
    func getBottomSheetView() -> some View {
        if let member = viewModel.communityMember {
            CommunityMembershipBottomSheetView(showBottomSheet: $viewModel.showBottomSheet, community: community, communityMember: member)
                .environmentObject(viewConfig)
        }
    }
}

class AmityCommunityMembershipPageViewModel: ObservableObject {
    @Published var showBottomSheet: Bool = false
    var communityMember: AmityCommunityMember?
}
