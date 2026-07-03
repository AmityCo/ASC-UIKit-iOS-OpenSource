//
//  AmitySelectGroupMemberPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmitySelectGroupMemberViewModel: ObservableObject {

    static let memberLimit: Int = 1000

    @Published var searchKeyword: String = ""
    @Published var users: [AmityUser] = []
    @Published var selectedUsers: [AmityUser] = []
    @Published var isLoading = false
    @Published var showMemberLimitAlert: Bool = false

    private let userManager = UserManager()
    private var collection: AmityCollection<AmityUser>?
    private var token: AmityNotificationToken?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadUsers()
        observeKeyword()
    }

    private func loadUsers() {
        isLoading = true
        collection = userManager.getUsers()
        observeCollection()
    }

    private func observeKeyword() {
        $searchKeyword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] keyword in
                guard let self else { return }
                let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.collection = self.userManager.getUsers()
                } else {
                    self.collection = self.userManager.searchUsers(keyword: trimmed, sortBy: .displayName)
                }
                self.observeCollection()
            }
            .store(in: &cancellables)
    }

    private func observeCollection() {
        token?.invalidate()
        isLoading = true
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            self.users = col.snapshots.filter { $0.userId != currentUserId }
            self.isLoading = false
        }
    }

    func toggleSelection(_ user: AmityUser) {
        if let idx = selectedUsers.firstIndex(where: { $0.userId == user.userId }) {
            selectedUsers.remove(at: idx)
        } else {
            guard selectedUsers.count < Self.memberLimit - 1 else {
                showMemberLimitAlert = true
                return
            }
            selectedUsers.append(user)
        }
    }

    func isSelected(_ user: AmityUser) -> Bool {
        selectedUsers.contains { $0.userId == user.userId }
    }

    func loadMoreIfNeeded(atIndex index: Int) {
        guard index == users.count - 1,
              collection?.hasNext == true else { return }
        collection?.nextPage()
    }
}

// MARK: - Page

public struct AmitySelectGroupMemberPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .selectGroupMemberPage }

    @StateObject private var viewModel: AmitySelectGroupMemberViewModel
    @StateObject private var viewConfig: AmityViewConfigController

    private let onMembersSelected: (([AmityUser]) -> Void)?

    public init() {
        self._viewModel = StateObject(wrappedValue: AmitySelectGroupMemberViewModel())
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .selectGroupMemberPage)
        )
        self.onMembersSelected = nil
    }

    public init(preselectedUsers: [AmityUser], onMembersSelected: @escaping ([AmityUser]) -> Void) {
        let vm = AmitySelectGroupMemberViewModel()
        vm.selectedUsers = preselectedUsers
        self._viewModel = StateObject(wrappedValue: vm)
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .selectGroupMemberPage)
        )
        self.onMembersSelected = onMembersSelected
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: Nav bar
            navBar

            // MARK: Search bar — always visible at top
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // MARK: Selected members row — below search bar
            if !viewModel.selectedUsers.isEmpty {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                selectedMembersRow
            }

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)

            // MARK: User list
            if viewModel.isLoading && viewModel.users.isEmpty {
                skeletonList
            } else if viewModel.users.isEmpty {
                let trimmed = viewModel.searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count < 3 {
                    initialSearchState
                } else {
                    emptyState
                }
            } else {
                userList
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .alert(isPresented: $viewModel.showMemberLimitAlert) {
            Alert(
                title: Text(AmityLocalizedStringSet.Chat.SelectGroupMember.memberLimitAlertTitle.localizedString),
                message: Text(AmityLocalizedStringSet.Chat.SelectGroupMember.memberLimitAlertMessage.localizedString),
                dismissButton: .default(Text(AmityLocalizedStringSet.Chat.okButton.localizedString))
            )
        }
    }

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.SelectGroupMember.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .frame(maxWidth: .infinity)

            HStack {
                Button {
                    if onMembersSelected != nil {
                        host.controller?.navigationController?.popViewController(animated: true)
                    } else {
                        host.controller?.navigationController?.dismiss(animated: true)
                    }
                } label: {
                    Image(AmityIcon.Chat.closeButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 16, height: 16)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    if let callback = onMembersSelected {
                        callback(viewModel.selectedUsers)
                        host.controller?.navigationController?.popViewController(animated: true)
                    } else {
                        let createPage = AmityCreateGroupChatPage(selectedUsers: viewModel.selectedUsers)
                        let vc: UIViewController = AmitySwiftUIHostingController(rootView: createPage)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                } label: {
                    let isEmpty = viewModel.selectedUsers.isEmpty
                    Text(
                        onMembersSelected != nil
                            ? AmityLocalizedStringSet.Chat.SelectGroupMember.done.localizedString
                            : AmityLocalizedStringSet.Chat.SelectGroupMember.next.localizedString
                    )
                    .applyTextStyle(.bodyBold(Color(isEmpty
                        ? viewConfig.theme.primaryColor.blend(.shade2)
                        : viewConfig.theme.primaryColor)))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedUsers.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Selected members row

    private var selectedMembersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(viewModel.selectedUsers.enumerated()), id: \.element.userId) { index, user in
                    selectedMemberItem(
                        user: user,
                        isFirst: index == 0,
                        isLast: index == viewModel.selectedUsers.count - 1
                    )
                }
            }
        }
        .frame(height: 106)
    }

    private func selectedMemberItem(user: AmityUser, isFirst: Bool, isLast: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AmityUserProfileImageView(displayName: user.displayName ?? user.userId, avatarURL: {
                    guard let urlStr = user.getAvatarInfo()?.fileURL else { return nil }
                    return URL(string: urlStr)
                }())
                .frame(width: 40, height: 40)

                Button {
                    viewModel.toggleSelection(user)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 18, height: 18)
                        Image(AmityIcon.Chat.closeButtonIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 9, height: 9)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }

            Text(user.displayName ?? user.userId)
                .applyTextStyle(.custom(12, .regular, Color(viewConfig.theme.baseColor)))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 56)
        }
        .frame(width: 64)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.leading, isFirst ? 16 : 0)
        .padding(.trailing, isLast ? 16 : 0)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.Chat.searchButtonIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 14, height: 14)

                TextField(AmityLocalizedStringSet.Chat.SelectGroupMember.searchPlaceholder.localizedString, text: $viewModel.searchKeyword)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))

            if !viewModel.searchKeyword.isEmpty {
                Button { viewModel.searchKeyword = "" } label: {
                    Image(AmityIcon.Chat.grayCloseIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(viewConfig.theme.baseColorShade4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - User list

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                    Button {
                        viewModel.toggleSelection(user)
                    } label: {
                        userRow(user: user, isSelected: viewModel.isSelected(user))
                    }
                    .buttonStyle(.plain)
                    .onAppear { viewModel.loadMoreIfNeeded(atIndex: index) }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func userRow(user: AmityUser, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AmityUserProfileImageView(displayName: user.displayName ?? user.userId, avatarURL: {
                guard let urlStr = user.getAvatarInfo()?.fileURL else { return nil }
                return URL(string: urlStr)
            }())
            .frame(width: 44, height: 44)

            HStack(spacing: 0) {
                Text(user.displayName ?? user.userId)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)
                if user.isBrand {
                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .fixedSize()
                        .padding(.leading, 4)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        isSelected
                            ? Color(viewConfig.theme.highlightColor)
                            : Color(viewConfig.theme.baseColorShade3),
                        lineWidth: 2
                    )
                    .frame(width: 22, height: 22)
                
                if isSelected {                    
                    Circle().fill(Color(viewConfig.theme.primaryColor)).frame(width: 20, height: 20)
                    Image(AmityIcon.checkMarkIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 44, height: 44)
                            .shimmering()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 160, height: 14)
                            .shimmering()
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Empty state

    private var initialSearchState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(AmityIcon.Chat.searchUserIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 47, height: 47)
            Text(AmityLocalizedStringSet.Chat.Search.minimumChars.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(AmityIcon.Chat.searchNotFoundIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 47, height: 47)
            Text(AmityLocalizedStringSet.Chat.Search.emptyTitle.localizedString)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
