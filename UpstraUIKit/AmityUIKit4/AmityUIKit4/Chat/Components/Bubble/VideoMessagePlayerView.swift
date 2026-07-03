//
//  VideoMessagePlayerView.swift
//  AmityUIKit4
//

import SwiftUI
import AVKit

struct VideoMessagePlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        controller.player = player
        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.allowsPictureInPicturePlayback = false
        DispatchQueue.main.async { player.play() }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
