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
    
    init(@ViewBuilder headerView: @escaping () -> Content = { EmptyView() },
         communityOnTapAction: ((AmityCommunityModel) -> Void)? = nil, contentType: PostMenuType) {
        self.headerView = headerView
        self.communityOnTapAction = communityOnTapAction
        self._viewModel = StateObject(wrappedValue: TargetSelectionViewModel(contentType: contentType))
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
                                            .offset(y: -1)
                                            .isHidden(viewConfig.isHidden(elementId: .communityPrivateBadge))
                                    }
                                    
                                    Text(community.displayName)
                                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                                    
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
    
    init(contentType: PostMenuType) {
        let queryOptions = AmityCommunityQueryOptions(filter: .userIsMember, sortBy: .displayName, includeDeleted: false)
        communityCollection = communityRepository.getCommunities(with: queryOptions)
        
        cancellable = communityCollection?.$snapshots
            .flatMap { communities in
                Publishers.MergeMany(
                    communities.map { community -> AnyPublisher<AmityCommunityModel?, Never> in
                        let communityModel = AmityCommunityModel(object: community)
                        
                        // Story permission specifically need to check without considering onlyAdminCanPost
                        if contentType == .story {
                            return Future<AmityCommunityModel?, Never> { promise in
                                
                                AmityUIKit4Manager.client.hasPermission(.manageStoryCommunity, forCommunity: community.communityId) { success in
                                    let hasPermission = success
                                    let allowAllUserCreation = AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
                                    let hasStoryManagePermission = (allowAllUserCreation || hasPermission) && communityModel.isJoined
                                    
                                    if hasStoryManagePermission {
                                        promise(.success(communityModel))
                                    } else {
                                        promise(.success(nil))
                                    }
                                }
                            }
                            .eraseToAnyPublisher()
                        }
                        
                        // Check for post permission
                        if community.onlyAdminCanPost {
                            return Future<AmityCommunityModel?, Never> { promise in
                                AmityUIKit4Manager.client.hasPermission(.createPrivilegedPost, forCommunity: community.communityId) { success in
                                    if success {
                                        promise(.success(communityModel))
                                    } else {
                                        promise(.success(nil))
                                    }
                                }
                            }
                            .eraseToAnyPublisher()
                        } else {
                            return Just(communityModel).eraseToAnyPublisher()
                        }
                    }
                )
                .collect()
            }
            .compactMap { $0.compactMap { $0 } }
            .assign(to: \.communities, on: self)
    }
    
    func loadMore() {
        guard let collection = communityCollection, collection.hasNext else { return }
        collection.nextPage()
    }
}
