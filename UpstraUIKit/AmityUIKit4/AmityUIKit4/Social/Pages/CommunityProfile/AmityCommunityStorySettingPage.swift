//
//  AmityCommunityStorySettingPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/26/24.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityStorySettingPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityStorySettingPageViewModel
    private let community: AmityCommunity
    
    public var id: PageId {
        .communityStorySettingPage
    }
    
    public init(community: AmityCommunity) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityStorySettingPage))
        self.community = community
        self._viewModel = StateObject(wrappedValue: AmityCommunityStorySettingPageViewModel(community: community))
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            navigationBarView
                .padding([.top, .bottom], 16)
            
            SettingToggleButtonView(isEnabled: $viewModel.isCommentAllowed, title: AmityLocalizedStringSet.Social.communityStorySettingTitle.localizedString, description: AmityLocalizedStringSet.Social.communityStorySettingDescription.localizedString)
                .onChange(of: viewModel.isCommentAllowed) { _ in
                    Task { @MainActor in
                        do {
                            try await viewModel.updateSetting()
                        } catch {
                            Log.add(event: .error, error.localizedDescription)
                        }
                    }
                }
            
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
            
            Text(AmityLocalizedStringSet.Social.communitySettingStoryComments.localizedString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 20)
        }
    }
}


class AmityCommunityStorySettingPageViewModel: ObservableObject {
    @Published var isCommentAllowed: Bool = false
    private let communityManager = CommunityManager()
    private var community: AmityCommunity?
    private var cancellable: AnyCancellable?
    private var communityObject: AmityObject<AmityCommunity>?
    
    init(community: AmityCommunity) {
        self.observeDataChanges(community)
    }
    
    
    private func observeDataChanges(_ community: AmityCommunity?) {
        guard let community else { return }
        
        self.communityObject = communityManager.getCommunity(withId: community.communityId)
        self.cancellable = self.communityObject?.$snapshot
            .sink(receiveValue: { [weak self] community in
                self?.setupData(community)
            })
    }
    
    private func setupData(_ community: AmityCommunity?) {
        guard let community else { return }
        
        self.community = community
        self.isCommentAllowed = community.storySettings.allowComment
    }
    
    func updateSetting() async throws {
        guard let community else { return }
        
        let updateOptions = AmityCommunityUpdateOptions()
        updateOptions.setStorySettings(allowComment: isCommentAllowed)
        try await communityManager.editCommunity(withId: community.communityId, updateOptions: updateOptions)
    }
}
