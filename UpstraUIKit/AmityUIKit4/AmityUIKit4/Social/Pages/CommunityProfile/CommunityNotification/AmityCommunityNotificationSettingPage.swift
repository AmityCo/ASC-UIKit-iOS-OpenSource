//
//  AmityCommunityNotificationSettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/26/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityNotificationSettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityNotificationSettingPageViewModel
    private let community: AmityCommunity
    
    public var id: PageId {
        .communityNotificationSettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityNotificationSettingPage))
        self._viewModel = StateObject(wrappedValue: AmityCommunityNotificationSettingPageViewModel(community))
        self.community = community
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            navigationBarView
                .padding([.top, .bottom], 16)
            
            SettingToggleButtonView(isEnabled: $viewModel.isNotificationEnabled, title: AmityLocalizedStringSet.Social.communityNotificationSettingTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingDescription.localizedString)
                .onChange(of: viewModel.isNotificationEnabled) { _ in
                    viewModel.updateSetting()
                }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
            
            if viewModel.isNotificationEnabled {
                getNotificationModulesView()
            }
            
            Spacer()
        }
        .padding([.leading, .trailing], 16)
        .environmentObject(viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private func getNotificationModulesView() -> some View {
        if viewModel.isPostNetworkNotificationEnabled {
            getItemView(AmityIcon.postMenuIcon.getImageResource(), text: AmityLocalizedStringSet.Social.communityNotificationSettingPosts.localizedString)
                .onTapGesture {
                    let context = AmityCommunityNotificationSettingPageBehavior.Context(page: self, community: community)
                    AmityUIKitManagerInternal.shared.behavior.communityNotificationSettingPageBehavior?.goToPostsNotificationSettingPage(context)
                }
        }
        
        if viewModel.isCommentNetworkNotificationEnabled {
            getItemView(AmityIcon.commentMenuIcon.getImageResource(), text: AmityLocalizedStringSet.Social.communityNotificationSettingComments.localizedString)
                .onTapGesture {
                    let context = AmityCommunityNotificationSettingPageBehavior.Context(page: self, community: community)
                    AmityUIKitManagerInternal.shared.behavior.communityNotificationSettingPageBehavior?.goToCommentsNotificationSettingPage(context)
                }
        }
        
        if viewModel.isStoryNetworkNotificaitonEnabled {
            getItemView(AmityIcon.createStoryMenuIcon.getImageResource(), text: AmityLocalizedStringSet.Social.communityNotificationSettingStories.localizedString)
                .onTapGesture {
                    let context = AmityCommunityNotificationSettingPageBehavior.Context(page: self, community: community)
                    AmityUIKitManagerInternal.shared.behavior.communityNotificationSettingPageBehavior?.goToStoriesNotificationSettingPage(context)
                }
        }
    }
    
    @ViewBuilder
    private func getItemView(_ icon: ImageResource, text: String) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 20)
            
            Text(text)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
           
            Image(AmityIcon.arrowIcon.getImageResource())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        }
        .contentShape(Rectangle())
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
            
            Text(AmityLocalizedStringSet.Social.communityNotificationSettingPageTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 20)
        }
    }
    
}

@MainActor
class AmityCommunityNotificationSettingPageViewModel: ObservableObject {
    @Published var isNotificationEnabled: Bool = false
    @Published var isPostNetworkNotificationEnabled: Bool = false
    @Published var isCommentNetworkNotificationEnabled: Bool = false
    @Published var isStoryNetworkNotificaitonEnabled: Bool = false
    
    private let community: AmityCommunity
    private let notificationManger = NotificationManager()
    
    init(_ community: AmityCommunity) {
        self.community = community
        Task {
            try await isSocialNetworkEnabled()
        }
    }
    
    func updateSetting() {
        Task {
            if isNotificationEnabled {
                try? await notificationManger.enableNotificationSetting(withId: community.communityId, events: [])
            } else {
                try? await notificationManger.disableNotificationSetting(withId: community.communityId)
            }
            
            try await self.isSocialNetworkEnabled()
        }
    }
    
    private func isSocialNetworkEnabled() async throws {
        do {
            let settings = try await notificationManger.getCommunityNotificationSetting(withId: community.communityId)
            updateState(settings: settings)
        } catch {
            updateState(settings: nil)
        }
    }
    
    func updateState(settings: AmityCommunityNotificationSettings?) {
        self.isNotificationEnabled = settings?.isEnabled ?? false
        self.isPostNetworkNotificationEnabled = settings?.isPostNetworkEnabled ?? false
        self.isCommentNetworkNotificationEnabled = settings?.isCommentNetworkEnabled ?? false
        self.isStoryNetworkNotificaitonEnabled = settings?.isStoryNetworkEnabled ?? false
    }
}
