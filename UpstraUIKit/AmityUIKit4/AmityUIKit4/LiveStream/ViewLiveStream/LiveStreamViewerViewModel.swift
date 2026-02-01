//
//  LivestreamVideoPlayerViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import AmitySDK
import Combine

class LiveStreamViewerViewModel: ObservableObject {
    
    let roomManager = RoomManager()
    let postManager = PostManager()
    
    var roomToken: AmityNotificationToken?
    var postToken: AmityNotificationToken?
    private var chatViewModelCancellable: AnyCancellable?
    
    // Room Presense state
    private var presenceRepository: AmityRoomPresenceRepository?
    private var presenceTimer: Timer?
    @Published var watchingCount: Int = 0
    
    // Watch minute tracking
    let watchMinuteTracker: WatchMinuteTracker
    
    let post: AmityPostModel
    
    @Published var isLoaded = false
    @Published var room: AmityRoom?
    @Published var isStreamTerminated = false
    @Published var isPostDeleted = false
    @Published var isBannedFromStream = false
    @Published var liveStreamChatViewModel: AmityLiveStreamChatViewModel? {
        didSet {
            setupChatViewModelObservation()
        }
    }
    
    init(post: AmityPostModel, tracker: WatchMinuteTracker = WatchMinuteTracker()) {
        self.post = post
        self.watchMinuteTracker = tracker
        subscribeRoomEventAndObserve(roomId: post.room?.roomId ?? "")
        subscribePostEventAndObserve(postId: post.postId)
        
        // Create live stream chat view model
        guard let room = post.room else { return }
        self.room = room
        self.presenceRepository = AmityRoomPresenceRepository(client: AmityUIKitManagerInternal.shared.client, roomId: room.roomId)
        observeWatchingCount()
        
        // Start watch minute tracking for viewers in LIVE rooms
        if room.status == .live {
            watchMinuteTracker.startTracking(for: room)
        }
        
        Task.runOnMainActor {
            do {
                if let channel = try await room.getLiveChat(), let attachedRoom = channel.attachedToRoom {
                    self.liveStreamChatViewModel = AmityLiveStreamChatViewModel(room: attachedRoom, participantRole: .viewer)
                    return
                }
                Log.add(event: .error, "No live chat channel found for room id: \(room.roomId)")
            } catch {
                Log.add(event: .error, "Failed to get live chat channel: \(error.localizedDescription)")
            }
        }
    }
    
    func startPresenceHeartbeat() {
        Task.runOnMainActor {
            self.presenceRepository?.stopHeartbeat()
            async let _: Void? = self.presenceRepository?.startHeartbeat()
            Log.add(event: .info, "Started presence heartbeat for room id: \(self.room?.roomId ?? "nil")")
        }
    }
    
    func stopPresenceHeartbeat() {
        self.presenceRepository?.stopHeartbeat()
    }
    
    func observeWatchingCount() {
        self.presenceTimer?.invalidate()
        self.presenceTimer = nil
        
        self.presenceTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true, block: { [weak self]  _ in
            Task.runOnMainActor {
                do {
                    self?.watchingCount = try await self?.presenceRepository?.getRoomUserCount() ?? 0
                } catch {
                    Log.add(event: .error, "Error while fetching room watching count: \(error.localizedDescription)")
                }
            }
        })
    }
    
    private func subscribePostEventAndObserve(postId: String) {
        postToken?.invalidate()
        postToken = nil
        
        post.object.subscribeEvent(.post) { success, error in
            Log.add(event: .info, "Subscribing post event status: \(success) Error: \(String(describing: error))")
        }
        
        postToken = postManager.getPost(withId: postId).observe { [weak self] data, error in
            guard let self, let post = data.snapshot else { return }
                        
            if post.isDeleted {
                isPostDeleted = true
                cleanup()
            }
        }
    }
    
    private func subscribeRoomEventAndObserve(roomId: String) {
        roomToken?.invalidate()
        roomToken = nil
        isLoaded = false
        
        post.room?.subscribeEvent() { success, error in
            Log.add(event: .info, "Subscribing room event status: \(success) Error: \(String(describing: error))")
        }
        
        roomToken = roomManager.getRoom(roomId: roomId).observe { [weak self] data, error in
            guard let self, let room = data.snapshot else { return }
            
            self.liveStreamChatViewModel?.refreshHostAndCoHostId(room: room)
            
            self.isLoaded = true
            
            if room.isBanned {
                self.isBannedFromStream = true
            }
            
            if room.status != .idle {
                self.room = room
            }
            
            let terminateLabels = room.moderation?.terminateLabels ?? []
            if !terminateLabels.isEmpty {
                
                self.isStreamTerminated = true
                self.cleanup()
                
                NotificationCenter.default.post(name: .didLivestreamStatusUpdated, object: self.post.object)

                return
            }
            
            if room.status == .ended {
                NotificationCenter.default.post(name: .didLivestreamStatusUpdated, object: self.post.object)
                return
            }
        }
    }
    
    private func setupChatViewModelObservation() {
        chatViewModelCancellable?.cancel()
        chatViewModelCancellable = nil
        
        guard let chatViewModel = liveStreamChatViewModel else { return }
        
        chatViewModelCancellable = chatViewModel.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
    }
    
    func cleanup() {
        // Cancel any ongoing cleanup operations first
        chatViewModelCancellable?.cancel()
        chatViewModelCancellable = nil
        
        // Stop watch minute tracking
        watchMinuteTracker.stopTracking()
        
        // Clean up chat view model
        liveStreamChatViewModel?.cleanup()
        liveStreamChatViewModel = nil
        
        // Invalidate tokens
        self.roomToken?.invalidate()
        self.roomToken = nil
        
        self.postToken?.invalidate()
        self.postToken = nil
        
        self.presenceTimer?.invalidate()
        self.presenceTimer = nil
        self.stopPresenceHeartbeat()
                
        self.post.object.unsubscribeEvent(.post) { success, error in
            Log.add(event: .info, "Unsubscribing post event status: \(success) Error: \(String(describing: error))")
        }
        
        if let room = self.post.room, room.isInvalidated == false {
            room.unsubscribeEvent() { success, error in
                Log.add(event: .info, "Unsubscribing room event status: \(success) Error: \(String(describing: error))")
            }
        }
    }
}
