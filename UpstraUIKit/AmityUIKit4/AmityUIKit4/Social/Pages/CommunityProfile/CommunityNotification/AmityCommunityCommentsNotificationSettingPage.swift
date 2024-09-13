//
//  AmityCommunityCommentsNotificationSettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/28/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityCommentsNotificationSettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityCommentsNotificationSettingPageViewModel
    
    public var id: PageId {
        .communityCommentsNotificationSettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPostsNotificationSettingPage))
        self._viewModel = StateObject(wrappedValue: AmityCommunityCommentsNotificationSettingPageViewModel(community))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            navigationBarView
                .padding(.all, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.orginalSettings[.commentReacted] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingCommentReactionTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingCommentReactionDescription.localizedString, selectedSetting: $viewModel.commentReactionNotificationSetting)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    }
                    
                    if viewModel.orginalSettings[.commentCreated] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingCommentCreationTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingCommentCreationDescription.localizedString, selectedSetting: $viewModel.commentCreationNotificaitonSetting)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    }
                    
                    if viewModel.orginalSettings[.commentReplied] != nil {
                        CommunityNotificationSettingView(title: AmityLocalizedStringSet.Social.communityNotificationSettingCommentReplyTitle.localizedString, description: AmityLocalizedStringSet.Social.communityNotificationSettingCommentReplyDescription.localizedString, selectedSetting: $viewModel.commentReplyNotificaitonSetting)
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
            
            Text(AmityLocalizedStringSet.Social.communityNotificationSettingComments.localizedString)
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

class AmityCommunityCommentsNotificationSettingPageViewModel: ObservableObject {
    @Published var commentReactionNotificationSetting: CommunityNotificationSettingOption = .everyone
    @Published var commentCreationNotificaitonSetting: CommunityNotificationSettingOption = .everyone
    @Published var commentReplyNotificaitonSetting: CommunityNotificationSettingOption = .everyone
    
    @Published var isSettingChanged: Bool = false
    private var cancellable: AnyCancellable?
    
    private(set) var orginalSettings: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
    private let community: AmityCommunity
    private let notificaitonManager = NotificationManager()
    
    init(_ community: AmityCommunity) {
        self.community = community
        getPostNotificationSettings()
        
        cancellable = $commentReactionNotificationSetting
            .combineLatest($commentCreationNotificaitonSetting, $commentReplyNotificaitonSetting)
            .sink(receiveValue: { [weak self] reaction, creation, reply in
                self?.isSettingChanged = self?.orginalSettings[.commentReacted] != reaction || self?.orginalSettings[.commentCreated] != creation || self?.orginalSettings[.commentReplied] != reply
            })
    }
    
    
    func updateSettings(_ completion: @escaping (Bool, AmityError?) -> Void) {
        var updatedSetting: [AmityCommunityNotificationEventType : CommunityNotificationSettingOption] = [:]
        updatedSetting[.commentReacted] = commentReactionNotificationSetting
        updatedSetting[.commentCreated] = commentCreationNotificaitonSetting
        updatedSetting[.commentReplied] = commentReplyNotificaitonSetting
        
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
            
            self?.commentReactionNotificationSetting = self?.orginalSettings[.commentReacted] ?? .everyone
            self?.commentCreationNotificaitonSetting = self?.orginalSettings[.commentCreated] ?? .everyone
            self?.commentReplyNotificaitonSetting = self?.orginalSettings[.commentReplied] ?? .everyone
        }
    }
}


