//
//  AmityMessageListViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan on 3/4/2567 BE.
//

import SwiftUI
import Combine
import AmitySDK
import OSLog

struct ToastState {
    let style: ToastStyle
    let message: String
}

public class AmityMessageListViewModel: ObservableObject {
    let subChannelId: String
    let chatManager = ChatManager()
        
    @Published var messages = [MessageModel]()
    // Query state when message list is queried for the first time
    @Published var initialQueryState: QueryState = .loading
    @Published var muteState: MuteState = .none
    @Published var pagination: ScrollViewPagination = ScrollViewPagination()
        
    // Current toast state
    @Published var toastState: ToastState?
    
    var selectedMessage: MessageModel?
    
    var hasModeratorPermission = false
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
    
    public init(subChannelId: String) {
        self.subChannelId = subChannelId
        
        ChatPermissionChecker.hasModeratorPermission(for: subChannelId) { hasPermission in
            self.hasModeratorPermission = hasPermission
        }
        
        self.delegate = AmityUIKit4Manager.client.delegate
    }
    
    var messageAction: AmityMessageAction = .init()
    
    var token: AmityNotificationToken?
    
    public func queryMessages() {
        
        let channel = AmityChannelRepository(client: AmityUIKit4Manager.client).getChannel(subChannelId).snapshot
        channel?.subscribeEvent(completion: { isSuccess, _ in
            if !isSuccess {
                Log.chat.warning("Failed to subscribe to events for channel \(self.subChannelId)")
            }
        })
        
        pagination.reset()
        
        initialQueryState = .loading
        let options = AmityMessageQueryOptions(subChannelId: subChannelId, sortOption: .lastCreated)
        
        messageCollection = chatManager.queryMessages(options: options)
        
        token?.invalidate()
        token = nil
        token = messageCollection?.observe({ [weak self] collection, _, error in
            guard let self else { return }
            
            if let error {
                Log.chat.warning("Error when querying for messages \(error.localizedDescription)")
                
                if self.initialQueryState == .loading {
                    // Failed to load chat for first time
                    if error.isAmityErrorCode(.userIsBanned) {
                        self.initialQueryState = .banned
                        
                    } else {
                        self.initialQueryState = .error
                    }
                }
                return
            }
            
            if let channel = chatManager.getChannel(channelId: subChannelId), channel.isMuted {
                muteState = .channel
            } else if let currentMember = chatManager.getCurrentUserChannelMember(channelId: subChannelId) {
                if currentMember.isBanned {
                    /// Display banned empty state if current user is banned
                    self.initialQueryState = .banned
                    return
                } else if currentMember.isMuted {
                    muteState = .user
                }
            }
            
            if collection.dataStatus == .fresh {
                self.initialQueryState = .success
            
                let messages = collection.snapshots
                /// Need to modify.
                var messageModels = [MessageModel]()
                for message in messages {
                    let messageModel = MessageModel(message: message, hasModeratorPermission: hasModeratorPermission)
                    messageModels.append(messageModel)
                }
                messageModels.reverse()
                
                self.messages = messageModels
                
                if collection.count() > self.pagination.currentItemsCount && self.pagination.isInProgress {
                    self.pagination.end(anchor: nil)
                }
            }
            self.updateQueryState(loadingStatus: collection.loadingStatus)
        })
    }
    
    public func loadMoreMessages() {
        guard let collection = messageCollection, collection.loadingStatus != .loading else { return }
        
        if !messages.isEmpty && collection.hasNext && !pagination.isInProgress {
            // Set first message as an anchor for this pagination
            pagination.start(anchor: messages.first?.id ?? "")
            pagination.currentItemsCount = collection.count()
            
            collection.nextPage()
        }
    }
    
    @MainActor
    public func deleteMessage(messageId: String) {
        Task {
            do {
                let _ = try await chatManager.deleteMessage(messageId: messageId)
            } catch {
                toastState = .init(style: .warning, message: AmityLocalizedStringSet.Chat.toastDeleteErrorMessage.localizedString)
            }
        }
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
        return messageCollection.count() >= 20 && messageCollection.hasNext && loadingStatus != .error
    }
    
    @MainActor
    public func reportMessage(messageId: String) {
        Task {
            do {
                let _ = try await chatManager.flagMessage(messageId: messageId)
                
                // Add this value to cache
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
                
                // Add this value to cache
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

class ScrollViewPagination: ObservableObject {
    
    @Published var pagination: Int = 0
    
    var currentItemsCount = 0
    @Published var anchor: String?
    @Published var isInProgress = false
    
    func start(anchor: String) {
        self.anchor = anchor
        self.isInProgress = true
    }
    
    func end(anchor: String?) {
        pagination += 1 // Trigger in view
        isInProgress = false
    }
    
    func reset() {
        self.anchor = nil
        self.pagination = 0
        self.isInProgress = false
        self.currentItemsCount = 0
    }
}

extension AmityMessageListViewModel: AmityClientDelegate {
    public func didReceiveError(error: Error) {
        if error.isAmityErrorCode(.globalBan) {
            self.initialQueryState = .banned
        }
    }
}
