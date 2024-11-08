//
//  AmityBlockedUsersPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/25/24.
//

import SwiftUI
import AmitySDK

public struct AmityBlockedUsersPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .blockedUsersPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityBlockedUsersPageViewModel
    
    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .blockedUsersPage))
        self._viewModel = StateObject(wrappedValue: AmityBlockedUsersPageViewModel(AmityUIKitManagerInternal.shared.currentUserId))
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            navigationBarView
                .padding(.horizontal, 16)
            
            ZStack {
                emptyView
                    .isHidden(!viewModel.blockedUsers.isEmpty)
                
                userListView
                    .isHidden(viewModel.blockedUsers.isEmpty)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
    
    @ViewBuilder
    private var navigationBarView: some View {
        let title = viewConfig.getConfig(elementId: .title, key: "text", of: String.self) ?? "Manage blocked users"
        AmityNavigationBar(title: title, leading: {
            let backButton = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .backButtonElement, key: "image", of: String.self) ?? "")
            Image(backButton)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .onTapGesture {
                    host.controller?.navigationController?.popViewController()
                }
        }, trailing: { EmptyView() })
    }
    
    @ViewBuilder
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.loadingStatus == .loading {
                    ForEach(0..<10, id: \.self) { _ in
                        UserCellSkeletonView()
                            .padding([.leading, .trailing], 16)
                            .environmentObject(viewConfig)
                    }
                } else {
                    ForEach(Array(viewModel.blockedUsers.enumerated()), id: \.element.userId) { index, user in
                        getUserCellView(user, unblockAction: { user in
                            let alert = UIAlertController(title: "Unblock user?", message: "They will now be able to see posts and comments that you’ve created. They won’t be notified that you’ve unblocked them.", preferredStyle: .alert)
                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                            let unblockAction = UIAlertAction(title: "Unblock", style: .destructive) { _ in
                                Task { @MainActor in
                                    do {
                                        try await viewModel.unblockUser(withId: user.userId)
                                        Toast.showToast(style: .success, message: "User unblocked.")
                                    } catch {
                                        Toast.showToast(style: .warning, message: "Failed to unblock user. Please try again.")
                                    }
                                }
                            }
                            
                            alert.addAction(cancelAction)
                            alert.addAction(unblockAction)
                            host.controller?.present(alert, animated: true)
                        })
                        .padding([.leading, .trailing], 16)
                        .onTapGesture {
                            goToUserProfilePage(user.userId)
                        }
                        .onAppear {
                            if index == viewModel.blockedUsers.count - 1 {
                                viewModel.loadMore()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                Image(AmityIcon.listRadioIcon.getImageResource())
                    .renderingMode(.template)
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    .padding(.top, 24)
                
                Text("Nothing here to see yet")
                    .applyTextStyle(.title(Color(viewConfig.theme.baseColorShade3)))
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
            }
            .background(Color(viewConfig.theme.backgroundColor))
            .updateTheme(with: viewConfig)
            .padding(.bottom, 50)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func getUserCellView(_ user: AmityUser, unblockAction: @escaping (AmityUser) -> Void) -> some View {
        HStack(spacing: 0) {
            AmityUserProfileImageView(displayName: user.displayName ?? "", avatarURL: URL(string: user.getAvatarInfo()?.fileURL ?? ""))
                .frame(size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
            
            Text(user.displayName ?? "Unknown")
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .padding(.leading, 8)
                        
            Image(AmityIcon.brandBadge.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.leading, 4)
                .opacity(user.isBrand ? 1 : 0)
            
            Spacer()
            
            Button {
                unblockAction(user)
            } label: {
                Text("Unblock")
                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                    .padding(8)
                    .overlay (
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 2)
                    )
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityBlockedUsersPageBehavior.Context(page: self, userId: userId)
        AmityUIKitManagerInternal.shared.behavior.blockedUsersPageBehavior?.goToUserProfilePage(context: context)
    }
}
