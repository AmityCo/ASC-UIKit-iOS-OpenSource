//
//  AmityUserProfilePage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/17/24.
//

import SwiftUI

public struct AmityUserProfilePage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .userProfilePage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityUserProfilePageViewModel
    @State private var currentTab: Int = 0
    @State private var showStickyHeader: Bool = false
    @State private var showDisplayName: Bool = false
    @State private var headerComponentHeight: CGFloat = 0.0
    @State private var scrollOffsetY: CGFloat = 0.0
    @State private var isRefreshing: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var postCreationBottomSheet: Bool = false
    @State private var isUserReported: Bool = false
    private let userId: String
    
    @Namespace var namespace
    
    public init(userId: String) {
        self.userId = userId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .userProfilePage))
        self._viewModel = StateObject(wrappedValue: AmityUserProfilePageViewModel(userId))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
                .padding(.leading, 16)
                .padding(.trailing, 6)
            
            tabBarView
                .padding(.top, 10)
                .isHidden(!showStickyHeader)
            
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ProgressView()
                                .frame(width: 20, height: 20)
                                .padding(.vertical, 10)
                                .isHidden(!isRefreshing)
                            
                            if let user = viewModel.user {
                                AmityUserProfileHeaderComponent(user: user.object, userProfilePageViewModel: viewModel, pageId: id)
                                    .padding(.horizontal, 16)
                                    .readSize { headerComponentHeight = $0.height }
                            } else {
                                UserProfileHeaderSkeletonView()
                            }
                            
                            tabBarView
                                .padding(.top, 22)
                                .isHidden(showStickyHeader)
                        }
                        .offset(y: scrollOffsetY)
                        
                        if let user = viewModel.user {
                            AmityUserFeedComponent(userId: user.userId, userProfilePageViewModel: viewModel, pageId: id)
                                .isHidden(currentTab != 0)
                            
                            AmityUserImageFeedComponent(userId: user.userId, userProfilePageViewModel: viewModel, pageId: id)
                                .isHidden(currentTab != 1)
                            
                            AmityUserVideoFeedComponent(userId: user.userId, userProfilePageViewModel: viewModel, pageId: id)
                                .isHidden(currentTab != 2)
                        }
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    })
                }
                
                if let user = viewModel.user {
                    createPostView
                        .isHidden(!user.isCurrentUser)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offsetY in
                /// Update scrollOffsetY only if it is scrolled down from ideal offset
                /// Set scrollOffsetY 0 not to move header and tabBar view on scrolling down from ideal offset
//                    if offsetY >= 0 {
//                        scrollOffsetY = min(0, -offsetY)
//                    }
                
                /// Show display name on navigation bar if it is scrolled up to the end of name in header component
                if showDisplayName != (offsetY < -35) {
                    showDisplayName.toggle()
                }
                
                /// Show sticky header if it is scrolled up to tab bar position
                if showStickyHeader != (offsetY < -headerComponentHeight - 10) {
                    showStickyHeader.toggle()
                }
                
                /// Refresh data if it is scrolled down from ideal offset
                if offsetY >= 120 && !isRefreshing {
                    isRefreshing = true
                    
                    Task {
                        viewModel.refreshFeed(currentTab: currentTab)
                        await waitWhileRefreshing()
                        await MainActor.run {
                            isRefreshing = false
                        }
                    }
                }
            }
        }
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor), sheetContent: {
            bottomSheetView
        })
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
        .environmentObject(host)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
    }
    
    private var navigationBarView: some View {
        AmityNavigationBar(title: showDisplayName ? viewModel.user?.displayName ?? "" : "", leading: {
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
        }, trailing: {
            let menuButton = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .menuButton, key: "image", of: String.self) ?? "")
            Button {
                showBottomSheet.toggle()
            } label: {
                Image(menuButton)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(width: 24, height: 24)
            }
        })
    }
    
    private var tabBarView: some View {
        ZStack(alignment: .bottom) {
            HStack {
                let feedTabItem = TabItem(index: 0, image: AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .userFeedTabButton, key: "image", of: String.self) ?? ""))
                TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: feedTabItem)
                    .isHidden(viewConfig.isHidden(elementId: .userFeedTabButton))
                    .accessibilityIdentifier(AccessibilityID.Social.UserProfile.userFeedTabButton)
                
                let imageFeedTabItem = TabItem(index: 1, image: AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .userImageFeedTabButton, key: "image", of: String.self) ?? ""))
                TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: imageFeedTabItem)
                    .isHidden(viewConfig.isHidden(elementId: .userImageFeedTabButton))
                    .accessibilityIdentifier(AccessibilityID.Social.UserProfile.userImageFeedTabButton)
                
                let videoFeedTabItem = TabItem(index: 2, image: AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .userVideoFeedTabButton, key: "image", of: String.self) ?? ""))
                TabItemView(currentTab: $currentTab, namespace: namespace.self, tabItem: videoFeedTabItem)
                    .isHidden(viewConfig.isHidden(elementId: .userVideoFeedTabButton))
                    .accessibilityIdentifier(AccessibilityID.Social.UserProfile.userVideoFeedTabButton)
            }
            .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .offset(y: 1)
        }
        .padding(.bottom, 1)
    }
    
    @ViewBuilder
    private var bottomSheetView: some View {
        if userId == AmityUIKitManagerInternal.shared.currentUserId {
            ownerBottomSheet
        } else {
            nonOwnerBottomSheet
        }
    }
    
    private var ownerBottomSheet: some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: AmityIcon.editCommentIcon.getImageResource(), text: "Edit Profile")
                .onTapGesture {
                    showBottomSheet.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        let context = AmityUserProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.userProfilePageBehavior?.goToEditUserPage(context: context)
                    }
                }
            
            BottomSheetItemView(icon: AmityIcon.blockUserIcon.getImageResource(), text: "Manage blocked users")
                .onTapGesture {
                    showBottomSheet.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        let context = AmityUserProfilePageBehavior.Context(page: self)
                        AmityUIKitManagerInternal.shared.behavior.userProfilePageBehavior?.goToBlockedUsersPage(context: context)
                    }
                }
        }
        .padding(.bottom, 32)
    }
    
    private var nonOwnerBottomSheet: some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: isUserReported ? AmityIcon.unflagIcon.getImageResource() : AmityIcon.flagIcon.getImageResource(), text: isUserReported ? "Unreport user" :"Report user")
                .onTapGesture {
                    showBottomSheet.toggle()
    
                    Task { @MainActor in
                        if isUserReported {
                            do {
                                try await viewModel.unflag()
                                Toast.showToast(style: .success, message: "User unreported.")
                            } catch {
                                Toast.showToast(style: .warning, message: "Failed to unreport user. Please try again.")
                            }
                            
                        } else {
                            do {
                                try await viewModel.flag()
                                Toast.showToast(style: .success, message: "User reported.")
                            } catch {
                                Toast.showToast(style: .warning, message: "Failed to report user. Please try again.")
                            }
                        }
                    }
                }
                .onAppear {
                    Task { @MainActor in
                        isUserReported = try await viewModel.isFlaggedByMe()
                    }
                }
            
            let isBlockedUser = viewModel.profileHeaderViewModel.followInfo?.status ?? .none == .blocked
            BottomSheetItemView(icon: isBlockedUser ? AmityIcon.unblockUserIcon.getImageResource() : AmityIcon.blockUserIcon.getImageResource(), text: isBlockedUser ? "Unblock user" :  "Block user")
                .onTapGesture {
                    showBottomSheet.toggle()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Task { @MainActor in
                            if isBlockedUser {
                                showAlert(title: "Unblock user?", message: "\(viewModel.user?.displayName ?? "") will now be able to see posts and comments that you’ve created. They won’t be notified that you’ve unblocked them.", btnTitle: "Unblock", btnAction: {
                                    Task { @MainActor in
                                        do {
                                            try await viewModel.unblock()
                                            Toast.showToast(style: .success, message: "User unblocked.")
                                        } catch {
                                            Toast.showToast(style: .warning, message: "Failed to unblocked user. Please try again.")
                                        }
                                    }
                                })

                            } else {
                                showAlert(title: "Block user?", message: "\(viewModel.user?.displayName ?? "") won’t be able to see posts and comments that you’ve created. They won’t be notified that you’ve blocked them.", btnTitle: "Block", btnAction: {
                                    Task { @MainActor in
                                        do {
                                            try await viewModel.block()
                                            Toast.showToast(style: .success, message: "User blocked.")
                                        } catch {
                                            Toast.showToast(style: .warning, message: "Failed to block user. Please try again.")
                                        }
                                    }
                                })

                            }
                        }
                    }
                }
        }
        .padding(.bottom, 32)
    }
    
    private func waitWhileRefreshing() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func showAlert(title: String, message: String, btnTitle: String, btnAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let btnAction = UIAlertAction(title: btnTitle, style: .destructive) { _ in
            btnAction()
        }
        alert.addAction(cancelAction)
        alert.addAction(btnAction)
        
        host.controller?.present(alert, animated: true)
    }
    
    // Create post button
    @ViewBuilder
    private var createPostView: some View {
        Button(action: {
            postCreationBottomSheet.toggle()
        }, label: {
            ZStack {
                Rectangle()
                    .fill(Color(viewConfig.theme.primaryColor))
                    .clipShape(RoundedCorner())
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4, y: 2)
                Image(AmityIcon.plusIcon.imageResource)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(viewConfig.theme.backgroundColor))
            }
        })
        .buttonStyle(BorderlessButtonStyle())
        .padding(.trailing, 16)
        .padding(.bottom, 8)
        .bottomSheet(isShowing: $postCreationBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack {
                BottomSheetItemView(icon: AmityIcon.createPostMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString)
                    .onTapGesture {
                        postCreationBottomSheet.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let context = AmityUserProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.userProfilePageBehavior?.goToPostComposerPage(context: context)
                        }
                    }
                
                BottomSheetItemView(icon: AmityIcon.createPollMenuIcon.imageResource, text: "Poll")
                    .onTapGesture {
                        postCreationBottomSheet.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let context = AmityUserProfilePageBehavior.Context(page: self)
                            AmityUIKitManagerInternal.shared.behavior.userProfilePageBehavior?.goToPollPostComposerPage(context: context)
                        }
                    }
            }
            .padding(.bottom, 32)
        }
    }
}
