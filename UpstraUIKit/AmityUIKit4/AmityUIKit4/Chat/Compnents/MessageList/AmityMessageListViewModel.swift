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

public class AmityMessageListViewModel: ObservableObject {
    let subChannelId: String
    let chatManager = ChatManager()
        
    @Published var messages = [MessageModel]()
    // Query state when message list is queried for the first time
    @Published var initialQueryState: QueryState = .loading
    
    @Published var pagination: ScrollViewPagination = ScrollViewPagination()
    
    var hasModeratorPermission = false
    
    enum QueryState {
        case loading
        case success
        case error
    }
    
    private var messageCollection: AmityCollection<AmityMessage>?
    
    public init(subChannelId: String) {
        self.subChannelId = subChannelId
        AmityUIKitManagerInternal.shared.client.hasPermission(.editChannelUser, forChannel: subChannelId) { hasPermission in
            self.hasModeratorPermission = hasPermission
        }
    }
    
    var messageAction: AmityMessageAction?
    
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
                    self.initialQueryState = .error
                }
            }
            
            if collection.dataStatus == .fresh {
                self.initialQueryState = .success
            
                let messages = collection.snapshots
                /// Need to modify.
                var messageModels = [MessageModel]()
                for message in messages {
                    var messageModel = MessageModel(message: message, hasModeratorPermission: hasModeratorPermission)
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
    public func deleteMessage(messageId: String) async throws {
        let _ = try await chatManager.deleteMessage(messageId: messageId)
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
}

class MessageReplyCache {
    
    static var shared = MessageReplyCache()
    
    var cachedParentMessage = [String: MessageModel]()
    
    func appendMessage(message: MessageModel) {
        cachedParentMessage[message.id] = message
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
