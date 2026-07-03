//
//  AmityAddGroupMemberPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

public struct AmityAddGroupMemberPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .addGroupMemberPage }

    private let channelId: String

    @StateObject private var viewModel: AmityAddGroupMemberViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    public init(channelId: String) {
        self.channelId = channelId
        self._viewModel = StateObject(wrappedValue: AmityAddGroupMemberViewModel(channelId: channelId))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .addGroupMemberPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar

            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            if !viewModel.selectedUsers.isEmpty {
                selectedAvatars
                Rectangle().fill(Color(viewConfig.theme.baseColorShade4)).frame(height: 1)
            }

            if viewModel.isLoading && viewModel.users.isEmpty {
                skeletonList
            } else if viewModel.users.isEmpty {
                emptyState
            } else {
                userList
            }

            Rectangle().fill(Color(viewConfig.theme.baseColorShade4)).frame(height: 1)
            Button {
                Task {
                    do {
                        let ids = viewModel.selectedUsers.compactMap { $0.userId }
                        let count = ids.count
                        try await viewModel.addMembers(ids)
                        let message = count > 1
                            ? AmityLocalizedStringSet.Chat.AddGroupMember.toastAddedMultiple.localizedString
                            : AmityLocalizedStringSet.Chat.AddGroupMember.toastAdded.localizedString
                        Toast.showToast(style: .success, message: message)
                        host.controller?.navigationController?.popViewController(animated: true)
                    } catch {
                        toastStyle = .warning
                        toastMessage = AmityLocalizedStringSet.Chat.AddGroupMember.toastFailed.localizedString
                        showToast = true
                    }
                }
            } label: {
                Text(AmityLocalizedStringSet.Chat.AddGroupMember.navbarTitle.localizedString)
                    .applyTextStyle(.bodyBold(.white))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.selectedUsers.isEmpty
                            ? Color(viewConfig.theme.primaryColor.blend(.shade2))
                            : Color(viewConfig.theme.primaryColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.selectedUsers.isEmpty)
            .padding(16)
            .background(Color(viewConfig.theme.backgroundColor))
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
    }

    private var navBar: some View {
        ZStack {
            Text(AmityLocalizedStringSet.Chat.AddGroupMember.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

            HStack {
                Button {
                    host.controller?.navigationController?.popViewController(animated: true)
                } label: {
                    Image(AmityIcon.Chat.closeButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private var selectedAvatars: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(viewModel.selectedUsers.enumerated()), id: \.element.userId) { index, user in
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            AmityUserProfileImageView(
                                displayName: user.displayName ?? (user.userId ?? ""),
                                avatarURL: {
                                    guard let s = user.getAvatarInfo()?.fileURL else { return nil }
                                    return URL(string: s)
                                }()
                            )
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                            Button { viewModel.toggleSelection(user) } label: {
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

                        Text(user.displayName ?? (user.userId ?? ""))
                            .applyTextStyle(.custom(12, .regular, Color(viewConfig.theme.baseColor)))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .frame(width: 56)
                    }
                    .frame(width: 64)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .padding(.leading, index == 0 ? 16 : 0)
                    .padding(.trailing, index == viewModel.selectedUsers.count - 1 ? 16 : 0)
                }
            }
        }
        .frame(height: 93)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.Chat.searchButtonIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 14, height: 14)
            TextField(AmityLocalizedStringSet.Chat.AddGroupMember.searchPlaceholder.localizedString, text: $viewModel.searchKeyword)
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

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                    Button { viewModel.toggleSelection(user) } label: {
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
            AmityUserProfileImageView(displayName: user.displayName ?? (user.userId ?? ""), avatarURL: {
                guard let s = user.getAvatarInfo()?.fileURL else { return nil }
                return URL(string: s)
            }())
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            HStack(spacing: 0) {
                Text(user.displayName ?? (user.userId ?? ""))
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
                    .stroke(isSelected ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.baseColorShade3), lineWidth: 2)
                    .frame(width: 20, height: 20)
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
        .frame(height: 56)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle().fill(Color(viewConfig.theme.baseColorShade4)).frame(width: 40, height: 40)
                        RoundedRectangle(cornerRadius: 4).fill(Color(viewConfig.theme.baseColorShade4)).frame(width: 160, height: 14)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
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
            Text(AmityLocalizedStringSet.Chat.AddGroupMember.empty.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ViewModel

@MainActor
final class AmityAddGroupMemberViewModel: ObservableObject {
    @Published var searchKeyword: String = ""
    @Published var users: [AmityUser] = []
    @Published var selectedUsers: [AmityUser] = []
    @Published var isLoading = false

    private let channelId: String
    private let userManager = UserManager()
    private let channelManager = ChannelManager()
    private var collection: AmityCollection<AmityUser>?
    private var token: AmityNotificationToken?
    private var cancellables = Set<AnyCancellable>()

    init(channelId: String) {
        self.channelId = channelId
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
                self.collection = trimmed.isEmpty
                    ? self.userManager.getUsers()
                    : self.userManager.searchUsers(keyword: trimmed, sortBy: .displayName)
                self.observeCollection()
            }
            .store(in: &cancellables)
    }

    private func observeCollection() {
        token?.invalidate()
        isLoading = true
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            let currentId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            self.users = col.snapshots.filter { $0.userId != currentId }
            self.isLoading = false
        }
    }

    func toggleSelection(_ user: AmityUser) {
        if let idx = selectedUsers.firstIndex(where: { $0.userId == user.userId }) {
            selectedUsers.remove(at: idx)
        } else {
            selectedUsers.append(user)
        }
    }

    func isSelected(_ user: AmityUser) -> Bool {
        selectedUsers.contains { $0.userId == user.userId }
    }

    func loadMoreIfNeeded(atIndex index: Int) {
        guard index == users.count - 1, collection?.hasNext == true else { return }
        collection?.nextPage()
    }

    func addMembers(_ userIds: [String]) async throws {
        try await channelManager.addMembers(channelId: channelId, userIds: userIds)
    }
}
