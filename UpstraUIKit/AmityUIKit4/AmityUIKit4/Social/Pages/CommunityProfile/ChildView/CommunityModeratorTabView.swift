//
//  CommunityModeratorTabView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import SwiftUI
import AmitySDK
import Combine

struct CommunityModeratorTabView: View {
    @ObservedObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: CommunityModeratorTabViewModel
    private let onTapAction: (AmityCommunityMember) -> Void
    
    init(viewConfig: AmityViewConfigController, community: AmityCommunity, onTapAction: @escaping (AmityCommunityMember) -> Void) {
        self.viewConfig = viewConfig
        self._viewModel = StateObject(wrappedValue: CommunityModeratorTabViewModel(community: community))
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.loadingStatus == .loading {
                        ForEach(0..<10, id: \.self) { _ in
                            UserCellSkeletonView()
                                .padding([.leading, .trailing], 16)
                                .environmentObject(viewConfig)
                        }
                    } else {
                        ForEach(Array(viewModel.communityMembers.enumerated()), id: \.element.userId) { index, communityMember in
                            CommunityMemberView(communityMember, isModerator: true, onTapAction: onTapAction)
                                .padding([.leading, .trailing], 16)
                                .onAppear {
                                    if index == viewModel.communityMembers.count - 1 {
                                        viewModel.loadMoreMembers()
                                    }
                                }
                        }
                    }
                }
            }
        }
        .environmentObject(viewConfig)
    }
}

class CommunityModeratorTabViewModel: ObservableObject {
    @Published var communityMembers: [AmityCommunityMember] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    
    private var cancellable: AnyCancellable?
    private var loadingStatusCancellable: AnyCancellable?
    private let community: AmityCommunity
    private var memberCollection: AmityCollection<AmityCommunityMember>?
    
    init(community: AmityCommunity) {
        self.community = community
        
        getModerators()
    }
    
    private func getModerators() {
        memberCollection = nil
        cancellable = nil
        memberCollection = community.membership.getMembers(filter: .member, roles: [AmityCommunityRole.communityModerator.rawValue], sortBy: .lastCreated)
        cancellable = memberCollection?.$snapshots
            .sink(receiveValue: { [weak self] members in
                self?.communityMembers = members
            })
        
        loadingStatusCancellable = memberCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
    
    func loadMoreMembers() {
        guard let memberCollection, memberCollection.hasNext else { return }
        memberCollection.nextPage()
    }
}
