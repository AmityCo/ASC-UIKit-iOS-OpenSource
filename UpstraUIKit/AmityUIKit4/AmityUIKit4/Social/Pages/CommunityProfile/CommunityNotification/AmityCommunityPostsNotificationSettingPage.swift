//
//  AmityCommunityPostsNotificationSettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/27/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityPostsNotificationSettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var postReactionSetting: CommunityNotificationSettingOption = .everyone
    @State private var postCreationSetting: CommunityNotificationSettingOption = .everyone
    @StateObject private var viewModel: AmityCommunityPostsNotificationSettingsPageViewModel
    
    public var id: PageId {
        .communityPostsNotificationSettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPostsNotificationSettingPage))
        self._viewModel = StateObject(wrappedValue: AmityCommunityPostsNotificationSettingsPageViewModel(community))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            navigationBarView
                .padding(.all, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.orginalSettings[.postReacted] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingPostReactionTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingPostReactionDescription.localizedString, selectedSetting: $viewModel.postReactionNotificationSetting)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    }
                    
                    if viewModel.orginalSettings[.postCreated] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingPostCreationTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingPostCreationDescription.localizedString, selectedSetting: $viewModel.postCreationNotificaitonSetting)
                    }
                }
                .padding([.leading, .trailing], 16)
            }
        }
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
            
            Text(AmityLocalizedStringSet.Social.communityNotificationSettingPosts.localizedString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Text(AmityLocalizedStringSet.General.save.localizedString)
                .font(.system(size: 17))
                .foregroundColor(Color(viewConfig.theme.primaryColor))
                .opacity(viewModel.isSettingChanged ? 1.0 : 0.35)
                .onTapGesture {
                    guard viewModel.isSettingChanged else { return }
                    viewModel.updateSettings { status, error in
                        if let error {
                            Toast.showToast(style: .success, message: "Failed to update community profile!")
                            return
                        }
                        
                        Toast.showToast(style: .success, message: "Successfully updated community profile!")
                        if let navigationController = host.controller?.navigationController, navigationController.viewControllers.count > 2 {
                            navigationController.popToViewController(navigationController.viewControllers[1], animated: true)
                        }
                    }
                }
        }
    }
}


class AmityCommunityPostsNotificationSettingsPageViewModel: ObservableObject {
    @Published var postReactionNotificationSetting: CommunityNotificationSettingOption = .everyone
    @Published var postCreationNotificaitonSetting: CommunityNotificationSettingOption = .everyone
    @Published var isSettingChanged: Bool = false
    private var cancellable: AnyCancellable?
    
    private(set) var orginalSettings: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
    private let community: AmityCommunity
    private let notificaitonManager = NotificationManager()
    
    init(_ community: AmityCommunity) {
        self.community = community
        getPostNotificationSettings()
        
        cancellable = $postReactionNotificationSetting
            .combineLatest($postCreationNotificaitonSetting)
            .sink(receiveValue: { [weak self] reaction, creation in
                self?.isSettingChanged = self?.orginalSettings[.postReacted] != reaction || self?.orginalSettings[.postCreated] != creation
            })
    }
    
    
    func updateSettings(_ completion: @escaping (Bool, AmityError?) -> Void) {
        var updatedSetting: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
        updatedSetting[.postReacted] = postReactionNotificationSetting
        updatedSetting[.postCreated] = postCreationNotificaitonSetting
        
        let events = updatedSetting.mapToNotificationEvents()
        
        notificaitonManager.enableNotificaitonSetting(withId: community.communityId, events: events) { status, error in
            completion(status, error)
        }
    }
    
    func getPostNotificationSettings() {
        notificaitonManager.getCommunityNotificationSetting(withId: community.communityId) { [weak self] settings, error in
            if let error {
                self?.orginalSettings = [:]
                return
            }
            
            if let settings {
                self?.orginalSettings = settings.mapToSettingOptionMap()
            }
            
            self?.postReactionNotificationSetting = self?.orginalSettings[.postReacted] ?? .everyone
            self?.postCreationNotificaitonSetting = self?.orginalSettings[.postCreated] ?? .everyone
        }
    }
}

