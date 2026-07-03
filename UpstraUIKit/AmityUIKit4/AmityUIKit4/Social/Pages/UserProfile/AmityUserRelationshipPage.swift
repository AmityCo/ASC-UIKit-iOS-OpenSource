//
//  AmityUserRelationshipPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/24/24.
//

import SwiftUI

public enum AmityUserRelationshipPageTab {
    case following, follower
}

public struct AmityUserRelationshipPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var tabIndex: Int = 0
    @State private var tabs: [String] = [AmityLocalizedStringSet.Social.userFollowingButton.localizedString, "Followers"]
    private let userId: String
    @StateObject private var viewModel: AmityUserRelationshipPageViewModel
    @State private var showBottomSheet: (isShown: Bool, userId: String, displayName: String) = (false, "", "")
    @State private var isSelectedUserReported: Bool = false
    
    public var id: PageId {
        .userRelationshipPage
    }
    
    public init(userId: String, selectedTab: AmityUserRelationshipPageTab) {
        self.userId = userId
        self._tabIndex = State(initialValue: selectedTab == .following ? 0 : 1)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .userRelationshipPage))
        self._viewModel = StateObject(wrappedValue: AmityUserRelationshipPageViewModel(userId))
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            navigationBarView
            
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
            .padding(.horizontal, 16)
            
            UserRelationshipTabView(type: .following, userId: userId, onTapAction: { user in
                goToUserProfilePage(user.userId)
            }, menuButtonAction: { user in
                showBottomSheet.userId = user.userId
                showBottomSheet.displayName = user.displayName ?? ""
                showBottomSheet.isShown.toggle()
            })
            .isHidden(tabIndex != 0)
            
            UserRelationshipTabView(type: .follower, userId: userId, onTapAction: { user in
                goToUserProfilePage(user.userId)
            }, menuButtonAction: { user in
                showBottomSheet.userId = user.userId
                showBottomSheet.displayName = user.displayName ?? ""
                showBottomSheet.isShown.toggle()
            })
            .isHidden(tabIndex != 1)
        }
        .bottomSheet(isShowing: $showBottomSheet.isShown, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor), sheetContent: {
            bottomSheetView
        })
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    private var navigationBarView: some View {
        AmityNavigationBar(title: viewModel.user?.displayName ?? "", leading: {
            Image(AmityIcon.backIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
                .onTapGesture {
                    host.controller?.navigationController?.popViewController()
                }
        }, trailing: {
            EmptyView()
        })
    }
    
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            BottomSheetItemView(icon: isSelectedUserReported ? AmityIcon.unflagIcon.getImageResource() : AmityIcon.flagIcon.getImageResource(), text: isSelectedUserReported ? AmityLocalizedStringSet.Social.unreportUser.localizedString : AmityLocalizedStringSet.Social.reportUser.localizedString)
                .onTapGesture {
                    showBottomSheet.isShown.toggle()
                    
                    AmityUserAction.perform(host: host) {
                        Task { @MainActor in
                            if isSelectedUserReported {
                                do {
                                    try await viewModel.unflaguser(userId: showBottomSheet.userId)
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.userUnreportedToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.userUnreportFailedToast.localizedString)
                                }
        
                            } else {
                                do {
                                    try await viewModel.flagUser(userId: showBottomSheet.userId)
                                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.userReportedToast.localizedString)
                                } catch {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.userReportFailedToast.localizedString)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    Task { @MainActor in
                        isSelectedUserReported = try await viewModel.flaggedByMe(userId: showBottomSheet.userId)
                    }
                }
            
            BottomSheetItemView(icon: AmityIcon.blockUserIcon.getImageResource(), text: AmityLocalizedStringSet.Social.blockUser.localizedString)
                .onTapGesture {
                    showBottomSheet.isShown.toggle()
                    
                    AmityUserAction.perform(host: host) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showAlert(title: AmityLocalizedStringSet.Social.userBlockTitle.localizedString, message: String(format: AmityLocalizedStringSet.Social.userBlockMessageFormat.localizedString, showBottomSheet.displayName), btnTitle: AmityLocalizedStringSet.Social.block.localizedString, btnAction: {
                                Task { @MainActor in
                                    do {
                                        try await viewModel.block(userId: showBottomSheet.userId)
                                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.userBlockedToast.localizedString)
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.userBlockFailedToast.localizedString)
                                    }
                                }
                            })

                        }
                    }
                }
        }
        .padding(.bottom, 32)
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityUserRelationshipPageBehavior.Context(page: self, userId: userId)
        AmityUIKitManagerInternal.shared.behavior.userRelationshipPageBehavior?.goToUserProfilePage(context: context)
    }
    
    private func showAlert(title: String, message: String, btnTitle: String, btnAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel)
        let btnAction = UIAlertAction(title: btnTitle, style: .destructive) { _ in
            btnAction()
        }
        alert.addAction(cancelAction)
        alert.addAction(btnAction)
        
        host.controller?.present(alert, animated: true)
    }
}
