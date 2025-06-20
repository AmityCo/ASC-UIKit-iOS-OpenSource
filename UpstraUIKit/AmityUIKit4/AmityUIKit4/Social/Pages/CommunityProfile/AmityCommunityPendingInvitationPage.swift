//
//  AmityCommunityPendingInvitationPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/25.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityPendingInvitationPage: AmityPageView {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .communityPendingInvitationPage
    }
    
    private let community: AmityCommunity
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityPendingInvitationPageViewModel
    
    public init(community: AmityCommunity) {
        self.community = community
        self._viewModel = StateObject(wrappedValue: AmityCommunityPendingInvitationPageViewModel(community))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityPendingInvitationPage))
    }
    
    public var body: some View {
        ZStack {
            VStack {
                navigationBarView
                    .padding(.vertical, 8)
                
                ScrollView {
                    LazyVStack(spacing: 16, content: {
                        if viewModel.loadingStatus == .loading {
                            ForEach(0..<10, id: \.self) { _ in
                                UserCellSkeletonView()
                                    .environmentObject(viewConfig)
                            }
                        } else {
                            ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                                getUserView(user)
                                    .onTapGesture {
                                        goToUserProfilePage(userId: user.userId)
                                    }
                                    .onAppear {
                                        if index == viewModel.users.count - 1 {
                                            viewModel.loadMoreUsers()
                                        }
                                    }
                            }
                        }
                    })
                }
                .padding(.leading, 16)
                
                Spacer()
            }
            
            if viewModel.users.isEmpty {
                emptyView
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    private var navigationBarView: some View {
        AmityNavigationBar(title: "Pending invitations", showBackButton: true)
    }
    
    private func getUserView(_ user: AmityUserModel) -> some View {
        ZStack {
            HStack(spacing: 12) {
                AmityUserProfileImageView(displayName: user.displayName, avatarURL: URL(string: user.avatarURL))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                Text(user.displayName)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
                
                if user.isBrand {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .padding(.leading, -6)
                }
                
                Spacer()
            }
            
            Color.clear // Invisible overlay for tap event
                .contentShape(Rectangle())
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 0) {
            Image(AmityIcon.listRadioIcon.getImageResource())
                .renderingMode(.template)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .padding(.top, 24)
            
            Text("Nothing here to see yet")
                .applyTextStyle(.title(Color(viewConfig.theme.baseColorShade3)))
                .padding(.top, 8)
                .padding(.bottom, 24)
            
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    private func goToUserProfilePage(userId: String) {
        let page = AmityUserProfilePage(userId: userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

class AmityCommunityPendingInvitationPageViewModel: ObservableObject {
    @Published var users: [AmityUserModel] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    private let community: AmityCommunity
    
    private let userManager = UserManager()
    private var invitationCollection: AmityCollection<AmityInvitation>?
    private var invitationCancellable: AnyCancellable?
    private var loadingStatusCancellable: AnyCancellable?
    
    init(_ community: AmityCommunity) {
        self.community = community
        getPendingMembers()
    }
    
    private func getPendingMembers() {
        invitationCollection = community.getMemberInvitations()
        invitationCancellable = invitationCollection?.$snapshots
            .sink(receiveValue: { [weak self] invitations in
                self?.users = invitations.compactMap {
                    if let user = $0.invitedUser {
                        return AmityUserModel(user: user)
                    }
                    return nil
                }
            })
        
        loadingStatusCancellable = invitationCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
    
    func loadMoreUsers() {
        guard let invitationCollection, invitationCollection.hasNext else { return }
        invitationCollection.nextPage()
    }
}

