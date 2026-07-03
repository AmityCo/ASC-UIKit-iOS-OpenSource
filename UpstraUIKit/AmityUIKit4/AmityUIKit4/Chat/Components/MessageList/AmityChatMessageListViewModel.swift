//
//  AmityChatMessageListViewModel.swift
//  AmityUIKit4
//

import SwiftUI
import Combine
import AmitySDK
import OSLog

@MainActor
public final class AmityChatMessageListViewModel: ObservableObject {
    let subChannelId: String
    let chatManager = ChatManager()
    private let channelManager = ChannelManager()
    private let fileRepositoryManager = FileRepositoryManager()

    @Published var messages = [MessageModel]()

    @Published var uploadProgress: [String: Double] = [:]

    /// `uniqueId`s of uploads the user cancelled — both cancel and failure land in `.error`.
    private var cancelledUploadIds: Set<String> = []

    @Published var initialQueryState: QueryState = .loading
    @Published var muteState: MuteState = .none
    @Published var pagination: ScrollViewPagination = ScrollViewPagination()

    /// Set this to scroll to a specific message and trigger a bounce animation.
    @Published var jumpToMessageId: String? = nil
    /// The message ID currently bouncing (cleared after animation).
    @Published var bouncingMessageId: String? = nil

    private var pendingAroundMessageId: String?

    /// Timeout task (3 s) that fires after `pendingAroundMessageId` is set.
    private var jumpTimeoutTask: Task<Void, Never>?

    // Current toast state
    @Published var toastState: ToastState?

    /// Delete confirmation state.
    @Published var pendingDeleteMessageId: String? = nil

    /// Set to a message ID to present the report sheet.
    @Published var pendingReportMessageId: String? = nil

    @Published var pendingFailedMessage: MessageModel? = nil
    @Published var showFailedActionSheet: Bool = false

    /// Set to true to present the reaction list sheet.
    @Published var showingReactionSheet: Bool = false

    @Published var selectedMessage: MessageModel?

    @Published var hasModeratorPermission = false
    var delegate: AmityClientDelegate?

    enum QueryState {
        case loading
        case success
        case error
        case banned
    }

    enum MuteState {
        case channel
        case user
        case none

        var localizedString: String {
            switch self {
            case .channel:
                return AmityLocalizedStringSet.Chat.channelIsMuted.localizedString
            case .user:
                return AmityLocalizedStringSet.Chat.userIsMuted.localizedString
            case .none:
                return ""
            }
        }
    }

    private var messageCollection: AmityCollection<AmityMessage>?

    private var moderatorUserIds: Set<String> = []
    private var moderatorsCollection: AmityCollection<AmityChannelMember>?
    private var moderatorsToken: AmityNotificationToken?

    public init(subChannelId: String, aroundMessageId: String? = nil) {
        self.subChannelId = subChannelId
        self.pendingAroundMessageId = aroundMessageId

        self.delegate = AmityUIKit4Manager.client.delegate
    }

    @Published var messageAction: AmityMessageAction = .init()

    var token: AmityNotificationToken?

    private var channelToken: AmityNotificationToken?

    deinit {
        token?.invalidate()
        token = nil
        channelToken?.invalidate()
        channelToken = nil
        moderatorsToken?.invalidate()
        moderatorsToken = nil
        jumpTimeoutTask?.cancel()
    }

    // MARK: - Query

    public func queryMessages() {

        pagination.reset()

        initialQueryState = .loading
        let options = AmityMessageQueryOptions(
            subChannelId: subChannelId,
            aroundMessageId: pendingAroundMessageId,
            sortOption: .lastCreated
        )

        if pendingAroundMessageId != nil {
            startJumpTimeout()
        }

        messageCollection = chatManager.queryMessages(options: options)

        observeChannelForMidSessionBan()
        observeChannelModerators()

        token?.invalidate()
        token = nil
        token = messageCollection?.observe({ [weak self] collection, error in
            guard let self else { return }

            if let error {
                Log.chat.warning("Error when querying for messages \(error.localizedDescription)")

                if error.isAmityErrorCode(.userIsBanned) {
                    self.initialQueryState = .banned
                } else if self.initialQueryState == .loading {
                    self.initialQueryState = .error
                }
                return
            }

            let channel = chatManager.getChannel(channelId: subChannelId)
            let currentMember = channel?.currentMember

            if let channel, channel.isMuted {
                muteState = .channel
            } else if let currentMember {
                if currentMember.isBanned {
                    self.initialQueryState = .banned
                    return
                } else if currentMember.isMuted {
                    muteState = .user
                } else {
                    muteState = .none
                }
            } else {
                muteState = .none
            }

            // Show as soon as the LiveCollection has local cache — don't wait for .fresh (no loading flash for cached chats).
            if !collection.snapshots.isEmpty || collection.dataStatus == .local || collection.dataStatus == .fresh {
                self.initialQueryState = .success
            }

            let messages = collection.snapshots

            let isGroupChat: Bool = {
                guard let type = channel?.channelType else { return false }
                return type == .community || type == .live
            }()

            var messageModels = [MessageModel]()
            let mods = self.moderatorUserIds
            for message in messages {
                var messageModel = MessageModel(
                    message: message,
                    hasModeratorPermission: hasModeratorPermission,
                    isGroupChat: isGroupChat,
                    isSenderModerator: mods.contains(message.userId)
                )
                messageModel.isUploadCancelled = cancelledUploadIds.contains(message.uniqueId)
                messageModels.append(messageModel)
            }
            messageModels.reverse()

            self.messages = messageModels

            self.trackMediaUploadProgress(in: messages)

            if collection.snapshots.count > self.pagination.currentItemsCount && self.pagination.isInProgress {
                self.pagination.end(anchor: nil)
            }

            if let target = self.pendingAroundMessageId,
               messageModels.contains(where: { $0.id == target }) {
                self.pendingAroundMessageId = nil
                self.cancelJumpTimeout()
                self.jumpToMessageId = target
            }
            self.updateQueryState(loadingStatus: collection.loadingStatus)
        })
    }

    private func trackMediaUploadProgress(in messages: [AmityMessage]) {
        let currentUserId = AmityUIKit4Manager.client.currentUserId
        for message in messages where message.userId == currentUserId
            && (message.messageType == .image || message.messageType == .video) {
            let uploadId = message.uniqueId

            if message.syncState == .syncing {
                // Non-nil entry ⇒ already tracking; don't stack a second handler
                // (the SDK uploader appends, it doesn't replace).
                guard uploadProgress[uploadId] == nil else { continue }
                uploadProgress[uploadId] = 0
                fileRepositoryManager.observeUploadProgress(uploadId: uploadId) { [weak self] progress in
                    // Hop to main for the @Published mutation (closure is non-isolated).
                    DispatchQueue.main.async { self?.uploadProgress[uploadId] = progress }
                }
            } else if uploadProgress[uploadId] != nil {
                // Upload finished (.synced) or failed (.error): stop tracking.
                uploadProgress[uploadId] = nil
            }
        }
    }

    private func observeChannelModerators() {
        moderatorsToken?.invalidate()
        moderatorsToken = nil
        moderatorsCollection = channelManager.getMembers(
            channelId: subChannelId,
            roles: ["channel-moderator"]
        )
        moderatorsToken = moderatorsCollection?.observe { [weak self] collection, _ in
            guard let self else { return }
            let newSet = Set(collection.snapshots.map { $0.userId })
            guard newSet != self.moderatorUserIds else { return }
            self.moderatorUserIds = newSet
            self.rebuildMessageModelsForModeratorChange()
        }
    }

    private func rebuildMessageModelsForModeratorChange() {
        guard let messageCollection else { return }
        let snapshots = messageCollection.snapshots
        let parentChannel = chatManager.getChannel(channelId: subChannelId)
        let isGroupChat: Bool = {
            guard let type = parentChannel?.channelType else { return false }
            return type == .community || type == .live
        }()
        let mods = self.moderatorUserIds
        var rebuilt = [MessageModel]()
        for message in snapshots {
            var model = MessageModel(
                message: message,
                hasModeratorPermission: hasModeratorPermission,
                isGroupChat: isGroupChat,
                isSenderModerator: mods.contains(message.userId)
            )
            model.isUploadCancelled = cancelledUploadIds.contains(message.uniqueId)
            rebuilt.append(model)
        }
        rebuilt.reverse()
        self.messages = rebuilt
    }

    private func observeChannelForMidSessionBan() {
        channelToken?.invalidate()
        channelToken = nil
        channelToken = channelManager.getChannel(channelId: subChannelId).observe { [weak self] liveObject, _ in
            guard let self else { return }
            guard let channel = liveObject.snapshot else { return }
            guard let currentMember = channel.currentMember else { return }

            let isModerator = currentMember.roles.contains(AmityChannelRole.channelModerator.rawValue)
            if self.hasModeratorPermission != isModerator { self.hasModeratorPermission = isModerator }

            if currentMember.isBanned, self.initialQueryState != .banned {
                self.initialQueryState = .banned
                return
            }

            if channel.isMuted {
                self.muteState = .channel
            } else if currentMember.isMuted {
                self.muteState = .user
            } else {
                self.muteState = .none
            }
        }
    }

    /// Re-run the query with a new `aroundMessageId`.
    public func jumpTo(messageId: String) {
        if messages.contains(where: { $0.id == messageId }) {
            jumpToMessageId = messageId
            return
        }
        pendingAroundMessageId = messageId
        queryMessages()
    }

    // MARK: - Jump timeout

    private func startJumpTimeout() {
        jumpTimeoutTask?.cancel()
        jumpTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, let self else { return }
            guard self.pendingAroundMessageId != nil else { return }
            self.pendingAroundMessageId = nil
            self.toastState = .init(
                style: .warning,
                message: AmityLocalizedStringSet.Chat.JumpToMessage.unavailable.localizedString
            )
        }
    }

    private func cancelJumpTimeout() {
        jumpTimeoutTask?.cancel()
        jumpTimeoutTask = nil
    }

    // MARK: - Pagination

    public func loadMoreMessages() {
        guard let collection = messageCollection, collection.loadingStatus != .loading else { return }

        if !messages.isEmpty && collection.hasNext && !pagination.isInProgress {
            pagination.start(anchor: messages.first?.id ?? "")
            pagination.currentItemsCount = collection.snapshots.count
            collection.nextPage()
        }
    }

    // MARK: - Actions

    @MainActor
    public func deleteMessage(messageId: String) {
        guard NetworkMonitor.shared.isConnected else {
            toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastDeleteErrorMessage.localizedString)
            return
        }
        Task {
            do {
                let _ = try await chatManager.deleteMessage(messageId: messageId)
            } catch {
                toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastDeleteErrorMessage.localizedString)
            }
        }
    }
    
    @MainActor
    public func cancelUpload(uniqueId: String) {
        cancelledUploadIds.insert(uniqueId)
        fileRepositoryManager.cancelUpload(uploadId: uniqueId)
    }

    func updateQueryState(loadingStatus: AmityLoadingStatus) {
        guard let messageCollection else { return }

        if self.initialQueryState == .loading && loadingStatus == .loaded && messageCollection.dataStatus == .fresh && messages.isEmpty {
            self.initialQueryState = .success
        }
    }

    public func isPaginationAvailable() -> Bool {
        guard let messageCollection else { return false }

        let loadingStatus = messageCollection.loadingStatus
        return messageCollection.snapshots.count >= 20 && messageCollection.hasNext && loadingStatus != .error
    }

    @MainActor
    public func reportMessage(messageId: String) {
        Task {
            do {
                let _ = try await chatManager.flagMessage(messageId: messageId)
                MessageCache.shared.setFlagStatus(messageId: messageId, value: true)
                updateLocalMessageModel(messageId: messageId, isReported: true)
                toastState = .init(style: .success, message: AmityLocalizedStringSet.Chat.toastReportMessage.localizedString)
            } catch {
                toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastReportMessageError.localizedString)
            }
        }
    }

    @MainActor
    public func reportMessage(messageId: String, reason: AmityContentFlagReason) {
        Task {
            do {
                try await chatManager.flagMessage(messageId: messageId, reason: reason)
                MessageCache.shared.setFlagStatus(messageId: messageId, value: true)
                updateLocalMessageModel(messageId: messageId, isReported: true)
                toastState = .init(style: .success, message: AmityLocalizedStringSet.Chat.toastReportMessage.localizedString)
            } catch {
                toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastReportMessageError.localizedString)
            }
        }
    }

    @MainActor
    public func unReportMessage(messageId: String) {
        Task {
            do {
                let _ = try await chatManager.unflagMessage(messageId: messageId)
                MessageCache.shared.setFlagStatus(messageId: messageId, value: false)
                updateLocalMessageModel(messageId: messageId, isReported: false)
                toastState = .init(style: .success, message: AmityLocalizedStringSet.Chat.toastUnReportMessage.localizedString)
            } catch {
                toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastUnReportMessageError.localizedString)
            }
        }
    }

    private func updateLocalMessageModel(messageId: String, isReported: Bool) {
        if let firstIndex = messages.firstIndex(where: { $0.id == messageId }) {
            messages[firstIndex].isFlaggedByMe = isReported
        }
    }
}

extension AmityChatMessageListViewModel: AmityClientDelegate {
    nonisolated public func didReceiveError(error: Error) {
        Task { @MainActor in
            if error.isAmityErrorCode(.globalBan) {
                self.initialQueryState = .banned
            }
        }
    }
}
