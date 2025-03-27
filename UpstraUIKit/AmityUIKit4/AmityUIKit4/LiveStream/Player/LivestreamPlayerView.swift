//
//  LivestreamPlayerView.swift
//  AmityUIKitLiveStream
//
//  Created by Manuchet Rungraksa on 17/10/2567 BE.
//

import SwiftUI
import AmityVideoPlayerKit
import AmitySDK

public struct LivestreamPlayerView: UIViewRepresentable {
    
    let stream: AmityStream?
    let client: AmityClient
    
    var isPlaying: Bool
    
    public init(stream: AmityStream?, client: AmityClient, isPlaying: Bool) {
        self.stream = stream
        self.client = client
        self.isPlaying = isPlaying
    }

    public func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if isPlaying {
            if !context.coordinator.isPlaying {
                playLivestream(on: uiView, coordinator: context.coordinator)
            }
        } else {
            if context.coordinator.isPlaying {
                stopLivestream(on: uiView, coordinator: context.coordinator)
            }
        }
    }

    func stopLivestream(on view: UIView, coordinator: Coordinator) {
        if let snapshotView = view.snapshotView(afterScreenUpdates: false) {
            coordinator.lastFrameSnapshotView = snapshotView
            coordinator.lastFrameSnapshotView?.frame = view.bounds
            coordinator.lastFrameSnapshotView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        coordinator.player.stop()

        if let lastFrameSnapshotView = coordinator.lastFrameSnapshotView {
            view.addSubview(lastFrameSnapshotView)
        }
        coordinator.isPlaying = false
    }

    func playLivestream(on view: UIView, coordinator: Coordinator) {
        coordinator.lastFrameSnapshotView?.removeFromSuperview()

        let videoView = UIView(frame: view.bounds)
        videoView.isUserInteractionEnabled = false
        videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(videoView)

        coordinator.player.renderView = videoView

        if let stream {
            coordinator.player.play(stream, completion: { result in
                switch result {
                case .success:
                    print("Stream started playing")
                case .failure(let error):
                    print("Failed to play stream: \(error.localizedDescription)")
                }
            })
        }
        coordinator.isPlaying = true
    }

    public class Coordinator {
        var lastFrameSnapshotView: UIView?
        var isPlaying = false
        let player: AmityVideoPlayer

        init(player: AmityVideoPlayer) {
            self.player = player
        }
    }

    public func makeCoordinator() -> Coordinator {
        let player = AmityVideoPlayer(client: client)
        return Coordinator(player: player)
    }
}
