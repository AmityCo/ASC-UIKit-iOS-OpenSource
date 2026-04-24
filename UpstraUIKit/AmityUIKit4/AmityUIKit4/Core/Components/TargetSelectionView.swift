//
//  TargetSelectionView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/7/24.
//

import SwiftUI
import Combine
import AmitySDK

struct TargetSelectionView<Content: View>: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: TargetSelectionViewModel
    private let headerView: () -> Content
    private let communityOnTapAction: ((AmityCommunityModel) -> Void)?
    
    init(
        @ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
        communityOnTapAction: ((AmityCommunityModel) -> Void)? = nil,
        contentType: PostMenuType,
        viewModel: TargetSelectionViewModel? = nil
    ) {
        self.headerView = headerView
        self.communityOnTapAction = communityOnTapAction
        
        if let viewModel {
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            self._viewModel = StateObject(wrappedValue: TargetSelectionViewModel(contentType: contentType))
        }
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewReader in
                ScrollView {
                    headerView()
                    
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Text("My Communities")
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                            .padding([.leading, .top], 16)
                            .padding(.bottom, 8)
                        
                        ForEach(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                            Section {
                                HStack(spacing: 0) {
                                    AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: URL(string: community.avatarURL))
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
                                    
                                    if !community.isPublic {
                                        let lockIcon = AmityIcon.getImageResource(named: "lockBlackIcon")
                                        Image(lockIcon)
                                            .frame(width: 20, height: 20)
                                            .offset(x: -2, y: -1)
                                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                                    }
                                    
                                    Text(community.displayName)
                                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                                        .lineLimit(1)
                                    
                                    if community.isOfficial {
                                        let verifiedBadgeIcon = AmityIcon.verifiedBadge.imageResource
                                        Image(verifiedBadgeIcon)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 16, height: 16)
                                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
                                            .padding(.leading, 4)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                communityOnTapAction?(community)
                            }
                            .onAppear {
                                if index == viewModel.communities.count - 1 {
                                    viewModel.loadMore()
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
}


class TargetSelectionViewModel: ObservableObject {
    @Published var communities: [AmityCommunityModel] = []
    private var communityCollection: AmityCollection<AmityCommunity>?
    private var cancellable: AnyCancellable?
    
    private let communityRepository = AmityCommunityRepository()
    
    init(contentType: PostMenuType) {
        let queryOptions = AmityCommunityQueryOptions(filter: .userIsMember, sortBy: .displayName, includeDeleted: false)
        communityCollection = communityRepository.getCommunities(with: queryOptions)
        
        cancellable = communityCollection?.$snapshots
            .sink(receiveValue: { communities in
                Task { @MainActor in
                    let filteredCommunities = await self.processCommunities(communities, contentType: contentType)
                    self.communities = filteredCommunities
                }
            })
    }
    
    func loadMore() {
        guard let collection = communityCollection, collection.hasNext else { return }
        collection.nextPage()
    }
    
    func processCommunities(_ communities: [AmityCommunity], contentType: PostMenuType) async -> [AmityCommunityModel] {
        var filteredCommunities: [AmityCommunityModel] = []
        
        for community in communities {
            let communityModel = AmityCommunityModel(object: community)
            
            if contentType == .story {
                let canManageStory = await AmityUIKit4Manager.client.hasPermission(.manageStoryCommunity, forCommunity: community.communityId)
                
                let canCreateStory = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
                let hasManageStoryPermission = (canCreateStory || canManageStory) && communityModel.isJoined

                if hasManageStoryPermission {
                    filteredCommunities.append(communityModel)
                }
                
                continue
            }
            
            if community.onlyAdminCanPost {
                let hasCreatePermission = await AmityUIKit4Manager.client.hasPermission(.createPrivilegedPost, forCommunity: community.communityId)
                if hasCreatePermission {
                    filteredCommunities.append(communityModel)
                }
            } else {
                filteredCommunities.append(communityModel)
            }
        }
        
        return filteredCommunities
    }
}
