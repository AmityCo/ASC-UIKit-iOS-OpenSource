//
//  LiveStreamPlayerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/30/25.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine

struct LiveStreamPlayerView: UIViewRepresentable {
    
    let streamURL: URL?
    let isPlaying: Bool
    // POC (PDT-4099) #12: when this value changes, seek the player to the live
    // edge (used on return from PiP/background so playback stays live, not delayed).
    var seekToLiveToken: Int = 0
    var onPlayingChange: ((Bool) -> Void)? = nil
    
    var onRestoreFromPiP: (() -> Void)? = nil
    var onStopFromPiP: (() -> Void)? = nil
    var onPlaybackError: (() -> Void)? = nil
    var onPlaybackRecovered: (() -> Void)? = nil

    public init(streamURL: URL?, isPlaying: Bool, seekToLiveToken: Int = 0, onPlayingChange: ((Bool) -> Void)? = nil, onRestoreFromPiP: (() -> Void)? = nil, onStopFromPiP: (() -> Void)? = nil, onPlaybackError: (() -> Void)? = nil, onPlaybackRecovered: (() -> Void)? = nil) {
        self.streamURL = streamURL
        self.isPlaying = isPlaying
        self.seekToLiveToken = seekToLiveToken
        self.onPlayingChange = onPlayingChange
        self.onRestoreFromPiP = onRestoreFromPiP
        self.onStopFromPiP = onStopFromPiP
        self.onPlaybackError = onPlaybackError
        self.onPlaybackRecovered = onPlaybackRecovered
    }

    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        return playerView
    }

    func updateUIView(_ playerView: PlayerView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onPlayingChange = onPlayingChange
        coordinator.onPlaybackError = onPlaybackError
        coordinator.onPlaybackRecovered = onPlaybackRecovered
        coordinator.pipController.onRestoreUI = onRestoreFromPiP
        coordinator.pipController.onStopUI = onStopFromPiP
        if isPlaying {
            if coordinator.currentPlayer == nil || coordinator.currentURL != streamURL {
                startPlayback(playerView: playerView, coordinator: coordinator)
            } else if coordinator.currentPlayer?.timeControlStatus == .paused {
                seekToLiveEdge(coordinator: coordinator)
                coordinator.currentPlayer?.play()
            } else if coordinator.currentPlayer?.timeControlStatus != .playing {
                coordinator.currentPlayer?.play()
            }
        } else {
            coordinator.currentPlayer?.pause()
        }

        if seekToLiveToken != coordinator.lastSeekToLiveToken {
            coordinator.lastSeekToLiveToken = seekToLiveToken
            if coordinator.currentPlayer != nil {
                seekToLiveEdge(coordinator: coordinator)
            }
        }
    }

    private func seekToLiveEdge(coordinator: Coordinator) {
        guard let player = coordinator.currentPlayer,
              let seekableRange = player.currentItem?.seekableTimeRanges.last?.timeRangeValue else {
            return
        }
        let liveEdge = CMTimeRangeGetEnd(seekableRange)
        player.seek(to: liveEdge, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func startPlayback(playerView: PlayerView, coordinator: Coordinator) {
        guard let streamURL = streamURL else {
            Log.add(event: .error, "No stream URL provided")
            return
        }

        LiveStreamPiPRetainer.shared.releaseForNewPlayback()

        // Create new player for the stream
        let player = AVPlayer(url: streamURL)
        coordinator.currentPlayer = player
        coordinator.currentURL = streamURL
        coordinator.observePlaybackState(of: player)

        // Configure player for live streaming
        player.automaticallyWaitsToMinimizeStalling = true
        
        // Set the player to the layer
        playerView.playerLayer.player = player

        // keep a strong ref so the layer-hosting view can be handed to the
        // retainer (instead of deallocated) if the page is torn down while PiP runs.
        coordinator.playerView = playerView

        // attach Picture-in-Picture to the live player layer.
        coordinator.pipController.attach(to: playerView.playerLayer)

        // Start playback
        player.play()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var currentPlayer: AVPlayer?
        var currentURL: URL?
        var onPlayingChange: ((Bool) -> Void)?
        var onPlaybackError: (() -> Void)?
        var onPlaybackRecovered: (() -> Void)?

        
        let pipController = AmityPipController()
        var playerView: PlayerView?
        var lastSeekToLiveToken = 0
        private var observedPlayer: AVPlayer?
        private var hasBeenReadyToPlay = false

        override init() {
            super.init()
        }

        func observePlaybackState(of player: AVPlayer) {
            observedPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
            observedPlayer?.removeObserver(self, forKeyPath: "currentItem.status")
            observedPlayer = player
            hasBeenReadyToPlay = false
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
            player.addObserver(self, forKeyPath: "currentItem.status", options: [.new], context: nil)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let player = object as? AVPlayer else { return }
            if keyPath == "timeControlStatus" {
                let status = player.timeControlStatus
                // Unchanged semantics for watch-minute tracking and the play/pause
                // button: anything other than an explicit pause counts as active.
                let playing = status != .paused
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.onPlayingChange?(playing)
                    if status == .playing {
                        self.onPlaybackRecovered?()
                    }
                }
            } else if keyPath == "currentItem.status" {
                switch player.currentItem?.status {
                case .readyToPlay:
                    hasBeenReadyToPlay = true
                case .failed:
                    guard hasBeenReadyToPlay else { return }
                    DispatchQueue.main.async { [weak self] in
                        self?.onPlaybackError?()
                    }
                default:
                    break
                }
            }
        }

        deinit {
            observedPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
            observedPlayer?.removeObserver(self, forKeyPath: "currentItem.status")

            if PiPState.shared.isActive, let player = currentPlayer, let view = playerView {
                LiveStreamPiPRetainer.shared.retain(pipController: pipController, player: player, playerView: view)
                currentPlayer = nil
                playerView = nil
                return
            }

            pipController.detach()
            currentPlayer?.pause()
            currentPlayer = nil
            playerView = nil
        }
    }
    
    class PlayerView: UIView {
        
        override public class var layerClass: AnyClass {
            return AVPlayerLayer.self
        }
        
        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
        
        override public func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
}


