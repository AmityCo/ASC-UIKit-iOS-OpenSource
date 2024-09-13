//
//  AmityCommunityStoriesNotificationSettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/28/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityStoriesNotificationSettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityStoriesNotificationSettingPageViewModel
    
    public var id: PageId {
        .communityCommentsNotificationSettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPostsNotificationSettingPage))
        self._viewModel = StateObject(wrappedValue: AmityCommunityStoriesNotificationSettingPageViewModel(community))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            navigationBarView
                .padding(.all, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.orginalSettings[.storyCreated] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingStoryCreationTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingStoryCreationDescription.localizedString, selectedSetting: $viewModel.storyCreationNotificationSetting)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    }
                    
                    if viewModel.orginalSettings[.storyReacted] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingStoryReactionTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingStoryReactionDescription.localizedString, selectedSetting: $viewModel.storyReactionNotificaitonSetting)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    }
                    
                    if viewModel.orginalSettings[.storyCommentCreated] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingStoryCommentTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingStoryCommentDescription.localizedString, selectedSetting: $viewModel.storyCommentCreationNotificaitonSetting)
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
            
            Text(AmityLocalizedStringSet.Social.communityNotificationSettingStories.localizedString)
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
                        if error != nil {
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

class AmityCommunityStoriesNotificationSettingPageViewModel: ObservableObject {
    @Published var storyCreationNotificationSetting: CommunityNotificationSettingOption = .everyone
    @Published var storyReactionNotificaitonSetting: CommunityNotificationSettingOption = .everyone
    @Published var storyCommentCreationNotificaitonSetting: CommunityNotificationSettingOption = .everyone
    
    @Published var isSettingChanged: Bool = false
    private var cancellable: AnyCancellable?
    
    private(set) var orginalSettings: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
    private let community: AmityCommunity
    private let notificaitonManager = NotificationManager()
    
    init(_ community: AmityCommunity) {
        self.community = community
        getPostNotificationSettings()
        
        cancellable = $storyCreationNotificationSetting
            .combineLatest($storyReactionNotificaitonSetting, $storyCommentCreationNotificaitonSetting)
            .sink(receiveValue: { [weak self] creation, reaction, comment in
                self?.isSettingChanged = self?.orginalSettings[.storyCreated] != creation || self?.orginalSettings[.storyReacted] != reaction || self?.orginalSettings[.storyCommentCreated] != comment
            })
    }
    
    
    func updateSettings(_ completion: @escaping (Bool, AmityError?) -> Void) {
        var updatedSetting: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
        updatedSetting[.storyCreated] = storyCreationNotificationSetting
        updatedSetting[.storyReacted] = storyReactionNotificaitonSetting
        updatedSetting[.storyCommentCreated] = storyCommentCreationNotificaitonSetting
        
        let events = updatedSetting.mapToNotificationEvents()
        
        notificaitonManager.enableNotificaitonSetting(withId: community.communityId, events: events) { status, error in
            completion(status, error)
        }
    }
    
    func getPostNotificationSettings() {
        notificaitonManager.getCommunityNotificationSetting(withId: community.communityId) { [weak self] settings, error in
            if error != nil {
                self?.orginalSettings = [:]
                return
            }
            
            if let settings {
                self?.orginalSettings = settings.mapToSettingOptionMap()
            }
            
            self?.storyCreationNotificationSetting = self?.orginalSettings[.storyCreated] ?? .everyone
            self?.storyReactionNotificaitonSetting = self?.orginalSettings[.storyReacted] ?? .everyone
            self?.storyCommentCreationNotificaitonSetting = self?.orginalSettings[.storyCommentCreated] ?? .everyone
        }
    }
}
