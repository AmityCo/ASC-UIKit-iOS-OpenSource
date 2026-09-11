//
//  AmityCommunityInviteMemberPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/15/25.
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityCommunityInviteMemberPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .communityInviteMemberPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel = AmityCommunityInviteMemberPageViewModel()
    @State private var selectedUsers: [AmityUserModel] = []
    private let onInvitedAction: ([AmityUserModel]) -> Void
    
    public init(users: [AmityUserModel], onInvitedAction: @escaping ([AmityUserModel]) -> Void) {
        self.onInvitedAction = onInvitedAction
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .communityInviteMemberPage))
        self._selectedUsers = State(initialValue: users)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBarView
                .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 16))
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            searchUserView
                .padding(EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16))
            
            if !selectedUsers.isEmpty {
                selectedUserView
                    .padding(EdgeInsets(top: 24, leading: 0, bottom: 16, trailing: 0))
                
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
            }
            
            switch listState {
            case .loading:
                scrollingList { skeletonRows }
            case .users:
                scrollingList { userRows }
            case .noUsersAvailable:
                noUsersAvailableView
            case .needMoreCharacters:
                needEnoughCharToSearchView
            case .noResults:
                emptyView
            }
            
            inviteMemberButtonView
                .padding(.bottom, 10)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    private func scrollingList<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            Color.clear.frame(height: 16)

            LazyVStack(spacing: 16, content: content)
        }
        .padding(.leading, 16)
    }

    @ViewBuilder
    private var skeletonRows: some View {
        ForEach(0..<3, id: \.self) { _ in
            UserCellSkeletonView()
                .environmentObject(viewConfig)
        }
    }

    @ViewBuilder
    private var userRows: some View {
        ForEach(Array(viewModel.searchedUsers.enumerated()), id: \.element.userId) { index, user in
            let isSelected = isSelectedUser(user)

            getUserView(user, isSelected: isSelected)
                .onTapGesture {
                    if isSelected {
                        selectedUsers.remove(at: selectedUsers.firstIndex(of: user) ?? 0)
                    } else {
                        selectedUsers.append(user)
                    }
                }
                .onAppear {
                    if index == viewModel.searchedUsers.count - 1 {
                        viewModel.loadMoreUsers()
                    }
                }
        }
    }

    private enum ListState {
        case loading
        case noUsersAvailable
        case needMoreCharacters
        case noResults
        case users
    }

    /// Every combination resolves to a state — the previous chain matched none for `.notLoading`
    /// and fell through to an empty list, which is why the area rendered blank with no explanation.
    private var listState: ListState {
        if viewModel.loadingStatus == .loading { return .loading }
        if !viewModel.searchedUsers.isEmpty { return .users }

        let keyword = viewModel.searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if keyword.isEmpty { return .noUsersAvailable }
        return keyword.count < 3 ? .needMoreCharacters : .noResults
    }

    private var navigationBarView: some View {
        HStack(spacing: 0) {
            Image(AmityIcon.closeIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 24)
                .onTapGesture {
                    host.controller?.dismiss(animated: true)
                }
            
            Spacer()
            
            let title = viewConfig.getText(elementId: .title) ?? AmityLocalizedStringSet.Social.communityInviteMemberTitle.localizedString
            Text(title)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 24)
        }
    }
    
    
    private var searchUserView: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.searchIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 20, height: 16)
                .padding(.leading, 12)
            
            ZStack(alignment: .trailing) {
                TextField(AmityLocalizedStringSet.Social.searchUserPlaceholder.localizedString, text: $viewModel.searchKeyword)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                
                Button(
                    action: {
                        viewModel.searchKeyword = ""
                    },
                    label: {
                        Image(AmityIcon.backgroundedCloseIcon.getImageResource())
                            .resizable()
                            .frame(width: 17, height: 17)
                            .padding(.trailing, 12)
                    }
                )
                .visibleWhen(!viewModel.searchKeyword.isEmpty)
            }
        }
        .frame(height: 40)
        .background(Color(viewConfig.theme.baseColorShade4))
        .clipShape(RoundedCorner(radius: 8))
    }
    
    
    private var selectedUserView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                Color.clear
                    .frame(width: 4)
                
                ForEach(Array(selectedUsers.enumerated()), id: \.element.userId) { index, user in
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            AmityUserProfileImageView(displayName: user.displayName, avatarURL: URL(string: user.avatarURL))
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            
                            Circle()
                                .fill(.black.opacity(0.3))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(AmityIcon.closeIcon.getImageResource())
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 18, height: 18)
                                )
                                .offset(x: 2, y: -3)
                                .onTapGesture {
                                    selectedUsers.remove(at: index)
                                }
                        }
                        
                        UserDisplayNameLabel(name: user.displayName, isBrand: user.isBrand, spacing: 2)
                    }
                    .frame(width: 68)
                }
            }
        }
        .frame(height: 70)
    }
    
    private func getUserView(_ user: AmityUserModel, isSelected: Bool) -> some View {
        ZStack {
            HStack(spacing: 12) {
                AmityUserProfileImageView(displayName: user.displayName, avatarURL: URL(string: user.avatarURL))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                Text(user.displayName)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                if user.isBrand {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .padding(.leading, -6)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2.0)
                        .fill(Color(viewConfig.theme.baseColorShade3))
                        .frame(width: 16, height: 16)
                        .isHidden(isSelected)
                    
                    Image(AmityIcon.checkboxIcon.getImageResource())
                        .frame(width: 22, height: 22)
                        .isHidden(!isSelected)
                        .offset(x: 3)
                }
                .padding(.trailing, 18)
            }
            
            Color.clear // Invisible overlay for tap event
                .contentShape(Rectangle())
        }
    }
    
    
    private var inviteMemberButtonView: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Rectangle()
                .fill(Color(viewConfig.theme.primaryColor).opacity(selectedUsers.isEmpty ? 0.3 : 1))
                .frame(height: 40)
                .cornerRadius(4)
                .overlay (
                    Text(viewConfig.getText(elementId: .inviteButton) ?? AmityLocalizedStringSet.Social.communityInviteMemberButton.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                        .opacity(selectedUsers.isEmpty ? (viewConfig.currentStyle == .dark ? 0.3 : 1) : 1)
                )
                .onTapGesture {
                    guard !selectedUsers.isEmpty else { return }
                    onInvitedAction(selectedUsers)
                }
                .padding([.leading, .trailing], 16)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 15) {
            Image(AmityIcon.noSearchableIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 60, height: 60)
            
            Text(AmityLocalizedStringSet.Social.searchNoResultsFound.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noUsersAvailableView: some View {
        VStack(spacing: 8) {
            Image(AmityIcon.listRadioIcon.getImageResource())
                .renderingMode(.template)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))

            Text(AmityLocalizedStringSet.Social.noUsersAvailable.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var needEnoughCharToSearchView: some View {
        VStack(spacing: 15) {
            Image(AmityIcon.defaultSearchIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 60, height: 60)
            
            Text(AmityLocalizedStringSet.Social.startSearchHint.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func isSelectedUser(_ user: AmityUserModel) -> Bool {
        return selectedUsers.contains { $0.userId == user.userId }
    }
}

class AmityCommunityInviteMemberPageViewModel: ObservableObject {
    @Published var searchedUsers: [AmityUserModel] = []
    @Published var searchKeyword: String = ""
    /// `.loading`, not `.notLoading`: `init` always schedules a search, so the list is pending from
    /// the moment the page exists and must not read as "no users available" during the debounce.
    @Published var loadingStatus: AmityLoadingStatus = .loading
    
    private let userManager = UserManager()
    private var userCollection: AmityCollection<AmityUser>?
    private var userCancellable: AnyCancellable?
    private var searchKeywordCancellable: AnyCancellable?
    private var loadingStatusCancellable: AnyCancellable?
    
    init() {
        searchKeywordCancellable = $searchKeyword
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                guard let self else { return }
                searchUser(value)
            })
    }
    
    private func searchUser(_ keyword: String) {
        userCollection = nil
        userCancellable = nil
        
        userCollection = userManager.searchUsers(keyword: keyword)
        userCancellable = userCollection?.$snapshots
            .sink(receiveValue: { [weak self] users in
                self?.searchedUsers = users.map { AmityUserModel(user: $0) }
            })
        
        loadingStatusCancellable = userCollection?.$loadingStatus
            .sink(receiveValue: { [weak self] status in
                self?.loadingStatus = status
            })
    }
    
    func loadMoreUsers() {
        guard let userCollection, userCollection.hasNext else { return }
        userCollection.nextPage()
    }
}
