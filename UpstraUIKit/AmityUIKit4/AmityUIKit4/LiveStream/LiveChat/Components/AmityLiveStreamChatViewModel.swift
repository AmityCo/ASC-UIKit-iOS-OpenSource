//
//  AmityLiveStreamChatViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/27/25.
//

import UIKit
import AmitySDK
import Combine

public class AmityLiveStreamChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    @Published var messageInput: String = ""
    @Published var showBottomSheet: (show: Bool, message: MessageModel?) = (false, nil)
    @Published var showReactionBar: Bool = false
    @Published var composeBarState: ComposeBarState = .normal
    @Published var isTextEditorFocused: Bool = false
    
    private let channelManager = ChannelManager()
    private let chatManager = ChatManager()
    private let streamManager = StreamManager()
    private var streamToken: AmityNotificationToken?
    private var channelToken: AmityNotificationToken?
    private var channel: AmityChannel?
    private var collectionCancellable: AnyCancellable?
    private var loadingStatusCancellable: AnyCancellable?
    private var messageCollection: AmityCollection<AmityMessage>?
    private var channelMembershipCancellable: AnyCancellable?
    
    private var isCommunityMember: Bool = true
    private var isChannelEnabled: Bool = true
    private var isUserMuted: Bool = false
    
    var swapCameraAction: (() -> Void)?
    let stream: AmityStream
    let isStreamer: Bool
    let liveReactionViewModel: LiveReactionViewModel
    
    enum ComposeBarState {
        // Normal state that allows user to send messages and reactions
        case normal
        // If the user is muted by the moderator in the live channel
        case muted
        // It is read-only state when the streamer set live channel to read-only mode
        case readOnly
        // Disable the input field and reaction button if the user is not a member of community
        case disabled
    }
    
    private func updateComposeBarState() {
        let newState = calculateComposeBarState()
        if newState != composeBarState {
            composeBarState = newState
        }
    }
    
    private func calculateComposeBarState() -> ComposeBarState {
        // Priority 1: disabled state (highest priority)
        if !isCommunityMember {
            return .disabled
        }
        
        // Priority 2: readOnly state based on channel enabled
        if !isChannelEnabled {
            return .readOnly
        }
        
        // Priority 3: muted state (when channel is enabled but user is muted)
        if isUserMuted {
            return .muted
        }
        
        // Default: normal state
        return .normal
    }
    
    public init(stream: AmityStream) {
        self.stream = stream
        self.isStreamer = stream.user?.userId ?? "" == AmityUIKitManagerInternal.shared.currentUserId
        self.channel = stream.channel
        self.liveReactionViewModel = LiveReactionViewModel(stream: stream)
        
        guard let channel else { return }
        
        // If the user is streamer, we don't need to change compose bar state during live stream
        // because the streamer can always send messages and reactions
        // Also the streamer has already joined the channel since channel is created by the streamer
        if isStreamer {
            subscribeChannel(channel)
            observeMessages(channel)
        } else {
            setupComposeBarState()
            subscribeLiveStreamChatModeration(stream)
            joinChannel(channel) {
                self.observeChannelMembership(channel)
                self.subscribeChannel(channel)
                self.observeChannel(channel)
                self.observeMessages(channel)
            }
        }
    }
    
    deinit {
        guard let channel else { return }
        unsubscribeChannel(channel)
        unsubscribeLiveStreamChatModeration(stream)
    }
    
    private func setupComposeBarState() {
        isCommunityMember = stream.community?.isJoined ?? true
        isChannelEnabled = !(stream.channel?.isMuted ?? false)
        updateComposeBarState()
    }
    
    private func observeStream(_ stream: AmityStream) {
        streamToken = streamManager.getStream(id: stream.streamId).observe { [weak self] object, error  in
            guard let self, let stream = object.snapshot else { return }
            
            self.isChannelEnabled = stream.channelEnabled
            self.updateComposeBarState()
        }
    }
    
    private func joinChannel(_ channel: AmityChannel, completion: @escaping () -> Void = {}) {
        Task.runOnMainActor {
            do {
                let _ = try await self.channelManager.joinChannel(channelId: channel.channelId)
                Log.add(event: .info, "Joined the live chat channel: \(channel.channelId)")
                completion()
            } catch {
                Log.add(event: .error, "Failed to join live chat channel: \(error.localizedDescription)")
            }
        }
    }
    
    private func subscribeChannel(_ channel: AmityChannel) {
        subscribeChannelWithRetry(channel, attempt: 1)
    }
    
    private func subscribeChannelWithRetry(_ channel: AmityChannel, attempt: Int) {
        let delay = Double.random(in: 2...3) + Double((attempt - 1) * 2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            channel.subscribeEvent { status, error in
                if let error = error {
                    Log.add(event: .error, "Failed to subscribe to the live chat channel (attempt \(attempt)/5): \(error.localizedDescription)")
                    
                    if attempt < 5 {
                        Log.add(event: .info, "Retrying subscription to live chat channel in \(2 * attempt) seconds...")
                        self.subscribeChannelWithRetry(channel, attempt: attempt + 1)
                    } else {
                        Log.add(event: .error, "Failed to subscribe to live chat channel after 5 attempts")
                    }
                } else {
                    Log.add(event: .info, "Subscribed to the live chat channel: \(channel.channelId) on attempt \(attempt)")
                }
            }
        }
    }
    
    private func unsubscribeChannel(_ channel: AmityChannel) {
        guard !channel.model.isInvalidated else { return }
        
        channel.unSubscribeEvent(completion: { status, error in
            if error != nil {
                Log.add(event: .error, "Failed to unsubscribe from the live chat channel: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                Log.add(event: .info, "UnSubscribed to the live chat channel: \(channel.channelId)")
            }
        })
    }
    
    private func subscribeLiveStreamChatModeration(_ stream: AmityStream) {
        stream.subscribeEvent(.chatModeration) { status, error in
            if error != nil {
                Log.add(event: .error, "Failed to subscribe to live stream chat moderation: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                Log.add(event: .info, "Subscribed to live stream chat moderation for stream: \(stream.streamId)")
            }
        }
    }
    
    private func unsubscribeLiveStreamChatModeration(_ stream: AmityStream) {
        guard !stream.model.isInvalidated else { return }
        
        stream.unsubscribeEvent(.chatModeration) { status, error in
            if error != nil {
                Log.add(event: .error, "Failed to unsubscribe from live stream chat moderation: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                Log.add(event: .info, "UnSubscribed from live stream chat moderation for stream: \(stream.streamId)")
            }
        }
    }
    
    private func observeChannel(_ channel: AmityChannel) {
        channelToken = channelManager.getChannel(channelId: channel.channelId).observe { [weak self] object, error in
            guard let self, let channel = object.snapshot else { return }
            
            self.isChannelEnabled = !channel.isMuted
            self.updateComposeBarState()
        }
    }
    
    private func observeChannelMembership(_ channel: AmityChannel) {
        // Setup initial state based on current membership
        if let member = channel.currentMembership {
            isUserMuted = member.isMuted
            updateComposeBarState()
        }
        
        // Observe changes in channel membership
        channelMembershipCancellable = channel.myMembership()
            .sink(receiveValue: { [weak self] member in
                guard let member else { return }
                self?.isUserMuted = member.isMuted
                self?.updateComposeBarState()
            })
    }
    
    private func observeMessages(_ channel: AmityChannel) {
        let queryOptions = AmityMessageQueryOptions(subChannelId: channel.channelId, type: .text, sortOption: .lastCreated)
        messageCollection = chatManager.queryMessages(options: queryOptions)
        
        collectionCancellable = messageCollection?.$snapshots.sink(receiveValue: { [weak self] messages in
            self?.messages = messages.map { MessageModel(message: $0) }
        })
        
        loadingStatusCancellable = messageCollection?.$loadingStatus.sink(receiveValue: { [weak self] status in
            self?.loadingStatus = status
        })
    }
    
    @MainActor
    func sendMessage() async throws {
        guard !messageInput.isEmpty, let channel else { return }
        let createOptions = AmityTextMessageCreateOptions(subChannelId: channel.channelId, text: messageInput)
        let _ = try await chatManager.createTextMessage(options: createOptions)
    }
    
    func loadPreviousMessages() {
        guard let messageCollection, messageCollection.hasNext else { return }
        messageCollection.nextPage()
    }
    
    func deleteMessage(_ messageId: String) async throws {
        let _ = try await chatManager.deleteMessage(messageId: messageId)
    }
    
    func unflagMessage(_ messageId: String) async throws {
        let _ = try await chatManager.unflagMessage(messageId: messageId)
    }
}

