//
//  AmitySearchChannelViewModel.swift
//  AmityUIKit4
//

import Foundation
import Combine
import AmitySDK

@MainActor
final class AmitySearchChannelViewModel: ObservableObject {

    enum SearchTab: Int, CaseIterable {
        case chats, messages
        var title: String {
            switch self {
            case .chats: return AmityLocalizedStringSet.Chat.Search.tabChats.localizedString
            case .messages: return AmityLocalizedStringSet.Chat.Search.tabMessages.localizedString
            }
        }
    }

    enum ArchiveResult {
        case success, limitExceeded, error
    }

    @Published var searchKeyword: String = ""
    @Published var activeTab: SearchTab = .chats
    @Published var channels: [AmityChannel] = []
    @Published var messages: [AmityMessage] = []
    @Published var messageChannelMap: [String: AmityChannel] = [:]
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var archivedChannelIds: Set<String> = []
    @Published var hasResolvedMessageChannels = false

    private var cancellables = Set<AnyCancellable>()
    private var channelCollection: AmityCollection<AmityChannel>?
    private var channelToken: AmityNotificationToken?
    private var messageCollection: AmityCollection<AmityMessage>?
    private var messageToken: AmityNotificationToken?
    private var channelLookupToken: AmityNotificationToken?

    init() {
        fetchArchivedChannelIds()
        observeKeyword()
    }

    deinit {
        channelToken?.invalidate()
        messageToken?.invalidate()
        channelLookupToken?.invalidate()
    }

    // MARK: - Archived IDs (for badge)

    private let channelManager = ChannelManager()
    private let chatManager = ChatManager()

    private func fetchArchivedChannelIds() {
        Task {
            do {
                let ids = try await channelManager.getArchivedChannelIds()
                self.archivedChannelIds = Set(ids)
            } catch {}
        }
    }

    func markArchived(_ channelId: String) { archivedChannelIds.insert(channelId) }
    func markUnarchived(_ channelId: String) { archivedChannelIds.remove(channelId) }

    // MARK: - Tab switching

    func changeTab(_ tab: SearchTab) {
        guard tab != activeTab else { return }
        cleanup()
        activeTab = tab
        channels = []
        messages = []
        messageChannelMap = [:]
        isLoading = false
        hasResolvedMessageChannels = false
        let trimmed = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 3 { performSearch(trimmed) }
    }

    // MARK: - Debounced keyword

    private func observeKeyword() {
        $searchKeyword
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] keyword in
                guard let self else { return }
                let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.count < 3 {
                    self.cleanup()
                    self.channels = []
                    self.messages = []
                    self.messageChannelMap = [:]
                    self.isLoading = false
                    self.hasResolvedMessageChannels = false
                    return
                }
                self.performSearch(trimmed)
            }
            .store(in: &cancellables)
    }

    // MARK: - Search

    private func performSearch(_ query: String) {
        cleanup()
        isLoading = true
        channels = []
        messages = []
        messageChannelMap = [:]

        if activeTab == .chats {
            searchChannels(query: query)
        } else {
            searchMessages(query: query)
        }
    }

    private func searchChannels(query: String) {
        let options = AmityChannelSearchOptions()
        options.query = query
        options.types = [AmityChannelQueryType.conversation, AmityChannelQueryType.community]
        options.sortBy = .lastActivity
        options.isMemberOnly = true
        channelCollection = channelManager.searchChannels(options: options)
        channelToken = channelCollection?.observe { [weak self] col, _ in
            guard let self else { return }
            self.channels = col.snapshots
            self.isLoading = false
            self.isLoadingMore = false
        }
    }

    private func searchMessages(query: String) {
        hasResolvedMessageChannels = false
        let options = AmityMessageSearchOptions(query: query)
        messageCollection = chatManager.searchMessages(options: options)
        messageToken = messageCollection?.observe { [weak self] col, _ in
            guard let self else { return }
            let msgs = col.snapshots
            self.messages = msgs
            self.isLoading = false
            self.isLoadingMore = false
            self.fetchChannelsForMessages(msgs)
        }
    }

    private func fetchChannelsForMessages(_ msgs: [AmityMessage]) {
        guard !msgs.isEmpty else {
            hasResolvedMessageChannels = true
            return
        }
        let channelIds = Array(Set(msgs.map { $0.channelId }))
        let missingIds = channelIds.filter { messageChannelMap[$0] == nil }
        guard !missingIds.isEmpty else {
            hasResolvedMessageChannels = true
            return
        }

        let col = channelManager.getChannels(channelIds: missingIds)
        channelLookupToken?.invalidate()
        channelLookupToken = col.observeOnce { [weak self] channelCol, _ in
            guard let self else { return }
            for ch in channelCol.snapshots {
                self.messageChannelMap[ch.channelId] = ch
            }
            self.hasResolvedMessageChannels = true
        }
    }

    // MARK: - Pagination

    func loadMore() {
        guard !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        if activeTab == .chats {
            guard channelCollection?.hasNext == true else { isLoadingMore = false; return }
            channelCollection?.nextPage()
        } else {
            guard messageCollection?.hasNext == true else { isLoadingMore = false; return }
            messageCollection?.nextPage()
        }
    }

    // MARK: - Archive/Unarchive

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

    func unarchiveChannel(_ channelId: String) async -> Bool {
        do {
            try await channelManager.unarchiveChannel(channelId: channelId)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        channelToken?.invalidate()
        channelToken = nil
        channelCollection = nil
        messageToken?.invalidate()
        messageToken = nil
        messageCollection = nil
        channelLookupToken?.invalidate()
        channelLookupToken = nil
    }
}
