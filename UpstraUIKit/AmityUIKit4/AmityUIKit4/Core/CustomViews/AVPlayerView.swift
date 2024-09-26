//
//  AVPlayerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/14/24.
//

import Foundation
import AVKit
import SwiftUI

struct AVPlayerView: UIViewControllerRepresentable {
    private let url: URL
    private let autoPlay: Bool
    
    init(url: URL, autoPlay: Bool = true) {
        self.url = url
        self.autoPlay = autoPlay
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"
        ]
        
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        let vc = AVPlayerViewController()
        vc.player = player
        if autoPlay {
            player.play()
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

