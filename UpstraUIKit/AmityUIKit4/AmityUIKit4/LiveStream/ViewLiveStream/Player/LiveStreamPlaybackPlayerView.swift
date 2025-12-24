//
//  LiveStreamPlaybackPlayerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/3/25.
//

import Foundation
import AVKit
import AmitySDK

struct LiveStreamPlaybackPlayerView: UIViewControllerRepresentable {
    private let room: AmityRoom
    
    public init(room: AmityRoom) {
        self.room = room
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
        player.play()
        return playerViewController
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
