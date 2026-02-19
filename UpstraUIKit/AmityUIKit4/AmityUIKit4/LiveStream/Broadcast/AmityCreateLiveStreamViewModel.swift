//
//  AmityCreateLiveStreamViewModel.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 3/3/25.
//

import SwiftUI
import AmityLiveVideoBroadcastKit
import AmitySDK
import Combine

enum LiveStreamEndReason: String {
    case manual
    case maxDuration
    case connectionIssue
    case terminated
    case notApproved
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
        
    /// Stream is about to end. UI can reach this state when live stream runs upto its maximum duration.
    case ending
    
    /// Live stream is now ended. This can be due to interruption, termination or manual
    case ended(reason: LiveStreamEndReason)
    
    var isStreaming: Bool {
        return self == .streaming || self == .ending
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
        case (.ending, .ending):
            return true
        case (let .ended(reason1), let .ended(reason2)):
            return reason1 == reason2
        default:
            return false
        }
    }
}

class AmityCreateLiveStreamViewModel: ObservableObject, AmityVideoBroadcasterDelegate {
    
    private var communityManager = CommunityManager()
    private var userManager = UserManager()
    private var postManager = PostManager()
    private var streamManager = StreamManager()
    private var channelManager = ChannelManager()
    private var fileRepository = AmityFileRepository(client: AmityUIKitManagerInternal.shared.client)
    
    private var targetObjectToken: AmityNotificationToken?
    private var livePostToken: AmityNotificationToken?
    private var liveStreamToken: AmityNotificationToken?
    
    // Target
    private var targetId: String
    var targetType: AmityPostTargetType
    @Published var targetDisplayName: String = AmityLocalizedStringSet.Social.liveStreamMyTimelineLabel.localizedString
    
    // Broadcaster
    let broadcaster: AmityVideoBroadcaster = AmityVideoBroadcaster(client: AmityUIKitManagerInternal.shared.client)
    // Flag to keep track whether `broadcaster` has been configured to start live stream.
    private var isBroadcasterSetupComplete = false
    
    // States
    @Published var currentState: LiveStreamUIState = .setup
    @Published var broadcasterState: AmityStreamBroadcasterState = .idle
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
    @Published var liveStreamChatViewModel: AmityLiveStreamChatViewModel?
    
    /// We use this post to start publishing live stream, and navigate to post detail page, after the user finish streaming.
    var createdPost: AmityPost?
    var createdStream: AmityStream?

    init(targetId: String, targetType: AmityPostTargetType) {
        self.targetId = targetId
        self.targetType = targetType
        self.broadcaster.delegate = self
        self.setup()
    }
    
    private func setup() {
        self.fetchTargetInfo(targetId: targetId, targetType: targetType)
        
        // Observe app life cycle notfications
        NotificationCenter.default.addObserver(self, selector: #selector(suspendLiveStream), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeLiveStream), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func suspendLiveStream() {
        guard currentState == .streaming, let _ = createdStream else { return }
        broadcaster.suspendPublish()
    }
    
    @objc func resumeLiveStream() {
        guard let stream = createdStream else { return }
        
        broadcaster.startPublish(existingStreamId: stream.streamId)
    }
    
    func switchCamera() {
        switch broadcaster.switchCamera {
        case .front:
            broadcaster.switchCamera = .back
        case .back:
            broadcaster.switchCamera = .front
        @unknown default:
            assertionFailure("Unknown case for switching camera while broadcasting")
        }
    }
    
    func setupBroadcaster(previewSize: CGSize) {
        // We want to setup broadcaster only once.
        guard !isBroadcasterSetupComplete else { return }
        
        // Flag
        isBroadcasterSetupComplete = true
        
        let config = AmityStreamBroadcasterConfiguration()
        config.canvasFitting = .fill
        config.bitrate = 3_000_000 // 3mbps
        config.frameRate = .fps30
        
        broadcaster.delegate = self
        
        let videoResolution = CGSize(width: previewSize.width * 2, height: previewSize.height * 2)
        Log.add(event: .info, """
              >> Broadcaster Setup
              Canvas Fitting: Fill
              Bitrate: 3_000_000
              FrameRate: .fps30
              VideoResolution: \(videoResolution)
              """)
        broadcaster.videoResolution = videoResolution
        broadcaster.setup(with: config)
        // Note: Bug on broadcaster sdk
        // If we change the camera state before setup, it seems to ignore it and always use back camera
        broadcaster.switchCamera = .front
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
                // #3 Create Stream
                let stream = try await streamManager.createStream(title: sanitizedTitle, description: sanitizedDescription.isEmpty ? nil : sanitizedDescription, thumbnail: thumbnailData, metadata: nil, chatEnabled: true)
                self.createdStream = stream
                Log.add(event: .info, "Stream Created: \(stream.streamId)")

                // #4 Create Post
                let postText = "\(sanitizedTitle)\n\n\(sanitizedDescription)"
                let streamId = stream.streamId
                let streamPostBuilder = AmityLiveStreamPostBuilder(streamId: streamId, text: postText)
                let post = try await postManager.createStreamPost(builder: streamPostBuilder, targetId: self.targetId, targetType: self.targetType, metadata: nil, mentionees: nil)
                self.createdPost = post
                Log.add(event: .info, "Post Created: \(post.postId)")
                
                // #5 Create Live Stream Channel
                if let channel = try await stream.getLiveChat(), let updatedStream = streamManager.getStream(id: streamId).snapshot {
                    // If live chat is enabled, we will mute the channel since the beginning of live stream
                    if isLiveChatDisabled {
                        try await channelManager.muteChannel(channelId: channel.channelId)
                    }
                    self.createdStream = updatedStream
                    self.liveStreamChatViewModel = AmityLiveStreamChatViewModel(stream: updatedStream)
                }

                // #6 Start publishing
                broadcaster.startPublish(existingStreamId: streamId)
                Log.add(event: .info, "Broadcast started...")
                                
                // Start timer
                updateLiveStreamTimerStatus()
                Log.add(event: .info, "Starting live timer...")
                
                // Update ui state
                currentState = .streaming
                Log.add(event: .info, "UI State chagned to streaming...")
                
                // Observe stream event
                subscribeStreamEventAndObserve()
                subscribePostEventAndObserve()
                Log.add(event: .info, "Obversing stream to handle terminated events")

            } catch let error {
                // Show alert
                LiveStreamAlert.shared.show(for: .streamError)
                // Update ui state
                currentState = .setup
                
                Log.add(event: .error, "Error while creating live stream \(error.localizedDescription)")
            }
        }
    }
    
    // When user taps on end live button
    func endLiveStream(reason: LiveStreamEndReason) {
        Log.add(event: .info, "Ending live stream, Reason: \(reason.rawValue)")
        
        broadcaster.stopPublish()
        
        currentState = .ended(reason: reason)
        
        cleanup()
    }
    
    func editLiveStream(chatDisabled: Bool) {
        guard let createdStream else { return }
        Task.runOnMainActor {
            do {
                if chatDisabled {
                    try await self.channelManager.muteChannel(channelId: createdStream.channel?.channelId ?? "")
                } else {
                    try await self.channelManager.unmuteChannel(channelId: createdStream.channel?.channelId ?? "")
                }
            } catch {
                Log.add(event: .error, "Error while editing live stream \(error.localizedDescription)")
            }
        }
    }
        
    deinit {
        cleanup()
    }
    
    func cleanup() {
        targetObjectToken?.invalidate()
        liveStreamToken?.invalidate()
        livePostToken?.invalidate()
        
        targetObjectToken = nil
        liveStreamToken = nil
        livePostToken = nil
        
        // Cleanup states
        isReconnecting = false
        isUploadingThumbnail = false
        liveStreamEndCountdown = 0
        selectedImage = nil
        thumbnailData = nil
        
        if createdPost?.isInvalidated == false {
            createdPost?.unsubscribeEvent(.post, withCompletion: { success, error in
                Log.add(event: .info, "Unsubscribing post event status: \(success) Error: \(String(describing: error))")
            })
        }
        
        if !currentAppIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        NotificationCenter.default.removeObserver(self)
        
        // Invalidate timers
        timerService.invalidateTimers()
        
        self.broadcaster.previewView.removeFromSuperview()

    }
    
    func subscribePostEventAndObserve() {
        guard let postId = createdPost?.postId else { return }
        
        createdPost?.subscribeEvent(.post, withCompletion: { success, error in
            Log.add(event: .info, "Subscribing post event status: \(success) Error: \(String(describing: error))")
        })
        
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
    
    func subscribeStreamEventAndObserve() {
        guard let streamId = createdStream?.streamId else { return }
        liveStreamToken = streamManager.getStream(id: streamId).observe { [weak self] liveObject, error in
            guard let self, let snapshot = liveObject.snapshot else { return }
            
            if snapshot.isDeleted {
                liveStreamToken?.invalidate()
                liveStreamToken = nil
                
                self.endLiveStream(reason: .terminated)
            }
            
            if let terminateLabels = snapshot.moderation?.terminateLabels, !terminateLabels.isEmpty {
                liveStreamToken?.invalidate()
                liveStreamToken = nil
                
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
                currentState = .ending
            }
            
            // 10 seconds counter should now be enabled
            if secondElapsed >= LiveStreamTimerService.threshold.streamMaxLiveDuration - LiveStreamTimerService.threshold.streamEndCountdownDuration && !isLiveStreamEndCountdownStarted {
                currentState = .ending
                
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

extension AmityCreateLiveStreamViewModel {
    
    // Note:
    // When you start publishing, the broadcaster state goes from
    // idle -> connecting -> connected
    func amityVideoBroadcasterDidUpdateState(_ broadcaster: AmityLiveVideoBroadcastKit.AmityVideoBroadcaster) {
        Log.add(event: .info, "Broadcaster State: \(broadcaster.state.strValue)")
        
        switch broadcaster.state {
        case .connected:
            // Invalidate reconnection timer
            timerService.stopReconnectionTimer()
            
            isReconnecting = false
        case .idle:
            break
        case .connecting:
            let existingState = self.broadcasterState
            if existingState == .connected || existingState == .disconnected {
                updateLiveStreamReconnectionStatus()
            }
        case .disconnected:
            break
        @unknown default:
            break
        }
        
        // Assign new state
        self.broadcasterState = broadcaster.state
    }
}

extension AmityCreateLiveStreamViewModel {
    
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

extension AmityStreamBroadcasterState {
    
    var strValue: String {
        switch self {
        case .connected:
            "Connected"
        case .idle:
            "Idle"
        case .connecting:
            "Connecting"
        case .disconnected:
            "Disconnected"
        @unknown default:
            "Unknown"
        }
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
