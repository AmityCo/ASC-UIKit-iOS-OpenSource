//
//  AmityCreateLiveStreamViewModel.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 3/3/25.
//

import SwiftUI
import AmitySDK
import Combine
import AmityLiveKit

enum LiveStreamEndReason: String {
    case manual
    case maxDuration
    case connectionIssue
    case terminated
    case notApproved
    case leaveAsCoHost
    case coHostLeave
}

enum LiveStreamUIState: Equatable {
    
    /// User can setup title, description & thumbnail (upload thumbnail) in this state. Shutter button is disabled
    case setup
    
    /// Title should be present & thumbnail (if selected) should have been uploaded in this state.
    /// UI is ready for the user to start live stream. Shutter button is now enabled.
    case readyToStart
    
    /// In this state we create stream object, post & evenutually start broadcasting etc
    /// UI shows some kind of loading state. Shutter button is hidden.
    case started
    
    /// In this state we have started publishing the live stream. We will also refer to broadcaster state, post deleted status, stream termination status and modify UI.
    /// Any other state such as loss of network connection, reconnection or error after stream has started, the UI state will still be streaming.
    case streaming
        
    /// Stream is about to end. UI can reach this state when live stream runs upto its maximum duration or ended manually
    case ending(reason: LiveStreamEndReason)
    
    /// Live stream is now ended. This can be due to interruption, termination or manual
    case ended(reason: LiveStreamEndReason)
    
    var isStreaming: Bool {
        return self == .streaming || self == .ending(reason: .maxDuration)
    }
    
    // We implement equatable by ourseles because of the use of enum with associated type
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.setup, .setup):
            return true
        case (.readyToStart, .readyToStart):
            return true
        case (.started, .started):
            return true
        case (.streaming, .streaming):
            return true
        case (let .ending(reason1), let .ending(reason2)):
            return reason1 == reason2
        case (let .ended(reason1), let .ended(reason2)):
            return true
        default:
            return false
        }
    }
}

class LiveStreamConferenceViewModel: ObservableObject {
    
    private var communityManager = CommunityManager()
    private var userManager = UserManager()
    private var postManager = PostManager()
    private var streamManager = StreamManager()
    private var roomManager = RoomManager()
    private var channelManager = ChannelManager()
    private var invitationManager = InvitationManager()
    private var fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    private var targetObjectToken: AmityNotificationToken?
    private var livePostToken: AmityNotificationToken?
    private var liveRoomToken: AmityNotificationToken?
    
    // Target
    private var targetId: String
    var targetType: AmityPostTargetType
    @Published var targetDisplayName: String = AmityLocalizedStringSet.Social.liveStreamMyTimelineLabel.localizedString
    
    // UIState for broadcaster
    @Published var broadcasterState: LiveStreamBroadcasterState = .idle
    
    // Room Presense state
    private var presenceRepository: AmityRoomPresenceRepository?
    private var presenceTimer: Timer?
    @Published var watchingCount: Int = 0
    
    // Flag to keep track whether `broadcaster` has been configured to start live stream.
    private var isBroadcasterSetupComplete = false
    
    // States
    @Published var currentState: LiveStreamUIState = .setup
    @Published var isReconnecting: Bool = false // Prev state is .connected || .disconnected & new state is .connecting
    
    // Thumbnail
    @Published var selectedImage: UIImage?
    @Published var isUploadingThumbnail = false
    @Published var thumbnailUploadProgress = 0.0
    private var thumbnailData: AmityImageData?
    
    // Duration & Timer
    @Published var liveDuration = "0:00"
    @Published var liveStreamEndCountdown: Int = LiveStreamTimerService.threshold.streamEndCountdownDuration
    @Published var isLiveStreamEndCountdownStarted = false
    private let timerService = LiveStreamTimerService()
        
    // Idle timer to keep screen awake
    var currentAppIdleTimerDisabled = false
    
    // Stream Information
    @Published var streamTitle: String = ""
    @Published var streamDescription: String = ""
    
    // Settings
    @Published var isLiveChatDisabled: Bool = false
    
    // ViewModels
    @Published var liveStreamChatViewModel: AmityLiveStreamChatViewModel?
    
    /// We use this post to start publishing live stream, and navigate to post detail page, after the user finish streaming.
    private var internalCreatedPost: AmityPost?
    var createdPost: AmityPost? {
        if internalCreatedPost?.isInvalidated == false {
            return internalCreatedPost
        }
        
        return nil
    }
    
    private var internalCreatedRoom: AmityRoom?
    var createdRoom: AmityRoom? {
        if internalCreatedRoom?.isInvalidated == false {
            return internalCreatedRoom
        }
        
        return nil
    }
    
    private var internalCreatedEvent: AmityEvent?
    var createdEvent: AmityEvent? {
        if internalCreatedEvent?.model.isInvalidated == false {
            return internalCreatedEvent
        }
        
        return nil
    }
    
    // Co-host streaming properties
    let participantRole: LiveStreamParticipantRole
    let broadcasterViewModel: LiveStreamBroadcasterViewModel
    
    @Published var invitedCoHost: (isWaiting: Bool, user: AmityUserModel?, invitationAccepted: Bool) = (false, nil, false)
    var coHostInvitation: AmityInvitation?
    
    var didCoHostLeave: (() -> Void)?
    var didCoHostJoined: ((Bool) -> Void)?
    
    // cancellables
    var disposeBag = Set<AnyCancellable>()
    
    init(targetId: String, targetType: AmityPostTargetType, participantRole: LiveStreamParticipantRole = .host, broadcasterViewModel: LiveStreamBroadcasterViewModel = LiveStreamBroadcasterViewModel()) {
        self.targetId = targetId
        self.targetType = targetType
        self.participantRole = participantRole
        self.broadcasterViewModel = broadcasterViewModel
        self.setup()
        self.observeBroadcasterState()
    }
    
    convenience init(event: AmityEvent, participantRole: LiveStreamParticipantRole = .host, broadcasterViewModel: LiveStreamBroadcasterViewModel = LiveStreamBroadcasterViewModel()) {
        self.init(targetId: event.targetCommunity?.communityId ?? "", targetType: .community, participantRole: participantRole, broadcasterViewModel: broadcasterViewModel)
        self.internalCreatedEvent = event
        
        // If we have event, prefill title & description
        if let createdEvent, let room = createdEvent.room {
            self.streamTitle = room.title ?? ""
            self.streamDescription = room.description ?? ""
        }
    }
    
    private func setup() {
        self.fetchTargetInfo(targetId: targetId, targetType: targetType)
        
        // Observe app life cycle notfications
//        NotificationCenter.default.addObserver(self, selector: #selector(suspendLiveStream), name: UIApplication.didEnterBackgroundNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(resumeLiveStream), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func observeBroadcasterState() {
        broadcasterViewModel.$broadcasterState
            .sink { [weak self] state in
                Log.add(event: .info, "Broadcaster State: \(state.strValue)")
                
                switch state {
                case .connected:
                    // Invalidate reconnection timer
                    self?.timerService.stopReconnectionTimer()
                    self?.isReconnecting = false
                case .reconnecting, .disconnected:
                    self?.updateLiveStreamReconnectionStatus()
                case .idle, .connecting, .disconnecting:
                   break
                @unknown default:
                    break
                }
                
                self?.broadcasterState = state
            }
            .store(in: &disposeBag)
    }
    
    func switchCamera() {
        broadcasterViewModel.switchCamera()
    }
    
    func toggleMicrophone() {
        broadcasterViewModel.toggleMicrophone()
    }
    
    func setupBroadcaster(previewSize: CGSize) {
        // We want to setup broadcaster only once.
        guard !isBroadcasterSetupComplete else { return }
        
        // Flag
        isBroadcasterSetupComplete = true
    }
    
    func startStream(title: String, description: String) {
        guard currentState != .streaming else { return }
        
        // #1. Validate inputs
        let sanitizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedTitle.isEmpty else { return }
        
        // #2
        // Make sure thumbnail is not in uploading state
        guard !isUploadingThumbnail else { return }
        
        // Prevent screen display from sleep
        if !UIApplication.shared.isIdleTimerDisabled {
            currentAppIdleTimerDisabled = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        currentState = .started
                
        Task { @MainActor in
            do {
                // We don't need to create room and post if it came from event.
                // Event already has room and post associated with it.
                if let createdEvent {
                    self.internalCreatedRoom = createdEvent.room
                    Log.add(event: .info, "Room associated to event: \(internalCreatedRoom?.roomId ?? "nil")")
                    
                    self.internalCreatedPost = createdEvent.room?.post
                    Log.add(event: .info, "Post associated to event: \(createdPost?.postId ?? "nil")")
                    
                } else {
                    // #3 Create Room
                    let createRoomOptions = AmityRoomCreateOptions(title: sanitizedTitle,
                                                                   description: sanitizedDescription,
                                                                   thumbnailFileId: thumbnailData?.fileId)
                    let room = try await roomManager.createRoom(options: createRoomOptions)
                    self.internalCreatedRoom = room
                    Log.add(event: .info, "Room Created: \(room.roomId)")

                    // #4 Create Post
                    let roomId = room.roomId
                    let roomPostBuilder = AmityRoomPostBuilder(roomId: roomId, text: sanitizedDescription)
                    roomPostBuilder.setTitle(sanitizedTitle)
                    
                    let post = try await postManager.createLiveStreamRoomPost(builder: roomPostBuilder, targetId: self.targetId, targetType: self.targetType, metadata: nil, mentionees: nil)
                    self.internalCreatedPost = post
                    Log.add(event: .info, "Post Created: \(post.postId)")
                }
                
                guard let room = createdRoom else {
                    LiveStreamAlert.shared.show(for: .streamError)
                    currentState = .setup
                    Log.add(event: .info, "Room is not available and cannot start live stream.")
                    return
                }
                
                // #5 Create Live Stream Channel
                if let channel = try await room.getLiveChat() {
                    Log.add(event: .info, "Retrieved live chat channel: \(channel.channelId)")
                    // If live chat is enabled, we will mute the channel since the beginning of live stream
                    if isLiveChatDisabled {
                        try await channelManager.muteChannel(channelId: channel.channelId)
                    }
                    
                    // Get attached room for chat view model
                    if let attachedToRoom = channel.attachedToRoom {
                        self.liveStreamChatViewModel = AmityLiveStreamChatViewModel(room: attachedToRoom, participantRole: .host)
                    }
                }
                
                // #6 Generate room token & URL
                guard let roomTokenResult = try await roomManager.generateRoomToken(roomId: room.roomId) else {
                    LiveStreamAlert.shared.show(for: .streamError)
                    currentState = .setup
                    Log.add(event: .error, "Room token generation failed and cannot start live stream. Room type should be 'coHosts'.")
                    return
                }
                
                broadcasterViewModel.startBroadcast(url: roomTokenResult.url, token: roomTokenResult.token, captureRatio: .full)
                Log.add(event: .info, "Broadcast started...")
                                
                // Start timer
                updateLiveStreamTimerStatus()
                Log.add(event: .info, "Starting live timer...")
                
                // Update ui state
                currentState = .streaming
                Log.add(event: .info, "UI State chagned to streaming...")
                
                // Observe room event
                subscribeRoomEventAndObserve(subscribeEvent: true)
                subscribePostEventAndObserve(subscribeEvent: true)
                Log.add(event: .info, "Obversing stream to handle terminated events")
                
                // Observe co-host events
                observeCoHostEvents(room: room)
                Log.add(event: .info, "Obversing co-host events")
                
                // Observe watching count
                self.presenceRepository = AmityRoomPresenceRepository(client: AmityUIKitManagerInternal.shared.client, roomId: room.roomId)
                observeWatchingCount()
                Log.add(event: .info, "Obversing watching count from room")
                
            } catch let error {
                // Show alert
                LiveStreamAlert.shared.show(for: .streamError)
                // Update ui state
                currentState = .setup
                
                Log.add(event: .error, "Error while creating live stream room \(error.localizedDescription)")
            }
        }
    }
    
    func startStreamAsCoHost(post: AmityPostModel) {
        guard let room = post.room else { return }
        currentState = .started
        
        Task { @MainActor in
            do {
                self.internalCreatedPost = post.object
                self.internalCreatedRoom = room
                Log.add(event: .info, "Post Created: \(post.postId)")
                
                // #1 Create Live Stream Channel
                if let channel = try await room.getLiveChat() {
                    // If live chat is enabled, we will mute the channel since the beginning of live stream
                    if isLiveChatDisabled {
                        try await channelManager.muteChannel(channelId: channel.channelId)
                    }
                    self.liveStreamChatViewModel = AmityLiveStreamChatViewModel(room: room, participantRole: .coHost)
                }
                
                // #2 Generate room token & URL
                guard let roomTokenResult = try await roomManager.generateRoomToken(roomId: room.roomId) else { return }
                broadcasterViewModel.startBroadcast(url: roomTokenResult.url, token: roomTokenResult.token, captureRatio: .half)
                
                Log.add(event: .info, "Broadcast started...")
                
                // Start timer
                updateLiveStreamTimerStatus()
                Log.add(event: .info, "Starting live timer...")
                
                // Update ui state
                currentState = .streaming
                Log.add(event: .info, "UI State chagned to streaming...")
                
                // Observe room event
                // Doesn't need to subscribe event cause LiveStreamViewerView already subscribe these events
                // UI flow of co-host --- LiveStreamViewerView -> BackstageView -> LiveStreamConferenceView
                subscribeRoomEventAndObserve(subscribeEvent: false)
                subscribePostEventAndObserve(subscribeEvent: false)
                Log.add(event: .info, "Obversing stream to handle terminated events")
                
                // Observe co-host events
                observeCoHostEvents(room: room)
                Log.add(event: .info, "Obversing co-host events")
                
                // Observe watching count
                self.presenceRepository = AmityRoomPresenceRepository(client: AmityUIKitManagerInternal.shared.client, roomId: room.roomId)
                observeWatchingCount()
                Log.add(event: .info, "Obversing watching count from room")
                
                didCoHostJoined?(true)
            } catch let error {
                // Show alert
                LiveStreamAlert.shared.show(for: .streamError)
                
                didCoHostJoined?(false)
                
                Log.add(event: .error, "Error while connecting live stream room \(error.localizedDescription)")
            }
        }
    }
    
    // When user taps on end live button
    func endLiveStream(reason: LiveStreamEndReason) {
        currentState = .ending(reason: .manual)
        Log.add(event: .info, "Ending live stream, Reason: \(reason.rawValue)")
        
        // Stop broadcast and leave the room if it is a co-host
        if participantRole == .coHost {
            Task.runOnMainActor { [weak self] in
                do {
                    if let room = self?.createdRoom {
                        try await self?.roomManager.leaveRoom(roomId: room.roomId)
                    }
                    
                    // If co-host leave as co-host, notify the handler to switch UI back to viewer
                    // If it is terminated by the moderation, we don't need to switch UI back to viewer
                    if reason == .leaveAsCoHost && reason != .terminated {
                        self?.didCoHostLeave?()
                    }
        
                    self?.stopBroadcastAndCleanup(reason: reason)
                } catch {
                    if reason == .leaveAsCoHost && reason != .terminated {
                        self?.didCoHostLeave?()
                    }
                    
                    self?.stopBroadcastAndCleanup(reason: reason)
                }
            }
        } else {
            // Stop broadcast and stop the room if it is a host
            Task.runOnMainActor { [weak self] in
                do {
                    if let room = self?.createdRoom {
                        try await self?.roomManager.stopRoom(roomId: room.roomId)
                    }
                    
                    self?.stopBroadcastAndCleanup(reason: reason)
                } catch {
                    self?.stopBroadcastAndCleanup(reason: reason)
                }
            }
        }
    }
    
    func stopBroadcastAndCleanup(reason: LiveStreamEndReason) {
        broadcasterViewModel.stopBroadcast()
        currentState = .ended(reason: reason)
        cleanup(reason)
    }
    
    func observeCoHostEvents(room: AmityRoom) {
        roomManager.getCoHostEvent(roomId: room.roomId)
            .sink(receiveValue: { [weak self] event in
                Log.add(event: .info, "Received co-host Event: \(event.type)")
                self?.coHostInvitation = event.invitation
    
                // Update invited co-host waiting status if invitation is rejected and co-host left from back-stage or stage
                if event.type == .invitationRejected {
                    self?.invitedCoHost = (false, nil, false)
                    Toast.showToast(style: .warning, message: "Co-host declined the invitation.", bottomPadding: 60)
                } else if event.type == .invitationAccepted {
                    self?.invitedCoHost.invitationAccepted = true
                    Toast.showToast(style: .success, message: "Co-host accepted the invitation.", bottomPadding: 60)
                } else if event.type == .coHostLeft {
                    self?.invitedCoHost = (false, nil, false)
                                        
                    if let hostParticipant = room.participants.first(where: { $0.type == "host" }), let actorInternalId = event.actorInternalId, actorInternalId == hostParticipant.userInternalId {
                        return
                    } else {
                        Toast.showToast(style: .success, message: "Co-host left the stage.", bottomPadding: 60)
                    }
                    
                } else if event.type == .coHostRemoved {
                    if self?.participantRole == .host {
                        self?.invitedCoHost = (false, nil, false)
                    } else if self?.participantRole == .coHost {
                        // end the co-host streaming if co-host is kicked from live stream
                        self?.endLiveStream(reason: .leaveAsCoHost)
                    }
                }
            })
            .store(in: &disposeBag)
    }
    
    func observeWatchingCount() {
        self.presenceTimer?.invalidate()
        self.presenceTimer = nil
        
        self.presenceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self]  _ in
            Task.runOnMainActor {
                do {
                    self?.watchingCount = try await self?.presenceRepository?.getRoomUserCount() ?? 0
                } catch {
                    Log.add(event: .error, "Error while fetching room watching count: \(error.localizedDescription)")
                }
            }
        })
    }
        
    @MainActor
    func cancelCoHostInvitation() async {
        if let createdRoom, let coHostInvitation {
            do {
                try await createdRoom.cancelInvitation(coHostInvitation.invitationId)
                Toast.showToast(style: .success, message: "Invitation cancelled.", bottomPadding: 60)
            } catch {
                Toast.showToast(style: .warning, message: "Failed to cancel invitation.", bottomPadding: 60)
            }
        }
    }
    
    @MainActor
    func removeCoHostFromStream(userId: String) async {
        if let createdRoom {
            do {
                try await roomManager.removeCohost(roomId: createdRoom.roomId, userId: userId)
                Toast.showToast(style: .success, message: "Co-host removed from live.", bottomPadding: 60)
            } catch {
                Toast.showToast(style: .warning, message: "Failed to remove co-host.", bottomPadding: 60)
            }
        }
    }
    
    
    func editLiveStream(chatDisabled: Bool) {
        guard let createdRoom else { return }
        Task.runOnMainActor {
            do {
                if chatDisabled {
                    try await self.channelManager.muteChannel(channelId: createdRoom.channel?.channelId ?? "")
                } else {
                    try await self.channelManager.unmuteChannel(channelId: createdRoom.channel?.channelId ?? "")
                }
            } catch {
                Log.add(event: .error, "Error while editing live stream \(error.localizedDescription)")
            }
        }
    }
    
    func cleanup(_ reason: LiveStreamEndReason) {
        targetObjectToken?.invalidate()
        liveRoomToken?.invalidate()
        livePostToken?.invalidate()
        
        targetObjectToken = nil
        liveRoomToken = nil
        livePostToken = nil
        
        // Cleanup states
        isReconnecting = false
        isUploadingThumbnail = false
        liveStreamEndCountdown = 0
        selectedImage = nil
        thumbnailData = nil
        
        disposeBag.removeAll()
        
        if !currentAppIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        NotificationCenter.default.removeObserver(self)
        
        // Invalidate timers
        timerService.invalidateTimers()
        presenceTimer?.invalidate()
        presenceTimer = nil
        
        // If co-host left or being removed, UI state will change to LiveStreamViewerView which still needs to observe room and post events...
        // So we only unsubscribe events when the participant is host
        if participantRole == .host {
            if createdPost?.isInvalidated == false {
                createdPost?.unsubscribeEvent(.post, withCompletion: { success, error in
                    Log.add(event: .info, "Unsubscribing post event status: \(success) Error: \(String(describing: error))")
                })
            }
            
            if createdRoom?.isInvalidated == false {
                createdRoom?.unsubscribeEvent() { success, error in
                    Log.add(event: .info, "Unsubscribing room event status: \(success) Error: \(String(describing: error))")
                }
            }
        }
    }
    
    func subscribePostEventAndObserve(subscribeEvent: Bool) {
        guard let postId = createdPost?.postId else { return }
        
        if subscribeEvent {
            createdPost?.subscribeEvent(.post, withCompletion: { success, error in
                Log.add(event: .info, "Subscribing post event status: \(success) Error: \(String(describing: error))")
            })
        }
        
        livePostToken = postManager.getPost(withId: postId).observe{ [weak self] liveObject, error in
            guard let self, let snapshot = liveObject.snapshot else { return }
            
            if snapshot.getFeedType() == .declined {
                self.endLiveStream(reason: .notApproved)
            }
            
            if snapshot.isDeleted {
                livePostToken?.invalidate()
                livePostToken = nil
                
                self.endLiveStream(reason: .terminated)
            }
        }
    }
    
    func subscribeRoomEventAndObserve(subscribeEvent: Bool) {
        guard let roomId = createdRoom?.roomId else { return }
        
        if subscribeEvent {
            createdRoom?.subscribeEvent { success, error in
                Log.add(event: .info, "Subscribing room event status: \(success) Error: \(String(describing: error))")
            }
        }
        
        liveRoomToken = roomManager.getRoom(roomId: roomId).observe { [weak self] liveObject, error in
            guard let self, let snapshot = liveObject.snapshot else { return }
            
            self.liveStreamChatViewModel?.refreshHostAndCoHostId(room: snapshot)
            
            // end co-host streaming if the room is ended by the host...
            if participantRole == .coHost && snapshot.status == .ended {
                endLiveStream(reason: .manual)
            }
            
            if snapshot.isDeleted {
                liveRoomToken?.invalidate()
                liveRoomToken = nil
                
                self.endLiveStream(reason: .terminated)
            }
            
            if let terminateLabels = snapshot.moderation?.terminateLabels, !terminateLabels.isEmpty {
                liveRoomToken?.invalidate()
                liveRoomToken = nil
                
                self.endLiveStream(reason: .terminated)
            }
        }
    }
    
    func updateLiveStreamTimerStatus() {
        timerService.startLiveDurationTimer { [weak self] duration, secondElapsed in
            guard let self else { return }
            if duration.hasPrefix("00") {
                let newDuration = String(duration.dropFirst())
                self.liveDuration = newDuration
            } else {
                self.liveDuration = duration
            }
            
            // Show warning toast 3 minutes before live stream reaches its max duration threshold
            if secondElapsed >= LiveStreamTimerService.threshold.streamMaxLiveDuration - LiveStreamTimerService.threshold.streamEndWarningDuration && currentState == .streaming {
                currentState = .ending(reason: .maxDuration)
            }
            
            // 10 seconds counter should now be enabled
            if secondElapsed >= LiveStreamTimerService.threshold.streamMaxLiveDuration - LiveStreamTimerService.threshold.streamEndCountdownDuration && !isLiveStreamEndCountdownStarted {
                currentState = .ending(reason: .maxDuration)
                
                self.timerService.startLivestreamCountdownTimer { countdown in
                    self.liveStreamEndCountdown = countdown
                }
                
                isLiveStreamEndCountdownStarted = true
            }
            
            // If we reach max threshold, we end the live stream
            if secondElapsed >= LiveStreamTimerService.threshold.streamMaxLiveDuration {
                self.timerService.stopLiveDurationTimer()
                self.timerService.stopLivestreamCountdownTimer()
                
                self.endLiveStream(reason: .maxDuration)
            }
        }
    }
    
    func updateLiveStreamReconnectionStatus() {
        guard case .streaming = currentState, !isReconnecting else { return }
        
        isReconnecting = true
        timerService.startReconnectionTimer { [weak self] seconds in
            guard let self else { return }
            
            if seconds > LiveStreamTimerService.threshold.streamReconnectionWaitDuration {
                self.isReconnecting = false
                self.endLiveStream(reason: .connectionIssue)
            }
        }
    }
}

extension LiveStreamConferenceViewModel {
    
    func fetchTargetInfo(targetId: String, targetType: AmityPostTargetType) {
        switch targetType {
        case .community:
            targetObjectToken = communityManager.getCommunity(withId: targetId).observeOnce { [weak self] liveObject, error in
                guard let self, let snapshot = liveObject.snapshot else { return }
                
                self.targetObjectToken?.invalidate()
                self.targetObjectToken = nil
                self.targetDisplayName = snapshot.displayName
            }
        case .user:
            //Note:
            //At the moment we do not have any requirement to fetch user object.
            targetObjectToken = userManager.getUser(withId: targetId).observeOnce({ [weak self] liveObject, error in
                guard let self, let _ = liveObject.snapshot else { return }
                
                self.targetObjectToken?.invalidate()
                self.targetObjectToken = nil
                self.targetDisplayName = AmityLocalizedStringSet.Social.liveStreamMyTimelineLabel.localizedString
            })
        @unknown default:
            break
        }
    }
    
    func uploadThumbnail(image: UIImage?) {
        guard let image else { return }
        isUploadingThumbnail = true
        
        Task { @MainActor in
            do {
                let imageData = try await fileRepository.uploadImage(image) { [weak self] progress in
                    guard let self else { return }
                    self.thumbnailUploadProgress = progress * 100
                }
                self.updateThumbnailStatus(imageData: imageData)
                Log.add(event: .info, "Thumbnail uploaded \(imageData.fileId)")
            } catch let error {
                self.updateThumbnailStatus(imageData: nil)
                
                LiveStreamAlert.shared.show(for: .thumbnailError(error.isAmityErrorCode(.business)))
                Log.add(event: .info, "Error while uploading thumbanil \(error.localizedDescription)")
            }
        }
    }
    
    func updateThumbnailStatus(imageData: AmityImageData?) {
        if let imageData {
            self.thumbnailData = imageData
        } else {
            self.thumbnailData = nil
            self.selectedImage = nil
        }
        
        self.isUploadingThumbnail = false
    }
}

extension LiveStreamUIState {
    
    var strValue: String {
        switch self {
        case .setup:
            "Setup"
        case .readyToStart:
            "Ready to start"
        case .started:
            "Started"
        case .streaming:
            "Streaming"
        case .ending:
            "Ending"
        case .ended(let reason):
            "Ended with reason: \(reason.rawValue)"
        }
    }
}
