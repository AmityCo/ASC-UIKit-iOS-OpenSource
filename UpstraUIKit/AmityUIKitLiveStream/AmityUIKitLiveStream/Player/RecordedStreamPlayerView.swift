//
//  RecordedStreamPlayerView.swift
//  AmityUIKitLiveStream
//
//  Created by Manuchet Rungraksa on 21/10/2567 BE.
//

import SwiftUI
import AmitySDK
import AVKit
import AmityVideoPlayerKit

public struct RecordedStreamPlayerView: UIViewControllerRepresentable {
    private let livestream: AmityStream
    let client: AmityClient
    
    public init(livestream: AmityStream, client: AmityClient) {
        self.livestream = livestream
        self.client = client
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AmityRecordedStreamPlayer(client: client, stream: livestream)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        player?.play()
        return playerViewController
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
