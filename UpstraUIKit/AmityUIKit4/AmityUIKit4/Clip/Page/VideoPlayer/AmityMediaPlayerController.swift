//
//  AmityMediaPlayerController.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AVFoundation
import AVKit
import CoreImage

class AmityMediaPlayerController: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading: Bool = true
    @Published var isSeeking: Bool = false
    @Published var videoGravity: AVLayerVideoGravity = .resizeAspect
    @Published var autoReplay: Bool = true
    /// False for a player whose owner sets the audio session itself (the feed mixes with other apps while muted).
    var configuresAudioSession: Bool = true
    /// With `autoReplay` off, stop on the last frame instead of rewinding to the start.
    var holdsLastFrameAtEnd: Bool = false
    /// Feed previews start like the Android feed (ExoPlayer: play after 1 s buffered, keep 2–8 s ahead): playback
    /// starts once 1 s of video is buffered ahead, not after AVPlayer's own estimate, and keeps at most 8 s
    /// ahead. Once the first frame is drawn the player waits to minimise stalls as usual, so a later stall still
    /// reads as one.
    var startsQuickly: Bool = false
    /// Whether playback was asked for, so a held start or a stall during it can carry on by itself.
    private var wantsPlayback = false
    /// Open once 1 s is buffered for the current item; until then a requested play is held.
    private var startGateOpen = false
    private var loadedRangesObservation: NSKeyValueObservation?
    private static let startBufferSeconds: Double = 1
    private static let maxBufferSeconds: Double = 8
    /// True once the video played to its end without replaying, whether it holds the last frame or rewinds;
    /// cleared when it plays again.
    @Published private(set) var hasEnded: Bool = false
    /// True once the item failed to load or to keep playing; it does not recover by itself.
    @Published private(set) var hasFailed: Bool = false
    /// True once the player layer has a frame to show (`AVPlayerLayer.isReadyForDisplay`), which comes after
    /// `readyToPlay`: the feed hides its spinner here, not when `isLoading` turns false.
    @Published private(set) var hasFirstFrame: Bool = false
    /// True while playback waits for data (`timeControlStatus == .waitingToPlayAtSpecifiedRate`), a stall.
    /// `isPlaying` stays true then, as before.
    @Published private(set) var isStalled: Bool = false
    /// True once playback has really started (`timeControlStatus == .playing`). A stream can draw its first frame
    /// and still wait before it plays; that wait is part of the start, not a stall.
    @Published private(set) var hasStartedPlaying: Bool = false
    private var readyForDisplayObservation: NSKeyValueObservation?
    /// Set by `enableFrameCapture()`: receives the decoded frames, so the frame on screen can be kept as an
    /// image, also for a streamed (HLS) video, which `AVAssetImageGenerator` cannot read.
    private var videoOutput: AVPlayerItemVideoOutput?
    
    private(set) var player: AVPlayer?
    private(set) var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var pendingSeekTarget: Double?
    private var wasPlayingBeforeBackground = false
    
    private(set) var isPictureInPictureEnabled = false
    let pipController = AmityPipController()

    func configure(playerLayer: AVPlayerLayer) {
        self.player = playerLayer.player
        self.playerLayer = playerLayer

        // Force audio output even when the device is in silent mode.
        // This must happen before playback starts to ensure audio works on all devices.
        if configuresAudioSession {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }

        // Explicitly sync player audio state to avoid silent playback on some devices
        player?.isMuted = isMuted
        player?.volume = 1.0

        configureObservers()
        configurePlayerItem()
        applyQuickStart(to: player?.currentItem)

        readyForDisplayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
            let ready = layer.isReadyForDisplay
            DispatchQueue.main.async {
                self?.hasFirstFrame = ready
                if ready { self?.endQuickStart() }
            }
        }

        if isPictureInPictureEnabled {
            pipController.attach(to: playerLayer)
        }
    }

    func enablePictureInPicture(roomId: String? = nil, onRestore: (() -> Void)? = nil) {
        isPictureInPictureEnabled = true
        pipController.onStopUI = { [weak self] in
            // Deliberate stop (✕ on the window): also clear the resume flag so a
            // later foreground doesn't resurrect the playback the user stopped.
            self?.wasPlayingBeforeBackground = false
            self?.pause()
        }
        pipController.onRestoreUI = onRestore
        if let roomId {
            PiPState.shared.setActiveRoom(roomId)
        }
        if let playerLayer = playerLayer {
            pipController.attach(to: playerLayer)
        }
    }
    
    private func configureObservers() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            self.currentTime = time.seconds
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackCompletion),
            name: AVPlayerItem.didPlayToEndTimeNotification,
            object: player.currentItem
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackFailure),
            name: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: player.currentItem
        )
        
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.old, .new], context: nil)

        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func handleWillResignActive() {
        wasPlayingBeforeBackground = isPlaying
    }

    @objc private func handleDidEnterBackground() {
        // Parity with the live viewer: if PiP is enabled but doesn't actually
        // start (e.g. "Start Picture in Picture Automatically" is off in
        // Settings), iOS never fires a delegate — it just doesn't start. The
        // `audio` background mode would otherwise keep the recording playing
        // audio-only with no window. So if PiP hasn't become active shortly
        // after backgrounding, pause. Guarded so we never pause once foregrounded.
        if isPictureInPictureEnabled, isPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if !PiPState.shared.isActive,
                   UIApplication.shared.applicationState != .active {
                    self?.pause()
                }
            }
        }
    }

    @objc private func handleDidBecomeActive() {
        if isPictureInPictureEnabled && PiPState.shared.isActive { return }
        if wasPlayingBeforeBackground {
            play()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.duration = playerItem.duration.seconds
                    }
                case .failed:
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.hasFailed = true
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        } else if keyPath == "duration" {
            if let playerItem = object as? AVPlayerItem {
                DispatchQueue.main.async {
                    self.duration = playerItem.duration.seconds
                }
            }
        } else if keyPath == "timeControlStatus" {
            DispatchQueue.main.async {
                self.isPlaying = (self.player?.timeControlStatus != .paused)
                self.isStalled = (self.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate)
                if self.player?.timeControlStatus == .playing { self.hasStartedPlaying = true }
            }
        }
    }
    
    @objc private func handlePlaybackFailure() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isPlaying = false
            self.hasFailed = true
        }
    }

    @objc private func handlePlaybackCompletion() {
        DispatchQueue.main.async {
            if self.autoReplay {
                self.player?.seek(to: .zero)
                self.player?.play()
                self.currentTime = 0
            } else if self.holdsLastFrameAtEnd {
                self.isPlaying = false
                self.hasEnded = true
            } else {
                self.isPlaying = false
                self.hasEnded = true
                self.currentTime = 0
                self.player?.seek(to: .zero)
            }
        }
    }
    
    private func configurePlayerItem() {
        guard let playerItem = player?.currentItem else { return }
        
        if playerItem.status == .readyToPlay {
            DispatchQueue.main.async {
                self.duration = playerItem.duration.seconds
                self.isLoading = false
            }
        } else if playerItem.status == .failed {
            DispatchQueue.main.async {
                self.isLoading = false
                self.hasFailed = true
            }
        }
    }
    
    func play() {
        hasEnded = false
        wantsPlayback = true
        isPlaying = true
        if startsQuickly, !startGateOpen {
            openStartGateIfBuffered()
            return
        }
        player?.play()
    }

    func pause() {
        wantsPlayback = false
        player?.pause()
        isPlaying = false
    }

    private func applyQuickStart(to item: AVPlayerItem?) {
        guard startsQuickly, let player, let item else { return }
        startGateOpen = false
        item.preferredForwardBufferDuration = Self.maxBufferSeconds
        player.automaticallyWaitsToMinimizeStalling = false
        NotificationCenter.default.removeObserver(self, name: AVPlayerItem.playbackStalledNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartStall),
                                               name: AVPlayerItem.playbackStalledNotification, object: item)
        loadedRangesObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.openStartGateIfBuffered() }
        }
    }

    /// Seconds of video loaded ahead of the play position.
    private func bufferedAhead(of item: AVPlayerItem) -> Double {
        let now = item.currentTime().seconds
        for value in item.loadedTimeRanges {
            let range = value.timeRangeValue
            let start = range.start.seconds, end = (range.start + range.duration).seconds
            if now >= start - 0.1, now <= end { return end - now }
        }
        return 0
    }

    /// Plays a held start once 1 s is buffered, or once the rest of a short video is.
    private func openStartGateIfBuffered() {
        guard startsQuickly, !startGateOpen, let player, let item = player.currentItem else { return }
        let ahead = bufferedAhead(of: item)
        let remaining = item.duration.seconds - item.currentTime().seconds
        let enough = ahead >= Self.startBufferSeconds || item.isPlaybackBufferFull
            || (remaining.isFinite && remaining > 0 && ahead >= remaining - 0.05)
        guard enough else { return }
        startGateOpen = true
        loadedRangesObservation?.invalidate()
        loadedRangesObservation = nil
        if wantsPlayback { player.play() }
    }

    /// The first frame is drawn: from here the player waits to minimise stalls, as every other player does.
    private func endQuickStart() {
        guard startsQuickly, let player, !player.automaticallyWaitsToMinimizeStalling else { return }
        player.automaticallyWaitsToMinimizeStalling = true
    }

    /// Ran out of data right after the start: carry on waiting for data, as a normal start would.
    @objc private func handleQuickStartStall() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.startsQuickly, self.startGateOpen else { return }
            self.endQuickStart()
            if self.wantsPlayback { self.player?.play() }
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func toggleMute() {
        setMuted(!isMuted)
    }

    func setMuted(_ muted: Bool) {
        guard isMuted != muted else { return }
        isMuted = muted
        player?.isMuted = muted
    }

    func mute() {
        isMuted = true
        player?.isMuted = true
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isSeeking = false
            }
        }
    }
    
    func beginSeeking() {
        isSeeking = true
    }
    
    func setCurrentTime(_ time: Double) {
        currentTime = time
    }
    
    @MainActor
    func generateThumbnail(at time: Double = 0, size: CGSize = CGSize.zero) async -> UIImage? {
        guard let player = player,
              let asset = player.currentItem?.asset else {
            return nil
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = size
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        return try? await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func restart() {
        seek(to: 0)
        play()
    }

    /// Starts receiving decoded frames, so `currentFrameImage()` can return the frame on screen.
    func enableFrameCapture() {
        guard videoOutput == nil, let item = player?.currentItem else { return }
        // The decoder's own format: no per-frame conversion while the video plays.
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
        item.add(output)
        videoOutput = output
    }

    /// The frame at the player's current time, made into an image off the main thread and handed back on it;
    /// nil before `enableFrameCapture()` or before a frame is decoded.
    func currentFrameImage(completion: @escaping (UIImage?) -> Void) {
        guard let output = videoOutput, let item = player?.currentItem,
              let buffer = output.copyPixelBuffer(forItemTime: item.currentTime(), itemTimeForDisplay: nil) else {
            completion(nil)
            return
        }
        Self.frameQueue.async {
            let image = CIImage(cvPixelBuffer: buffer)
            let cgImage = Self.ciContext.createCGImage(image, from: image.extent)
            DispatchQueue.main.async {
                completion(cgImage.map { UIImage(cgImage: $0) })
            }
        }
    }

    private static let ciContext = CIContext()
    private static let frameQueue = DispatchQueue(label: "amity.media-player.frame-capture", qos: .utility)

    /// Plays another video in the same player and layer (the next recording of a recorded live stream). The
    /// observers move to the new item, and its load, end and failure states start over.
    func replaceItem(with url: URL) {
        guard let player else { return }
        if let item = player.currentItem {
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "duration")
            NotificationCenter.default.removeObserver(self, name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            NotificationCenter.default.removeObserver(self, name: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
        }
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"] // l10n:ok HTTP header key not user-facing
        let item = AVPlayerItem(asset: AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers]))
        player.replaceCurrentItem(with: item)
        applyQuickStart(to: item)
        if let output = videoOutput {
            item.add(output)
        }
        hasEnded = false
        hasFailed = false
        hasStartedPlaying = false
        isLoading = true
        currentTime = 0
        duration = 0
        pendingSeekTarget = nil
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackCompletion),
                                               name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackFailure),
                                               name: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
        item.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        item.addObserver(self, forKeyPath: "duration", options: [.old, .new], context: nil)
    }
    
    func skipForward(_ seconds: Double = 10) {
        guard duration.isFinite, duration > 0 else { return }
        let base = pendingSeekTarget ?? currentTime
        let raw = base + seconds
        // A seek to exactly the duration does not land on a stream; the last frame is just before it.
        let target = raw >= duration ? max(duration - 0.1, 0) : raw
        accumulatedSeek(to: target)
        // Reached the final frame → end state (paused), the same as playing to the end: the full player shows
        // Watch again and the feed learns the video ended.
        if raw >= duration {
            pause()
            hasEnded = true
        }
    }

    func skipBackward(_ seconds: Double = 10) {
        // Back from the end: no longer ended, paused with the play button.
        hasEnded = false
        let base = pendingSeekTarget ?? currentTime
        let target = max(base - seconds, 0)
        accumulatedSeek(to: target)
    }

    private func accumulatedSeek(to target: Double) {
        pendingSeekTarget = target
        currentTime = target
        let cmTime = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            // Only clear once the final seek settles; superseded seeks (finished == false)
            // keep the running target so the burst keeps accumulating.
            guard finished else { return }
            DispatchQueue.main.async {
                self?.pendingSeekTarget = nil
            }
        }
    }
    
    func setVideoGravity(_ gravity: AVLayerVideoGravity) {
        videoGravity = gravity
        playerLayer?.videoGravity = gravity
    }
    
    func cleanup() {
        pause()

        pipController.detach()

        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.currentItem?.removeObserver(self, forKeyPath: "duration")
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        readyForDisplayObservation?.invalidate()
        readyForDisplayObservation = nil

        NotificationCenter.default.removeObserver(self)

        // player?.replaceCurrentItem(with: nil)
        
        playerLayer?.removeFromSuperlayer()
        
        player = nil
        playerLayer = nil
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isMuted = false
            self.currentTime = 0
            self.duration = 0
            self.isLoading = true
            self.isSeeking = false
        }
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.currentItem?.removeObserver(self, forKeyPath: "duration")
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        readyForDisplayObservation?.invalidate()
        readyForDisplayObservation = nil

        NotificationCenter.default.removeObserver(self)
    }
}
