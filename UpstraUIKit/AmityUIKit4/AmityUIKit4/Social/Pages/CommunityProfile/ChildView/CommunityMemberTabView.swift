//
//  CommunityMemberTabView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import SwiftUI
import AmitySDK
import Combine

struct CommunityMemberTabView: View {
    @ObservedObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: CommunityMemberTabViewModel
    private let onTapAction: (AmityCommunityMember) -> Void
    
    init(viewConfig: AmityViewConfigController, community: AmityCommunity, onTapAction: @escaping (AmityCommunityMember) -> Void) {
        self.viewConfig = viewConfig
        self._viewModel = StateObject(wrappedValue: CommunityMemberTabViewModel(community: community))
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        VStack(spacing: 12) {
            searchMemberView
                .padding([.leading, .trailing], 16)
            
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
                            CommunityMemberView(communityMember, isModerator: false, onTapAction: onTapAction)
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
    
    private var searchMemberView: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.searchIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 20, height: 16)
                .padding(.leading, 12)
            
            TextField("Search member", text: $viewModel.searchKeyword)
                .font(.system(size: 15.0))
        }
        .frame(height: 40)
        .background(Color(viewConfig.theme.baseColorShade4))
        .clipShape(RoundedCorner(radius: 8))
    }
}


class CommunityMemberTabViewModel: ObservableObject {
    @Published var searchKeyword: String = ""
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    @Published var communityMembers: [AmityCommunityMember] = []
    
    private var searchKeywordCancellable: AnyCancellable?
    private var cancellable: AnyCancellable?
    private var loadingStatusCancellable: AnyCancellable?
    private let community: AmityCommunity
    private var memberCollection: AmityCollection<AmityCommunityMember>?
    
    init(community: AmityCommunity) {
        self.community = community
        
        searchKeywordCancellable = $searchKeyword
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] str in
                self?.searchMembers(str)
            })
    }
    
    private func searchMembers(_ keyword: String) {
        memberCollection = nil
        cancellable = nil
        
        if keyword.isEmpty {
            memberCollection = community.membership.getMembers(filter: .member, roles: [], sortBy: .lastCreated)
        } else {
            memberCollection = community.membership.searchMembers(keyword: keyword, filter: [.member], roles: [], sortBy: .displayName)
        }
        
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
