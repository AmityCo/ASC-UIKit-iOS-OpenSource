//
//  RecordedStreamPlayerView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import SwiftUI
import AmitySDK
import AVKit
import AmityVideoPlayerKit

struct RecordedStreamPlayerView: UIViewControllerRepresentable {
    private let livestream: AmityStream
    
    init(livestream: AmityStream) {
        self.livestream = livestream
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AmityRecordedStreamPlayer(client: AmityUIKit4Manager.client, stream: livestream)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        player?.play()
        return playerViewController
    }
    
    
    func openRecordedLiveStreamPlayer(stream: AmityStream) {
#if canImport(AmityVideoPlayerKit)
        let player = AmityRecordedStreamPlayer(client: AmityUIKit4Manager.client, stream: stream)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        player?.play()
#else
        print("To watch recorded live stream, please install AmityVideoPlayerKit.")
#endif
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
