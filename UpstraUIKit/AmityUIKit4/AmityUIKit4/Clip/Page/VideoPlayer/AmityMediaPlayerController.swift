//
//  AmityMediaPlayerController.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AVFoundation
import AVKit

class AmityMediaPlayerController: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading: Bool = true
    @Published var isSeeking: Bool = false
    @Published var videoGravity: AVLayerVideoGravity = .resizeAspect
    @Published var autoReplay: Bool = true
    
    private(set) var player: AVPlayer?
    private(set) var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    
    func configure(playerLayer: AVPlayerLayer) {
        self.player = playerLayer.player
        self.playerLayer = playerLayer

        // Force audio output even when the device is in silent mode.
        // This must happen before playback starts to ensure audio works on all devices.
        try? AVAudioSession.sharedInstance().setCategory(.playback)

        // Explicitly sync player audio state to avoid silent playback on some devices
        player?.isMuted = isMuted
        player?.volume = 1.0

        configureObservers()
        configurePlayerItem()
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
        
        player.currentItem?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.old, .new], context: nil)
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
        }
    }
    
    @objc private func handlePlaybackCompletion() {
        DispatchQueue.main.async {
            if self.autoReplay {
                self.player?.seek(to: .zero)
                self.player?.play()
                self.currentTime = 0
            } else {
                self.isPlaying = false
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
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
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
    
    func skipForward(_ seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func setVideoGravity(_ gravity: AVLayerVideoGravity) {
        videoGravity = gravity
        playerLayer?.videoGravity = gravity
    }
    
    func cleanup() {
        pause()
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        player?.currentItem?.removeObserver(self, forKeyPath: "duration")
        
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
        
        NotificationCenter.default.removeObserver(self)
    }
}
