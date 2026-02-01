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
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"
        ]
        
        let url = URL(string: room.recordedData.first?.playbackUrl ?? "")
        let asset = AVURLAsset(url: url ?? URL(fileURLWithPath: ""), options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        // Setup player observers in coordinator
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
    }
    
    // Coordinator to manage watch minute tracking
    class Coordinator: NSObject {
        let watchMinuteTracker = WatchMinuteTracker()
        private var player: AVPlayer?
        private var timeControlStatusObserver: NSKeyValueObservation?
        private var isSeeking = false

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

            // Observe seeking
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidSeekStart),
                name: NSNotification.Name.AVPlayerItemTimeJumped,
                object: player.currentItem
            )
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
            NotificationCenter.default.removeObserver(self)
        }
    }
}
