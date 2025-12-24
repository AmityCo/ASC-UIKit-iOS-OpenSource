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
    @Published var showModerationBottomSheet: (show: Bool, message: MessageModel?) = (false, nil)
    @Published var showReactionBar: Bool = false
    @Published var composeBarState: ComposeBarState = .normal
    @Published var isTextEditorFocused: Bool = false
    
    // Channel moderation related data
    @Published var moderators: [String] = []
    @Published var mutedMembers: [String] = []
    
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
    
    private(set) var isCommunityMember: Bool = true
    private var isChannelEnabled: Bool = true
    private var isUserMuted: Bool = false
    private var isUserMutedByModerator: Bool = false
    
    // Delegate functions being set in LiveStreamConferenceView
    var isWaitingCoHost: (() -> (Bool, String))?
    var inviteCoHostAction: (() -> Void)?
    var removeCoHostAction: (() -> Void)?
    var didFinishCoHostInvitationAction: ((AmityUserModel?) -> Void)?
    var swapCameraAction: (() -> Void)?
    var toggleMicAction: (() -> Void)?
    @Published var isMicOn: Bool = true
    
    let room: AmityRoom
    @Published var hostUserId: String = ""
    @Published var coHostUserId: String = ""
    
    var isHost: Bool = false
    var isCoHost: Bool = false
    var isStreamer: Bool {
        return isHost || isCoHost
    }
    private var refreshTask: Task<Void, Never>?
    
    let participantRole: LiveStreamParticipantRole
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
        
        // Priority 3: muted state (when channel is enabled but user is muted by Admin in console)
        if isUserMuted {
            return .muted
        }
        
        // Priority 4: muted state (when channel is enabled but user is muted by a moderator in UIKit)
        if isUserMutedByModerator {
            return .muted
        }
        
        // Default: normal state
        return .normal
    }
    
    public init(room: AmityRoom, participantRole: LiveStreamParticipantRole = .viewer) {
        self.room = room
        self.participantRole = participantRole
        
        let hostId = room.creatorId ?? ""
        self.hostUserId = hostId
        self.isHost = AmityUIKitManagerInternal.shared.currentUserId == hostId
        
        let coHostId = room.participants.first(where: { $0.type == "coHost" })?.userId ?? ""
        self.coHostUserId = coHostId
        self.isCoHost = AmityUIKitManagerInternal.shared.currentUserId == coHostId
        
        self.channel = room.channel
        self.liveReactionViewModel = LiveReactionViewModel(room: room)
        
        guard let channel else { return }
        
        // If the user is streamer, we don't need to change compose bar state during live stream
        // because the streamer can always send messages and reactions
        // Also the streamer has already joined the channel since channel is created by the streamer
        if isStreamer {
            subscribeChannel(channel)
            observeChannel(channel)
            observeMessages(channel)
        } else {
            setupComposeBarState()
//            subscribeLiveStreamChatModeration(stream)
            joinChannel(channel) {
                self.observeChannelMembership(channel)
                self.subscribeChannel(channel)
                self.observeChannel(channel)
                self.observeMessages(channel)
            }
        }
    }
    
    private func setupComposeBarState() {
        isCommunityMember = room.community?.isJoined ?? true
        isChannelEnabled = !(room.channel?.isMuted ?? false)
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
    
//    private func subscribeLiveStreamChatModeration(_ stream: AmityStream) {
//        stream.subscribeEvent(.chatModeration) { status, error in
//            if error != nil {
//                Log.add(event: .error, "Failed to subscribe to live stream chat moderation: \(error?.localizedDescription ?? "Unknown error")")
//            } else {
//                Log.add(event: .info, "Subscribed to live stream chat moderation for stream: \(stream.streamId)")
//            }
//        }
//    }
//    
//    private func unsubscribeLiveStreamChatModeration(_ stream: AmityStream) {
//        guard !stream.model.isInvalidated else { return }
//        
//        stream.unsubscribeEvent(.chatModeration) { status, error in
//            if error != nil {
//                Log.add(event: .error, "Failed to unsubscribe from live stream chat moderation: \(error?.localizedDescription ?? "Unknown error")")
//            } else {
//                Log.add(event: .info, "UnSubscribed from live stream chat moderation for stream: \(stream.streamId)")
//            }
//        }
//    }
    
    private func observeChannel(_ channel: AmityChannel) {
        channelToken = channelManager.getChannel(channelId: channel.channelId).observe { [weak self] object, error in
            guard let self, let channel = object.snapshot else { return }
            
            self.channel = channel
            
            // Channel Moderation related data
            if let moderators = channel.metadata?["moderators"] as? [String] {
                self.moderators = moderators
            }
            
            if let mutedMembers = channel.metadata?["mutedMembers"] as? [String] {
                self.mutedMembers = mutedMembers
            }
            
            if !isStreamer {
                self.isChannelEnabled = !channel.isMuted
                self.isUserMutedByModerator = isMuted(userId: AmityUIKitManagerInternal.shared.currentUserId)
                self.updateComposeBarState()
            }
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
        MessageCache.shared.setFlagStatus(messageId: messageId, value: false)
    }
    
    @MainActor
    func promoteModerator(userId: String) async throws {
        guard let channel = self.channel else { return }
        let builder = AmityChannelUpdateBuilder(channelId: channel.channelId)
        var metadata: [String: Any] = [:]
        
        if var moderators = channel.metadata?["moderators"] as? [String] {
            moderators.append(userId)
            metadata["moderators"] = moderators
        } else {
            metadata["moderators"] = [userId]
        }
        
        if let mutedMembers = channel.metadata?["mutedMembers"] as? [String] {
            metadata["mutedMembers"] = mutedMembers
        }
        
        builder.setMetadata(metadata)
        try await channelManager.addRole(channelId: channel.channelId, userId: userId, role: AmityChannelRole.channelModerator.rawValue)
        self.channel = try await channelManager.updateChannel(builder: builder)
    }
    
    @MainActor
    func demoteModerator(userId: String) async throws {
        guard let channel = self.channel else { return }
        let builder = AmityChannelUpdateBuilder(channelId: channel.channelId)
        var metadata: [String: Any] = [:]
        
        if var moderators = channel.metadata?["moderators"] as? [String] {
            moderators.removeAll { $0 == userId }
            metadata["moderators"] = moderators
        }
        
        if let mutedMembers = channel.metadata?["mutedMembers"] as? [String] {
            metadata["mutedMembers"] = mutedMembers
        }
        
        builder.setMetadata(metadata)
        
        try await channelManager.removeRole(channelId: channel.channelId, userId: userId, role: AmityChannelRole.channelModerator.rawValue)
        self.channel = try await channelManager.updateChannel(builder: builder)
    }
    
    @MainActor
    func muteMember(userId: String) async throws {
        guard let channel = self.channel else { return }
        let builder = AmityChannelUpdateBuilder(channelId: channel.channelId)
        var metadata: [String: Any] = [:]
        
        if let moderators = channel.metadata?["moderators"] as? [String] {
            metadata["moderators"] = moderators
        }
        
        if var mutedMembers = channel.metadata?["mutedMembers"] as? [String] {
            mutedMembers.append(userId)
            metadata["mutedMembers"] = mutedMembers
        } else {
            metadata["mutedMembers"] = [userId]
        }
        
        builder.setMetadata(metadata)
        self.channel = try await channelManager.updateChannel(builder: builder)
    }
    
    @MainActor
    func unmuteMember(userId: String) async throws {
        guard let channel = self.channel else { return }
        let builder = AmityChannelUpdateBuilder(channelId: channel.channelId)
        var metadata: [String: Any] = [:]
        
        if let moderators = channel.metadata?["moderators"] as? [String] {
            metadata["moderators"] = moderators
        }
        
        if var mutedMembers = channel.metadata?["mutedMembers"] as? [String] {
            mutedMembers.removeAll { $0 == userId }
            metadata["mutedMembers"] = mutedMembers
        }
        
        builder.setMetadata(metadata)
        self.channel = try await channelManager.updateChannel(builder: builder)
    }
    
    func refreshHostAndCoHostId(room: AmityRoom) {
        let previousTask = refreshTask
        
        refreshTask = Task { @MainActor [weak self] in
            await previousTask?.value
            
            guard let self = self else { return }
            
            let newHostUserId = room.creatorId ?? ""
            let newCoHostUserId = room.participants.first(where: { $0.type == "coHost" })?.userId ?? ""
            
            if participantRole == .host {
                do {
                    if !newCoHostUserId.isEmpty && !self.isModerator(userId: newCoHostUserId) {
                        try await self.promoteModerator(userId: newCoHostUserId)
                    } else if newCoHostUserId.isEmpty && !self.coHostUserId.isEmpty && self.isModerator(userId: self.coHostUserId) {
                        Log.add(event: .info, "Demoting previous co-host (\(self.coHostUserId)) from moderator role")
                        try await self.demoteModerator(userId: self.coHostUserId)
                    }
                } catch {
                    print("Error updating moderator: \(error)")
                }
            }
            
            self.hostUserId = newHostUserId
            self.coHostUserId = newCoHostUserId
            self.isHost = AmityUIKitManagerInternal.shared.currentUserId == newHostUserId
            self.isCoHost = AmityUIKitManagerInternal.shared.currentUserId == newCoHostUserId
        }
    }
    func inviteAsCoHost(userId: String) async throws {
        try await room.createInvitation(userId)
    }
    
    func isModerator(userId: String) -> Bool {
        return moderators.contains(item: userId)
    }
    
    func isMuted(userId: String) -> Bool {
        return mutedMembers.contains(item: userId)
    }
    
    func cleanup() {
        // Cancel all ongoing observations
        collectionCancellable?.cancel()
        collectionCancellable = nil
        
        loadingStatusCancellable?.cancel()
        loadingStatusCancellable = nil
        
        channelMembershipCancellable?.cancel()
        channelMembershipCancellable = nil
        
        // Invalidate tokens
        streamToken?.invalidate()
        streamToken = nil
        
        channelToken?.invalidate()
        channelToken = nil
        
        // Clear collection
        messageCollection = nil
        
        // Clear live reaction VM
        liveReactionViewModel.cleanup()
        
        // Unsubscribe from channel if it exists
        guard let channel else { return }
        unsubscribeChannel(channel)
//        unsubscribeLiveStreamChatModeration(stream)
    }
}
