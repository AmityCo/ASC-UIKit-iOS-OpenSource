//
//  AmityUserProfileHeaderComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/17/24.
//

import SwiftUI
import AmitySDK

public struct AmityUserProfileHeaderComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    public var pageId: PageId?
    
    public var id: ComponentId {
        .userProfileHeader
    }
        
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityUserProfileHeaderComponentViewModel
    @State private var showMediaViewer: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var canLoadProfileAvatar: Bool = false
    private let user: AmityUserModel
    
    private var isOwnProfile: Bool {
        return user.isCurrentUser
    }
    
    public init(user: AmityUser, userProfilePageViewModel: AmityUserProfilePageViewModel? = nil, pageId: PageId? = nil) {
        self.user = AmityUserModel(user: user)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .userProfileHeader))
        if let userProfilePageViewModel {
            self._viewModel = StateObject(wrappedValue: userProfilePageViewModel.profileHeaderViewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: AmityUserProfileHeaderComponentViewModel(user.userId))
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            userHeaderView
            
            ExpandableText(user.about)
                .moreButtonText("...See more")
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .attributedColor(viewConfig.theme.primaryColor)
                .moreButtonColor(Color(viewConfig.theme.primaryColor))
                .expandAnimation(.easeOut(duration: 0.25))
                .font(AmityTextStyle.body(.clear).getFont())
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .isHidden(viewConfig.isHidden(elementId: .userDescription) || user.about.isEmpty)
                .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.userDescription)
            
            userRelationshipView
                .frame(height: 20)
                .padding(.top, 6)
            
            if let followInfo = viewModel.followInfo, let status = followInfo.status, !isOwnProfile {
                Group {
                    switch status {
                    case .none:
                        followButton
                    case .pending:
                        pendingRequestButton
                    case .accepted:
                        followingButton
                    case .blocked:
                        unblockButton
                    default:
                        EmptyView()
                    }
                }
                .padding(.top, 8)
            }
            
            if viewModel.followRequestCount != 0, isOwnProfile {
                pendingFollowRequestView
                    .padding(.vertical, 8)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .fullScreenCover(isPresented: $showMediaViewer) {
            MediaViewer(url: URL(string: user.avatarURL), closeAction: { showMediaViewer.toggle() })
        }
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor), sheetContent: {
            bottomSheetView
        })
        .updateTheme(with: viewConfig)
        .environmentObject(host)
    }
    
    private var userHeaderView: some View {
        HStack(spacing: 12) {
            AmityUserProfileImageView(displayName: user.displayName, avatarURL: URL(string: user.avatarURL))
                .onLoaded { success in
                    canLoadProfileAvatar = success
                }
                .onTapGesture {
                    withoutAnimation {
                        guard canLoadProfileAvatar else { return }
                        showMediaViewer.toggle()
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .isHidden(viewConfig.isHidden(elementId: .userAvatar))
                .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.userAvatar)
            
            ZStack(alignment: .bottomTrailing) {
                Text(user.displayName)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .lineLimit(4)
                    .isHidden(viewConfig.isHidden(elementId: .userName))
                    .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.userName)
                
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .offset(x: 30) // image size + padding
                    .opacity(user.isBrand ? 1 : 0)
            }
            
            Spacer()
        }
    }
    
    private var userRelationshipView: some View {
        HStack(spacing: 0) {
            Group {
                Text((viewModel.followInfo?.followingCount ?? 0).formattedCountString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                let followingText = viewConfig.getConfig(elementId: .userFollowing, key: "text", of: String.self) ?? "followings"
                Text(followingText)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.leading, 4)
            }
            .isHidden(viewConfig.isHidden(elementId: .userFollowing) || user.isBrand)
            .onTapGesture {
                guard user.isCurrentUser || viewModel.followInfo?.status == .accepted else { return }
                goToUserRelationshipPage(user.userId, .following)
            }
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.userFollowing)
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 2)
                .padding(.leading, 12)
                .isHidden(viewConfig.isHidden(elementId: .userFollower) || viewConfig.isHidden(elementId: .userFollowing) || user.isBrand)
            
            Group {
                Text((viewModel.followInfo?.followerCount ?? 0).formattedCountString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .padding(.leading, 12)
                
                let followerText = viewConfig.getConfig(elementId: .userFollower, key: "text", of: String.self) ?? "followers"
                Text(followerText)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .padding(.leading, 4)
            }
            .isHidden(viewConfig.isHidden(elementId: .userFollower))
            .onTapGesture {
                guard user.isCurrentUser || viewModel.followInfo?.status == .accepted else { return }
                goToUserRelationshipPage(user.userId, .follower)
            }
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.userFollower)
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var pendingFollowRequestView: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center,spacing: 7) {
                Image(AmityIcon.communityPendingPostIcon.imageResource)
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 6, height: 6)
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                
                Text(AmityLocalizedStringSet.Social.userProfileFollowRequestTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            }
            .padding(.top, 12)
            
            Text("\(viewModel.followRequestCount) \(viewModel.followRequestCount == 1 ? "request" : "requests") need your approval")
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color(viewConfig.theme.baseColorShade4))
        .cornerRadius(6)
        .onTapGesture {
            let context = AmityUserProfileHeaderComponentBehavior.Context(component: self, userId: user.userId)
            AmityUIKitManagerInternal.shared.behavior.userProfileHeaderComponentBehavior?.goToPendingFollowRequestPage(context: context)
        }
    }
    
    @ViewBuilder
    private var followButton: some View {
        let followUserIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .followUserButton, key: "image", of: String.self) ?? "")
        let followUserText = viewConfig.getConfig(elementId: .followUserButton, key: "text", of: String.self) ?? "Follow"
        getRelationshipButton(followUserIcon, followUserText, Color(viewConfig.theme.primaryColor))
            .onTapGesture {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                Task { @MainActor in
                    do {
                        try await viewModel.follow()
                    } catch {
                        let alert = UIAlertController(title: "Unable to follow this user", message: "Oops! something went wrong. Please try again later.", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .cancel)
                        alert.addAction(action)
                        host.controller?.present(alert, animated: true)
                    }
                }
            }
            .isHidden(viewConfig.isHidden(elementId: .followUserButton))
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.followUserButton)
    }
    
    @ViewBuilder
    private var pendingRequestButton: some View {
        let pendingUserIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .pendingUserButton, key: "image", of: String.self) ?? "")
        let pendingUserText = viewConfig.getConfig(elementId: .pendingUserButton, key: "text", of: String.self) ?? "Cancel request"
        getRelationshipButton(pendingUserIcon, pendingUserText, .clear)
            .onTapGesture {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                Task { @MainActor in
                    try await viewModel.unfollow()
                }
            }
            .isHidden(viewConfig.isHidden(elementId: .pendingUserButton))
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.pendingUserButton)
    }
    
    @ViewBuilder
    private var followingButton: some View {
        let followingUserIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .followingUserButton, key: "image", of: String.self) ?? "")
        let followingUserText = viewConfig.getConfig(elementId: .followingUserButton, key: "text", of: String.self) ?? "Following"
        getRelationshipButton(followingUserIcon, followingUserText, .clear)
            .onTapGesture {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                showBottomSheet.toggle()
            }
            .isHidden(viewConfig.isHidden(elementId: .followingUserButton))
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.followingUserButton)
    }
    
    @ViewBuilder
    private var unblockButton: some View {
        let unblockUserIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .unblockUserButton, key: "image", of: String.self) ?? "")
        let unblockUserText = viewConfig.getConfig(elementId: .unblockUserButton, key: "text", of: String.self) ?? "Following"
        getRelationshipButton(unblockUserIcon, unblockUserText, .clear)
            .onTapGesture {
                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                showAlert(title: "Unblock user?", message: "\(user.displayName) will now be able to see posts and comments that you’ve created. They won’t be notified that you’ve unblocked them.", btnTitle: "Unblock", btnAction: {
                    Task { @MainActor in
                        do {
                            try await viewModel.unblock()
                            Toast.showToast(style: .success, message: "User unblocked.")
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to unblocked user. Please try again.")
                        }
                    }
                })
            }
            .isHidden(viewConfig.isHidden(elementId: .unblockUserButton))
            .accessibilityIdentifier(AccessibilityID.Social.UserProfileHeader.unblockUserButton)
    }
    
    @ViewBuilder
    private func getRelationshipButton(_ icon: ImageResource, _ text: String, _ color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: 40)
            .overlay(
                HStack(alignment: .center, spacing: 8) {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(color != .clear ? .white : Color(viewConfig.theme.baseColor))
                        .frame(width: 20, height: 20)
                    
                    Text(text)
                        .applyTextStyle(.bodyBold(color != .clear ? .white : Color(viewConfig.theme.baseColor)))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1)
            )
            .cornerRadius(8)
            .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: AmityIcon.unfollowingUserIcon.getImageResource(), text: "Unfollow")
                .onTapGesture {
                    showBottomSheet.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAlert(title: "Unfollow this user?", message: "If you change your mind, you’ll have to request to follow them again.", btnTitle: "Unfollow", btnAction: {
                            Task { @MainActor in
                                try await viewModel.unfollow()
                            }
                        })
                    }
                }
        }
        .padding(.bottom, 32)
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
    
    private func goToUserRelationshipPage(_ userId: String, _ tab: AmityUserRelationshipPageTab) {
        let context = AmityUserProfileHeaderComponentBehavior.Context(component: self, userId: userId, selectedTab: tab)
        AmityUIKitManagerInternal.shared.behavior.userProfileHeaderComponentBehavior?.goToUserRelationshipPage(context: context)
    }
}
