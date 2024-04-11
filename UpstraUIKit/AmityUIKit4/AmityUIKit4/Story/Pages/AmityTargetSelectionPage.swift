//
//  AmityTargetSelectionPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 4/2/24.
//

import SwiftUI
import AmitySDK
import Combine

public enum AmityTargetSelectionPageType {
    case post
    case poll
    case livestream
    case story
}

public struct AmityTargetSelectionPage: AmityPageIdentifiable, View {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @Environment(\.colorScheme) private var colorScheme
    
    public var id: PageId {
        .targetSelectionPage
    }
    
    @StateObject private var viewModel: AmityTargetSelectionPageViewModel = AmityTargetSelectionPageViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    private let contentType: AmityTargetSelectionPageType
    
    public init(type: AmityTargetSelectionPageType) {
        self.contentType = type
        _viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .targetSelectionPage))
    }
    
    public var body: some View {
        VStack {
            HStack {
                Image(AmityIcon.backIcon.getImageResource())
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .padding(.leading, 12)
                    .onTapGesture {
                        if let navigationController = host.controller?.navigationController {
                            navigationController.dismiss(animated: true)
                        } else {
                            host.controller?.dismiss(animated: true)
                        }
                    }
                
                Spacer()
            }
            .overlay(
                Text("Share To")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    
            )
            .frame(height: 58)
            
            ScrollViewReader { scrollViewReader in
                ScrollView {
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
                                    
                                    Spacer()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let context = AmityTargetSelectionPageBehaviour.Context(page: self, community: community.object, targetType: .community)
                                AmityUIKitManagerInternal.shared.behavior.targetSelectionPageBehaviour?.selectTargetAction(context: context)
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
        .onChange(of: colorScheme) { _ in
            viewConfig.updateTheme()
        }
    }
}


class AmityTargetSelectionPageViewModel: ObservableObject {
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
