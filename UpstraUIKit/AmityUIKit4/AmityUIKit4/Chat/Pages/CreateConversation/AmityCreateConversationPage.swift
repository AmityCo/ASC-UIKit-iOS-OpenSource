//
//  AmityCreateConversationPage.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import Combine

// MARK: - ViewModel

@MainActor
final class AmityCreateConversationViewModel: ObservableObject {

    @Published var searchKeyword: String = ""
    @Published var users: [AmityUser] = []
    @Published var isLoading = false
    @Published var isCreating = false

    private let userManager = UserManager()
    private let channelManager = ChannelManager()
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
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            let currentUserId = AmityUIKitManagerInternal.shared.client.currentUserId ?? ""
            self.users = col.snapshots.filter { $0.userId != currentUserId }
            self.isLoading = false
        }
    }

    func loadMoreIfNeeded(atIndex index: Int) {
        guard index == users.count - 1,
              collection?.hasNext == true else { return }
        collection?.nextPage()
    }

    func createConversation(with user: AmityUser) async throws -> String {
        isCreating = true
        defer { isCreating = false }
        let builder = AmityConversationChannelCreateOptions()
        builder.setUserId(user.userId)
        builder.setIsDistinct(true)
        let channel = try await channelManager.createChannel(with: builder)
        return channel.channelId
    }
}

// MARK: - Page

public struct AmityCreateConversationPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper

    public var id: PageId { .createConversationPage }

    @StateObject private var viewModel = AmityCreateConversationViewModel()
    @StateObject private var viewConfig: AmityViewConfigController

    public init() {
        self._viewConfig = StateObject(
            wrappedValue: AmityViewConfigController(pageId: .createConversationPage)
        )
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: Navigation bar
                navBar

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

            if viewModel.isCreating {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .navigationBarHidden(true)
        .updateTheme(with: viewConfig)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(AmityLocalizedStringSet.Chat.CreateConversation.navbarTitle.localizedString)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .frame(maxWidth: .infinity)

                HStack {
                    Button {
                        host.controller?.dismiss(animated: true)
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

                    Color.clear
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)

            HStack(spacing: 8) {
                Image(AmityIcon.Chat.searchButtonIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .frame(width: 14, height: 14)

                TextField(AmityLocalizedStringSet.Chat.CreateConversation.searchPlaceholder.localizedString, text: $viewModel.searchKeyword)
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
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    // MARK: - User list

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.users.enumerated()), id: \.element.userId) { index, user in
                    Button {
                        openChat(with: user)
                    } label: {
                        userRow(user: user)
                    }
                    .buttonStyle(.plain)
                    .onAppear { viewModel.loadMoreIfNeeded(atIndex: index) }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }

    private func openChat(with user: AmityUser) {
        guard let presentedVC = host.controller else { return }

        let presenter = presentedVC.presentingViewController
        let presentingNav: UINavigationController? =
            presenter?.navigationController
            ?? (presenter as? UINavigationController)
            ?? ((presenter as? UITabBarController)?.selectedViewController as? UINavigationController)

        Task {
            guard let channelId = try? await viewModel.createConversation(with: user) else { return }
            let chatPage = AmityChatPage(channelId: channelId)
            let chatVC: UIViewController = AmitySwiftUIHostingController(rootView: chatPage)

            if let nav = presentingNav {
                presentedVC.dismiss(animated: true) {
                    nav.pushViewController(chatVC, animated: true)
                }
            } else {
                chatVC.modalPresentationStyle = .fullScreen
                presentedVC.dismiss(animated: true) {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        var top = root
                        while let presented = top.presentedViewController { top = presented }
                        top.present(chatVC, animated: true)
                    }
                }
            }
        }
    }

    private func userRow(user: AmityUser) -> some View {
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
