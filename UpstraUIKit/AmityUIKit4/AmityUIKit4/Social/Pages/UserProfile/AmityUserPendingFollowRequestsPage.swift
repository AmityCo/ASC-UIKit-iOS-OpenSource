//
//  AmityUserPendingFollowRequestsPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/25/24.
//

import SwiftUI

public struct AmityUserPendingFollowRequestsPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .pendingFollowRequestPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityUserPendingFollowRequestsPageViewModel
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .pendingFollowRequestPage))
        self._viewModel = StateObject(wrappedValue: AmityUserPendingFollowRequestsPageViewModel(AmityUIKitManagerInternal.shared.currentUserId))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
                .padding(.all, 16)
            
            if viewModel.users.isEmpty {
                getEmptyView()
            } else {
                getContentView()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
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
            
            Text("Follow requests (\(viewModel.users.count))")
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 20)
        }
    }
    
    @ViewBuilder
    func getEmptyView() -> some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image(AmityIcon.emptyPendingPostIcon.getImageResource())
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text("No requests to review")
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func getContentView() -> some View {
        if viewModel.loadingStatus == .loading {
            List {
                ForEach(0..<5, id: \.self) { index in
                    PostContentSkeletonView()
                        .listRowInsets(EdgeInsets())
                        .modifier(HiddenListSeparator())
                }
            }
            .listStyle(.plain)
            .environmentObject(viewConfig)
        } else {
            if #available(iOS 15.0, *) {
                getUserListView()
                    .refreshable {
                        viewModel.getPendingFollowers()
                    }
            } else {
                getUserListView()
            }
        }
    }
    
    
    @ViewBuilder
    func getUserListView() -> some View {
        Rectangle()
            .fill(Color(viewConfig.theme.baseColorShade4))
            .frame(height: 60)
            .overlay(
                Text("Declining a follow request is irreversible. The user must send a new request if declined.")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .padding([.leading, .trailing], 16)
            )
        
        List {
            ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                let userModel = AmityUserModel(user: user)
                VStack(spacing: 16) {
                    getUserCell(userModel)
                    
                    Rectangle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(height: 8)
                }
                .listRowInsets(EdgeInsets())
                .modifier(HiddenListSeparator())
                .onAppear {
                    if index == viewModel.users.count - 1 {
                        viewModel.loadMore()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func getUserCell(_ user: AmityUserModel) -> some View {
        HStack {
            AmityUserProfileImageView(displayName: user.displayName, avatarURL: URL(string: user.avatarURL))
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            
            Text("\(user.displayName)")
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
            Image(AmityIcon.brandBadge.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.leading, -4)
                .opacity(user.isBrand ? 1 : 0)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            goToUserProfilePage(user.userId)
        }
        
        requestActionView(user)
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func requestActionView(_ user: AmityUserModel) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.primaryColor))
                .overlay (
                    Text("Accept")
                        .applyTextStyle(.bodyBold(.white))
                )
                .cornerRadius(8)
                .onTapGesture {
                    Task { @MainActor in
                        do {
                            try await viewModel.acceptMyFollower(user.userId)
                            Toast.showToast(style: .success, message: "\(user.displayName) is now following you.")
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to accept follow request. Please try again.")
                        }
                    }
                }
                
            
            Rectangle()
                .fill(.clear)
                .overlay (
                    Text("Decline")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 1)
                )
                .onTapGesture {
                    Task { @MainActor in
                        do {
                            try await viewModel.declineMyFollower(user.userId)
                            Toast.showToast(style: .success, message: "Following request declined.")
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to decline follow request. Please try again.")
                        }
                    }
                }
        }
        .frame(height: 40)
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityUserPendingFollowRequestsPageBehavior.Context(page: self, userId: userId)
        AmityUIKitManagerInternal.shared.behavior.userPendingFollowRequestsPageBehavior?.goToUserProfilePage(context: context)
    }
}
