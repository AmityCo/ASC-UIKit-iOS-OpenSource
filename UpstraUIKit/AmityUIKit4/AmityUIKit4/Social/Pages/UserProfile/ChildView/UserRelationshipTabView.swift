//
//  UserRelationshipTabView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/24/24.
//

import SwiftUI
import AmitySDK
import Combine

enum UserRelationshipTabViewType {
    case following, follower
}

struct UserRelationshipTabView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: UserRelationshipTabViewModel
    private let onTapAction: (AmityUser) -> Void
    private let menuButtonAction: (AmityUser) -> Void
    
    init(type: UserRelationshipTabViewType, userId: String, onTapAction: @escaping (AmityUser) -> Void, menuButtonAction: @escaping (AmityUser) -> Void) {
        self.onTapAction = onTapAction
        self.menuButtonAction = menuButtonAction
        self._viewModel = StateObject(wrappedValue: UserRelationshipTabViewModel(type: type, userId: userId))
    }
    
    var body: some View {
        ZStack {
            emptyView
                .isHidden(!viewModel.users.isEmpty)
            
            userListView
                .isHidden(viewModel.users.isEmpty)
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack {
            Spacer()
            
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
            .padding(.bottom, 50)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.loadingStatus == .loading {
                    ForEach(0..<10, id: \.self) { _ in
                        UserCellSkeletonView()
                            .padding([.leading, .trailing], 16)
                            .environmentObject(viewConfig)
                    }
                } else {
                    ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                        UserCellView(user: user, menuButtonAction: menuButtonAction)
                            .padding([.leading, .trailing], 16)
                            .onTapGesture {
                                onTapAction(user)
                            }
                            .onAppear {
                                if index == viewModel.users.count - 1 {
                                    viewModel.loadMoreUsers()
                                }
                            }
                    }
                }
            }
        }
    }
}


class UserRelationshipTabViewModel: ObservableObject {
    @Published var users: [AmityUser] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    
    private var cancellable: AnyCancellable?
    private var userCollection: AmityCollection<AmityFollowRelationship>
    private var loadingStatusCancellable: AnyCancellable?
    private let userManger = UserManager()
    
    init(type: UserRelationshipTabViewType, userId: String) {
        if userId == AmityUIKitManagerInternal.shared.currentUserId {
            self.userCollection = type == .following ? userManger.getMyFollowings(.accepted) : userManger.getMyFollowers(.accepted)
        } else {
            self.userCollection = type == .following ? userManger.getUserFollowings(withId: userId) : userManger.getUserFollowers(withId: userId)
        }
        
        self.cancellable = userCollection.$snapshots
            .sink(receiveValue: { [weak self] followRelationships in
                self?.users = followRelationships.compactMap {
                    type == .following ? $0.targetUser : $0.sourceUser
                }
            })
        
        self.loadingStatusCancellable = userCollection.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
    
    func loadMoreUsers() {
        guard userCollection.hasNext else { return }
        userCollection.nextPage()
    }
}

