//
//  AmityMediaPlayer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AVFoundation
import AVKit

// Note:
// Migrate to this AmityMediaPlayer from existing VideoPlayer implementation. Existing VideoPlayer has issue
// where it re-renders the player layer whenever its modifier is modified.

/// Wraps AVPlayer & AVPPlayerLayer in UIViewRepresentable. This class interacts with its controller to handle
/// playback. Controller supports
/// - play / pause
/// - seek
/// - mute / unmute
/// - Thumbnail generation for current video
struct AmityMediaPlayer: UIViewRepresentable {
    let url: URL
    
    @ObservedObject
    var controller: AmityMediaPlayerController
    
    init(url: URL, controller: AmityMediaPlayerController) {
        self.url = url
        self.controller = controller
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"
        ]
                
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.layer.addSublayer(playerLayer)

        controller.configure(playerLayer: playerLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}
