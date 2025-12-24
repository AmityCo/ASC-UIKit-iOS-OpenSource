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
    
    public init(streamURL: URL?, isPlaying: Bool) {
        self.streamURL = streamURL
        self.isPlaying = isPlaying
    }
    
    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView()
        return playerView
    }
    
    func updateUIView(_ playerView: PlayerView, context: Context) {
        if isPlaying {
            if context.coordinator.currentPlayer == nil || context.coordinator.currentURL != streamURL {
                startPlayback(playerView: playerView, coordinator: context.coordinator)
            } else if context.coordinator.currentPlayer?.timeControlStatus != .playing {
                context.coordinator.currentPlayer?.play()
            }
        } else {
            context.coordinator.currentPlayer?.pause()
        }
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
        
        override init() {
            super.init()
        }
        
        deinit {
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


