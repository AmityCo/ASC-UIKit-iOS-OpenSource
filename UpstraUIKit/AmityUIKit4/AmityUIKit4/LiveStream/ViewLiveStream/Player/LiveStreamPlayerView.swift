//
//  LiveStreamPlayerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/30/25.
//

import SwiftUI
import AVFoundation
import AVKit

struct LiveStreamPlayerView: UIViewRepresentable {
    
    let streamURL: URL?
    let isPlaying: Bool
    var onPlayingChange: ((Bool) -> Void)? = nil

    public init(streamURL: URL?, isPlaying: Bool, onPlayingChange: ((Bool) -> Void)? = nil) {
        self.streamURL = streamURL
        self.isPlaying = isPlaying
        self.onPlayingChange = onPlayingChange
    }

    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        return playerView
    }

    func updateUIView(_ playerView: PlayerView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onPlayingChange = onPlayingChange
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
        
        // Create new player for the stream
        let player = AVPlayer(url: streamURL)
        coordinator.currentPlayer = player
        coordinator.currentURL = streamURL
        coordinator.observePlaybackState(of: player)

        // Configure player for live streaming
        player.automaticallyWaitsToMinimizeStalling = true
        
        // Set the player to the layer
        playerView.playerLayer.player = player
        
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
        private var observedPlayer: AVPlayer?

        override init() {
            super.init()
        }

        func observePlaybackState(of player: AVPlayer) {
            observedPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
            observedPlayer = player
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == "timeControlStatus", let player = object as? AVPlayer else { return }
            let playing = player.timeControlStatus != .paused
            DispatchQueue.main.async { [weak self] in
                self?.onPlayingChange?(playing)
            }
        }

        deinit {
            observedPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
            currentPlayer?.pause()
            currentPlayer = nil
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


