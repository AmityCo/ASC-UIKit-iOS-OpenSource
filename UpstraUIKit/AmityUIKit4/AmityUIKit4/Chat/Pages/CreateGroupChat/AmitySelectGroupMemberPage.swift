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
                selectedMembersRow
                AmityDivider(variant: .post, viewConfig: viewConfig)
            }

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
        .background(Color(viewConfig.color(.surfacePageBackgroundDefault)).ignoresSafeArea())
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
                .applyTextStyle(.titleBold(Color(viewConfig.color(.textSheetsHeaderTitleDefault))))
                .frame(maxWidth: .infinity)

            HStack {
                Button {
                    if onMembersSelected != nil {
                        host.controller?.navigationController?.popViewController(animated: true)
                    } else {
                        host.controller?.navigationController?.dismiss(animated: true)
                    }
                } label: {
                    Image(AmityIcon.DesignSystem.chevronLeft.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconIconButtonGhostSecondaryDefault)))
                        .frame(width: 24, height: 24)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Spacer()

                AmityButton(
                    variant: .main,
                    hierarchy: .primary,
                    style: .ghost,
                    label: onMembersSelected != nil
                        ? AmityLocalizedStringSet.Chat.SelectGroupMember.done.localizedString
                        : AmityLocalizedStringSet.Chat.SelectGroupMember.next.localizedString,
                    isDisabled: viewModel.selectedUsers.isEmpty,
                    viewConfig: viewConfig
                ) {
                    if let callback = onMembersSelected {
                        callback(viewModel.selectedUsers)
                        host.controller?.navigationController?.popViewController(animated: true)
                    } else {
                        let createPage = AmityCreateGroupChatPage(selectedUsers: viewModel.selectedUsers)
                        let vc: UIViewController = AmitySwiftUIHostingController(rootView: createPage)
                        host.controller?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.color(.surfaceSheetsBackgroundGeneral)))
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
                AmityChatUserProfileImageView(displayName: user.displayName ?? user.userId, avatarURL: user.resolvedAvatarURL)
                .frame(width: 40, height: 40)

                Button {
                    viewModel.toggleSelection(user)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(viewConfig.color(.surfaceIconButtonTransparentPrimaryEnabled)))
                            .frame(width: 16, height: 16)
                        Image(AmityIcon.DesignSystem.crossR.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.color(.iconIconButtonTransparentPrimaryDefault)))
                            .frame(width: 12, height: 12)
                    }
                }
                .buttonStyle(.plain)
            }

            Text(user.displayName ?? user.userId)
                .applyTextStyle(.caption(Color(viewConfig.color(.textAvatarLabelDefault))))
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
            Image(AmityIcon.DesignSystem.searchR.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.color(.iconInputTextInputDefault)))
                .frame(width: 20, height: 20)

                TextField(AmityLocalizedStringSet.Chat.SelectGroupMember.searchPlaceholder.localizedString, text: $viewModel.searchKeyword)
                    .applyTextStyle(.body(Color(viewConfig.color(.textInputTextInputPlaceholderEnabledFilled))))

            if !viewModel.searchKeyword.isEmpty {
                Button { viewModel.searchKeyword = "" } label: {
                    Image(AmityIcon.DesignSystem.clearR.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.color(.iconInputTextInputDefault)))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color(viewConfig.color(.surfaceInputBoxedInputDefault)))
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
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    private func userRow(user: AmityUser, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AmityChatUserProfileImageView(displayName: user.displayName ?? user.userId, avatarURL: user.resolvedAvatarURL)
            .frame(width: 44, height: 44)

            HStack(spacing: 0) {
                Text(user.displayName ?? user.userId)
                    .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))
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

            AmitySelection(variant: .checkbox,
                           isSelected: isSelected,
                           viewConfig: viewConfig) { _, _ in }
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
        .contentShape(Rectangle())
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                            .frame(width: 44, height: 44)
                            .shimmering()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(viewConfig.color(.surfaceSkeletonEffectDefault)))
                            .frame(width: 160, height: 14)
                            .shimmering()
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color(viewConfig.color(.surfaceListDefaultDefault)))
    }

    // MARK: - Empty state

    private var initialSearchState: some View {
        VStack {
            Spacer()
            AmityEmptyState(
                variant: .icon,
                image: AmityIcon.DesignSystem.searchR.imageResource,
                title: AmityLocalizedStringSet.Chat.Search.minimumChars.localizedString,
                viewConfig: viewConfig
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            AmityEmptyState(
                variant: .icon,
                image: AmityIcon.DesignSystem.searchCrossL.imageResource,
                title: AmityLocalizedStringSet.Chat.Search.emptyTitle.localizedString,
                viewConfig: viewConfig
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
