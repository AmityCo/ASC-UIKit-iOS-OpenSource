//
//  AmityCommunityPostPermissionPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/26/24.
//

import SwiftUI
import AmitySDK

public struct AmityCommunityPostPermissionPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityPostPermissionPageViewModel
    private let community: AmityCommunity
    
    public var id: PageId {
        .communityPostPermissionPage
    }
    
    public init(community: AmityCommunity) {
        self.community = community
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPostPermissionPage))
        self._viewModel = StateObject(wrappedValue: AmityCommunityPostPermissionPageViewModel(community: community))
    }
    
    public var body: some View {
        VStack(spacing: 28) {
            navigationBarView
                .padding([.top, .bottom], 16)
            
            getSettingView()
            
            Spacer()
        }
        .padding([.leading, .trailing], 16)
        .environmentObject(viewConfig)
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
            
            Text(AmityLocalizedStringSet.Social.communitySettingPostPermissions.localizedString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Text(AmityLocalizedStringSet.General.save.localizedString)
                .font(.system(size: 17))
                .foregroundColor(Color(viewConfig.theme.primaryColor))
                .opacity(community.postSettings == viewModel.selectedSetting ? 0.35 : 1.0)
                .onTapGesture {
                    guard community.postSettings != viewModel.selectedSetting else { return }
                    Task { @MainActor in
                        do {
                            try await viewModel.updateSetting()
                            Toast.showToast(style: .success, message: "Successfully updated community profile!")
                            if let navigationController = host.controller?.navigationController, navigationController.viewControllers.count > 2 {
                                navigationController.popToViewController(navigationController.viewControllers[1], animated: true)
                            }
                        } catch {
                            Toast.showToast(style: .success, message: "Failed to update community profile!")
                        }
                    }
                }
        }
    }
    
    
    private func getSettingView() -> some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(AmityLocalizedStringSet.Social.communityPostPermissionTitle.localizedString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                
                Text(AmityLocalizedStringSet.Social.communityPostPermissionDescription.localizedString)
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 20)
            }
            
            SettingRadioButtonView(isSelected: viewModel.selectedSetting == .anyoneCanPost, text: AmityLocalizedStringSet.Social.communityPostPermissionEveryoneCanPostSetting.localizedString)
                .onTapGesture {
                    viewModel.selectedSetting = .anyoneCanPost
                }
            
            SettingRadioButtonView(isSelected: viewModel.selectedSetting == .adminReviewPostRequired, text: AmityLocalizedStringSet.Social.communityPostPermissionAdminReviewSetting.localizedString)
                .onTapGesture {
                    viewModel.selectedSetting = .adminReviewPostRequired
                }
            
            SettingRadioButtonView(isSelected: viewModel.selectedSetting == .onlyAdminCanPost, text: AmityLocalizedStringSet.Social.communityPostPermissionOnlyAdminCanPostSetting.localizedString)
                .onTapGesture {
                    viewModel.selectedSetting = .onlyAdminCanPost
                }
        
        }
    }
}


class AmityCommunityPostPermissionPageViewModel: ObservableObject {
    @Published var selectedSetting: AmityCommunityPostSettings
    private let communityManager = CommunityManager()
    private let community: AmityCommunity
    
    init(community: AmityCommunity) {
        self.community = community
        self.selectedSetting = community.postSettings
    }
    
    @discardableResult
    func updateSetting() async throws -> AmityCommunity {
        let updateOptions = AmityCommunityUpdateOptions()
        updateOptions.setPostSettings(selectedSetting)
        
        return try await communityManager.editCommunity(withId: community.communityId, updateOptions: updateOptions)
    }
}
