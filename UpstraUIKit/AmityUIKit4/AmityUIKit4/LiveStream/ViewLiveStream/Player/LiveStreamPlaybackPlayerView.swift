//
//  LiveStreamPlaybackPlayerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/3/25.
//

import Foundation
import AVKit
import AmitySDK
import SwiftUI

/// The recorded live stream's player. It shares the feed's session like an uploaded video: it opens in the
/// session sound state and where the feed left the recording (from the start if it had ended), a mute or
/// unmute here sets the session, and back in the feed the recording continues from where this player
/// stopped (a pause is not kept), or shows Watch again if it ended here.
struct LiveStreamPlaybackPlayerView: UIViewControllerRepresentable {
    private let room: AmityRoom
    
    public init(room: AmityRoom) {
        self.room = room
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(room: room)
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"] // l10n:ok HTTP header key not user-facing
        let url = URL(string: room.recordedData.first?.playbackUrl ?? "")
        context.coordinator.feedURL = url
        let asset = AVURLAsset(url: url ?? URL(fileURLWithPath: ""), options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        // Setup player observers in coordinator
        context.coordinator.continueFromFeed(player)
        context.coordinator.setupPlayer(player)

        // Start watch minute tracking for recorded playback
        context.coordinator.watchMinuteTracker.startTracking(for: room)

        player.play()

        return playerViewController
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    public static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        // Stop watch minute tracking when player is dismissed
        coordinator.watchMinuteTracker.stopTracking()
        coordinator.handBackToFeed()
    }
    
    // Coordinator to manage watch minute tracking
    class Coordinator: NSObject {
        let watchMinuteTracker = WatchMinuteTracker()
        private var player: AVPlayer?
        private var timeControlStatusObserver: NSKeyValueObservation?
        private var mutedObserver: NSKeyValueObservation?
        private var isSeeking = false
        /// The recording's URL, the key the feed keeps its position and end state under.
        var feedURL: URL?
        private var hasPlayed = false
        private var hasEnded = false

        /// Opens where the feed left the recording, from the start if it had ended, in the session sound state.
        @MainActor
        func continueFromFeed(_ player: AVPlayer) {
            let store = FeedAutoPlayStore.shared
            // The session mute applies only while auto-play is on; with it off the recording opens with sound.
            player.isMuted = store.isAutoPlayOn && store.isMuted
            guard let url = feedURL else { return }
            if store.hasEnded(url) {
                store.setEnded(false, for: url)
                store.setPosition(0, for: url)
            } else {
                let start = store.position(for: url)
                if start > 0 {
                    player.seek(to: CMTime(seconds: start, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                }
            }
        }

        /// Back in the feed the recording continues from where this player stopped, or shows Watch again if
        /// it played to the end here.
        func handBackToFeed() {
            guard hasPlayed, let url = feedURL, let player else { return }
            let ended = hasEnded
            let position = player.currentTime().seconds
            Task { @MainActor in
                let store = FeedAutoPlayStore.shared
                store.setEnded(ended, for: url)
                store.setPosition(ended ? 0 : (position.isFinite ? position : 0), for: url)
            }
        }

        init(room: AmityRoom) {
            // Coordinator manages the watch minute tracker lifecycle
            // The room is used by the tracker when startTracking is called
            super.init()
        }

        func setupPlayer(_ player: AVPlayer) {
            self.player = player

            // Observe player state changes
            timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] player, change in
                self?.handleTimeControlStatusChange(player)
            }

            // The player's own mute button sets the session sound, as the feed's does.
            mutedObserver = player.observe(\.isMuted, options: [.new]) { player, _ in
                let muted = player.isMuted
                Task { @MainActor in
                    let store = FeedAutoPlayStore.shared
                    if store.isAutoPlayOn, store.isMuted != muted { store.setMuted(muted) }
                }
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidPlayToEnd),
                name: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem
            )

            // Observe seeking
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidSeekStart),
                name: NSNotification.Name.AVPlayerItemTimeJumped,
                object: player.currentItem
            )
        }

        @objc private func playerDidPlayToEnd() {
            hasEnded = true
        }

        @objc private func playerDidSeekStart() {
            if !isSeeking {
                isSeeking = true
                watchMinuteTracker.pauseTracking()
            }
        }

        private func handleTimeControlStatusChange(_ player: AVPlayer) {
            switch player.timeControlStatus {
            case .playing:
                hasPlayed = true
                hasEnded = false
                // Resume tracking when playing, but only if not seeking
                if isSeeking {
                    isSeeking = false
                }
                watchMinuteTracker.resumeTracking()

            case .paused:
                // Pause tracking when paused (but not if we're seeking)
                if !isSeeking {
                    watchMinuteTracker.pauseTracking()
                }

            case .waitingToPlayAtSpecifiedRate:
                // Pause tracking while buffering/waiting
                watchMinuteTracker.pauseTracking()

            @unknown default:
                break
            }
        }

        deinit {
            timeControlStatusObserver?.invalidate()
            mutedObserver?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }
}
