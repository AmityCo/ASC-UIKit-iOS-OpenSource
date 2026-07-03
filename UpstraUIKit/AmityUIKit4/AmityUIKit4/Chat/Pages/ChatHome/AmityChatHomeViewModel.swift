//
//  AmityChatHomeViewModel.swift
//  AmityUIKit4
//

import Foundation
import Combine
import AmitySDK

// MARK: - Tab

enum ChatHomeTab: CaseIterable {
    case all
    case direct
    case group

    var title: String {
        switch self {
        case .all:    return AmityLocalizedStringSet.Chat.Home.tabAll.localizedString
        case .direct: return AmityLocalizedStringSet.Chat.Home.tabDirect.localizedString
        case .group:  return AmityLocalizedStringSet.Chat.Home.tabGroups.localizedString
        }
    }

    static func visibleTabs() -> [ChatHomeTab] {
        let enabled = AmityUIKitConfigController.shared.enabledChannelTypes()
        let typedTabs: [ChatHomeTab] = enabled.map { type in
            switch type {
            case .conversation: return .direct
            case .community:    return .group
            }
        }
        guard typedTabs.count > 1 else {
            return typedTabs
        }
        return [.all] + typedTabs
    }
}

// MARK: - ViewModel

@MainActor
final class AmityChatHomeViewModel: ObservableObject {

    // MARK: Published state
    @Published var selectedTab: ChatHomeTab
    @Published private(set) var allChannels: [AmityChannel] = []
    @Published private(set) var directChannels: [AmityChannel] = []
    @Published private(set) var groupChannels: [AmityChannel] = []
    @Published var isLoading = true
    @Published var isPushNotificationEnabled: Bool = true

    let visibleTabs: [ChatHomeTab]

    // MARK: SDK
    private let channelManager = ChannelManager()
    private var allCollection: AmityCollection<AmityChannel>?
    private var directCollection: AmityCollection<AmityChannel>?
    private var groupCollection: AmityCollection<AmityChannel>?

    private var allToken: AmityNotificationToken?
    private var directToken: AmityNotificationToken?
    private var groupToken: AmityNotificationToken?

    init() {
        let tabs = ChatHomeTab.visibleTabs()
        self.visibleTabs = tabs
        self.selectedTab = tabs.first ?? .all
        startObservingAll()
        startObservingDirect()
        startObservingGroup()
        fetchPushNotificationSettings()
    }

    deinit {
        allToken?.invalidate()
        allToken = nil
        directToken?.invalidate()
        directToken = nil
        groupToken?.invalidate()
        groupToken = nil
    }

    // MARK: - Push Notification Settings

    private func fetchPushNotificationSettings() {
        Task {
            do {
                let manager = AmityUIKitManagerInternal.shared.client.notificationManager
                let settings = try await manager.getSettings()
                let chatModuleEnabled = settings.modules
                    .first(where: { $0.moduleType == .chat })?.isEnabled ?? true
                self.isPushNotificationEnabled = settings.isEnabled && chatModuleEnabled
            } catch {
                self.isPushNotificationEnabled = true
            }
        }
    }

    // MARK: - Query observers

    private func startObservingAll() {
        let query = AmityChannelQueryOptions(types: [AmityChannelQueryType.conversation, AmityChannelQueryType.community], filter: .userIsMember, includeDeleted: false, excludeArchives: true)
        allCollection = channelManager.getChannels(with: query)
        allToken = allCollection?.observe { [weak self] collection, _ in
            guard let self else { return }
            self.allChannels = collection.snapshots
            self.isLoading = false
        }
    }

    private func startObservingDirect() {
        let query = AmityChannelQueryOptions(types: [AmityChannelQueryType.conversation], filter: .userIsMember, includeDeleted: false, excludeArchives: true)
        directCollection = channelManager.getChannels(with: query)
        directToken = directCollection?.observe { [weak self] collection, _ in
            guard let self else { return }
            self.directChannels = collection.snapshots
        }
    }

    private func startObservingGroup() {
        let query = AmityChannelQueryOptions(types: [AmityChannelQueryType.community], filter: .userIsMember, includeDeleted: false, excludeArchives: true)
        groupCollection = channelManager.getChannels(with: query)
        groupToken = groupCollection?.observe { [weak self] collection, _ in
            guard let self else { return }
            self.groupChannels = collection.snapshots
        }
    }

    // MARK: - Pagination

    func loadMoreIfNeeded(for tab: ChatHomeTab) {
        switch tab {
        case .all:    if allCollection?.hasNext == true    { allCollection?.nextPage() }
        case .direct: if directCollection?.hasNext == true { directCollection?.nextPage() }
        case .group:  if groupCollection?.hasNext == true  { groupCollection?.nextPage() }
        }
    }

    // MARK: - Active channel list for current tab

    var activeChannels: [AmityChannel] {
        switch selectedTab {
        case .all:    return allChannels
        case .direct: return directChannels
        case .group:  return groupChannels
        }
    }

    var hasUnreadMessages: Bool {
        activeChannels.contains(where: { $0.unreadCount > 0 })
    }

    // MARK: - Archive

    enum ArchiveResult {
        case success, limitExceeded, error
    }

    func archiveChannel(_ channelId: String) async -> ArchiveResult {
        do {
            try await channelManager.archiveChannel(channelId: channelId)
            return .success
        } catch {
            if error.localizedDescription.lowercased().contains("limit") {
                return .limitExceeded
            }
            return .error
        }
    }
}
