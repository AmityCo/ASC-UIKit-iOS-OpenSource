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
    @StateObject private var viewModel = TargetSelectionViewModel()
    private let headerView: () -> Content
    private let communityOnTapAction: ((AmityCommunityModel) -> Void)?
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         communityOnTapAction: ((AmityCommunityModel) -> Void)? = nil) {
        self.headerView = headerView
        self.communityOnTapAction = communityOnTapAction
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewReader in
                ScrollView {
                    headerView()
                    
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Text("My Communities")
                            .font(.system(size: 15))
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                            .padding([.leading, .top], 16)
                            .padding(.bottom, 8)
                        
                        ForEach(Array(viewModel.communities.enumerated()), id: \.element.communityId) { index, community in
                            Section {
                                HStack(spacing: 0) {
                                    AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: URL(string: community.avatarURL))
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
                                        
                                    
                                    Text(community.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(viewConfig.theme.baseColor))
                                    
                                    if !community.isPublic {
                                        let lockIcon = AmityIcon.getImageResource(named: "lockBlackIcon")
                                        Image(lockIcon)
                                            .frame(width: 20, height: 12)
                                            .offset(y: -1)
                                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                                    }
                                    
                                    if community.isOfficial {
                                        let verifiedBadgeIcon = AmityIcon.getImageResource(named: "verifiedBadge")
                                        Image(verifiedBadgeIcon)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 12, height: 12)
                                            .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
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
    
    private let communityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    
    init() {
        let queryOptions = AmityCommunityQueryOptions(displayName: "", filter: .userIsMember, sortBy: .displayName, includeDeleted: false)
        communityCollection = communityRepository.getCommunities(with: queryOptions)
        cancellable = communityCollection?.$snapshots
            .map { communities -> [AmityCommunityModel] in
                communities.map { community in
                    AmityCommunityModel(object: community)
                }
            }
            .assign(to: \.communities, on: self)
    }
    
    func loadMore() {
        guard let collection = communityCollection, collection.hasNext else { return }
        collection.nextPage()
    }
}
