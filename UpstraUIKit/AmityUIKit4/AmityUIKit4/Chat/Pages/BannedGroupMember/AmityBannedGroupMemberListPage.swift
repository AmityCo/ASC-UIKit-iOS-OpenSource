//
//  AmityBannedGroupMemberListPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmityBannedGroupMemberListViewModel: ObservableObject {
    @Published var bannedMembers: [AmityChannelMember] = []
    @Published var isLoading: Bool = true
    @Published var searchText: String = ""
    @Published var showActionSheet: Bool = false
    @Published var selectedMember: AmityChannelMember?

    private let channelId: String
    private let isModerator: Bool
    private let channelManager = ChannelManager()

    private var collection: AmityCollection<AmityChannelMember>?
    private var token: AmityNotificationToken?
    private var cancellables = Set<AnyCancellable>()

    init(channelId: String, isModerator: Bool) {
        self.channelId = channelId
        self.isModerator = isModerator
        loadBannedMembers(query: "")
        observeSearch()
    }

    private func loadBannedMembers(query: String) {
        isLoading = true
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            collection = channelManager.getMembers(channelId: channelId, filter: .ban)
        } else {
            let filterBuilder = AmityChannelMembershipFilterBuilder()
            filterBuilder.add(filter: .ban)
            collection = channelManager.searchMembers(channelId: channelId, displayName: trimmedQuery, filterBuilder: filterBuilder, roles: [])
        }
        observeCollection()
    }

    private func observeSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] keyword in
                guard let self else { return }
                self.loadBannedMembers(query: keyword.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .store(in: &cancellables)
    }

    private func observeCollection() {
        token?.invalidate()
        isLoading = true
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            self.bannedMembers = col.snapshots
            self.isLoading = col.loadingStatus == .loading
        }
    }

    func loadMore() {
        guard collection?.hasNext == true else { return }
        collection?.nextPage()
    }

    func unbanMember(_ userId: String) async throws {
        try await channelManager.unbanMembers(channelId: channelId, userIds: [userId])
    }

    var canModerate: Bool { isModerator }
}

// MARK: - Page

public struct AmityBannedGroupMemberListPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .bannedGroupMemberListPage }

    @StateObject private var viewModel: AmityBannedGroupMemberListViewModel
    @StateObject private var viewConfig: AmityViewConfigController

    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var toastStyle: ToastStyle = .success

    public init(channelId: String, isModerator: Bool = false) {
        self._viewModel = StateObject(wrappedValue: AmityBannedGroupMemberListViewModel(channelId: channelId, isModerator: isModerator))
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .bannedGroupMemberListPage))
    }

    public var body: some View {
        VStack(spacing: 0) {
            navBar
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)

            if viewModel.isLoading && viewModel.bannedMembers.isEmpty {
                skeletonList
            } else if viewModel.bannedMembers.isEmpty {
                emptyState
            } else {
                memberList
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
        .bottomSheet(isShowing: $viewModel.showActionSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            actionSheetContent
                .environmentObject(host)
                .padding(.bottom, 32)
        }
        .showToast(isPresented: $showToast, style: toastStyle, message: toastMessage, bottomPadding: 80)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 10) {
            Button {
                host.controller?.navigationController?.popViewController(animated: true)
            } label: {
                Image(AmityIcon.Chat.backButtonIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(width: 17, height: 17)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(AmityLocalizedStringSet.Chat.BannedMembers.navbarTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

            Spacer()

            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(AmityIcon.Chat.searchButtonIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                .frame(width: 14, height: 14)
            TextField(AmityLocalizedStringSet.Chat.BannedMembers.searchPlaceholder.localizedString, text: $viewModel.searchText)
                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
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

    // MARK: - Member List

    private var memberList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.bannedMembers.enumerated()), id: \.element.userId) { index, member in
                    memberRow(member)
                        .onAppear {
                            if index == viewModel.bannedMembers.count - 1 {
                                viewModel.loadMore()
                            }
                        }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func memberRow(_ member: AmityChannelMember) -> some View {
        HStack(spacing: 8) {
            AmityUserProfileImageView(
                displayName: member.user?.displayName ?? member.userId,
                avatarURL: {
                    guard let s = member.user?.getAvatarInfo()?.fileURL else { return nil }
                    return URL(string: s)
                }()
            )
            .frame(width: 40, height: 40)
            .padding(4)

            Text(member.user?.displayName ?? member.userId)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)

            Spacer()

            let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            if viewModel.canModerate && member.userId != currentUserId {
                Button {
                    viewModel.selectedMember = member
                    DispatchQueue.main.async {
                        viewModel.showActionSheet = true
                    }
                } label: {
                    Image(AmityIcon.Chat.ellipsisIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            } else {
                Color.clear.frame(width: 16, height: 24)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Unban Action Sheet (bottom sheet)

    @ViewBuilder
    private var actionSheetContent: some View {
        if let member = viewModel.selectedMember {
            unbanActionSheet(member: member)
        } else {
            EmptyView()
        }
    }

    private func unbanActionSheet(member: AmityChannelMember) -> some View {
        VStack(spacing: 0) {
            Button {
                viewModel.showActionSheet = false
                presentUnbanConfirmation(for: member)
            } label: {
                HStack(spacing: 12) {
                    Image(AmityIcon.Chat.banMemberButtonIcon.imageResource)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                    Text(AmityLocalizedStringSet.Chat.BannedMembers.unbanUser.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }

    // MARK: - Unban confirmation (UIAlertController)

    private func presentUnbanConfirmation(for member: AmityChannelMember) {
        let userId = member.userId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let keyWindow = UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
            guard let rootVC = keyWindow?.rootViewController else { return }
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            let alert = UIAlertController(
                title: AmityLocalizedStringSet.Chat.BannedMembers.unbanConfirmTitle.localizedString,
                message: AmityLocalizedStringSet.Chat.BannedMembers.unbanConfirmDescription.localizedString,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: AmityLocalizedStringSet.General.cancel.localizedString,
                style: .cancel
            ))
            alert.addAction(UIAlertAction(
                title: AmityLocalizedStringSet.Chat.BannedMembers.unbanButton.localizedString,
                style: .destructive
            ) { _ in
                Task {
                    do {
                        try await viewModel.unbanMember(userId)
                        toastStyle = .success
                        toastMessage = AmityLocalizedStringSet.Chat.BannedMembers.unbanSuccess.localizedString
                    } catch {
                        toastStyle = .warning
                        toastMessage = AmityLocalizedStringSet.Chat.BannedMembers.unbanFailed.localizedString
                    }
                    showToast = true
                }
            })
            topVC.present(alert, animated: true)
        }
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { _ in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 40, height: 40)
                            .padding(4)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 160, height: 10)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 56)
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(AmityIcon.Chat.bannedMemberNotFoundIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                .frame(width: 60, height: 60)
            Text(AmityLocalizedStringSet.Chat.BannedMembers.empty.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
