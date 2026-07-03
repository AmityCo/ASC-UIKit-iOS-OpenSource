//
//  AmityArchivedChatViewModel.swift
//  AmityUIKit4
//

import Foundation
import Combine
import AmitySDK

@MainActor
final class AmityArchivedChatViewModel: ObservableObject {
    @Published var channels: [AmityChannel] = []
    @Published var isLoading = true

    private var collection: AmityCollection<AmityChannel>?
    private var token: AmityNotificationToken?

    init() {
        loadArchivedChannels()
    }

    deinit {
        token?.invalidate()
    }

    private let channelManager = ChannelManager()

    private func loadArchivedChannels() {
        collection = channelManager.getArchivedChannels()
        token = collection?.observe { [weak self] col, _ in
            guard let self else { return }
            self.channels = col.snapshots
            self.isLoading = false
        }
    }

    func unarchiveChannel(_ channelId: String) async -> Bool {
        do {
            try await channelManager.unarchiveChannel(channelId: channelId)
            channels.removeAll { $0.channelId == channelId }
            return true
        } catch {
            return false
        }
    }

    func loadMore() {
        guard collection?.hasNext == true else { return }
        collection?.nextPage()
    }
}
