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
    
    init(url: URL, 
         autoPlay: Bool = true,
         post: AmityPostModel? = nil) {
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
        
        let vc = CustomAVPlayerViewController()
        vc.player = player
        
        if autoPlay {
            player.play()
        }
        
        // Set up notification observers for play/pause control
        context.coordinator.setupNotificationObservers(for: player, with: url)
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        private var parent: AVPlayerView
        private var playObserver: NSObjectProtocol?
        private var pauseObserver: NSObjectProtocol?
        
        init(_ parent: AVPlayerView) {
            self.parent = parent
        }
        
        func setupNotificationObservers(for player: AVPlayer, with url: URL) {
            
            // Remove previous observers if they exist
            if let playObserver = playObserver {
                NotificationCenter.default.removeObserver(playObserver)
            }
            if let pauseObserver = pauseObserver {
                NotificationCenter.default.removeObserver(pauseObserver)
            }
            
            
            // Set up play notification observer
            playObserver = NotificationCenter.default.addObserver(
                forName: .playVideo,
                object: nil,
                queue: .main) { [weak player] notification in
                    if let notificationURL = notification.userInfo?["url"] as? URL,
                       notificationURL == url {
                        player?.play()
                    }
                }
            
            // Set up pause notification observer
            pauseObserver = NotificationCenter.default.addObserver(
                forName: .pauseVideo,
                object: nil,
                queue: .main) { [weak player] notification in
                    if let notificationURL = notification.userInfo?["url"] as? URL,
                       notificationURL == url {
                        player?.pause()
                    }
                }
        }
        
        deinit {
            if let playObserver = playObserver {
                NotificationCenter.default.removeObserver(playObserver)
            }
            if let pauseObserver = pauseObserver {
                NotificationCenter.default.removeObserver(pauseObserver)
            }
        }
    }
}


// MARK: - Notification Extensions
extension Notification.Name {
    static let playerControlsVisibilityChanged = Notification.Name("AmityUIKit.playerControlsVisibilityChanged")
    static let playerControlsWillFadeOut = Notification.Name("AmityUIKit.playerControlsWillFadeOut")
    static let playerControlsWillFadeIn = Notification.Name("AmityUIKit.playerControlsWillFadeIn")
}

class CustomAVPlayerViewController: AVPlayerViewController {
    
    private var viewToMonitor: UIView? = nil
    private var previousValue = true
    private var previousAlpha: CGFloat = 1.0
    private let fadeThreshold: CGFloat = 0.02
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let container = view.subviews.first
        viewToMonitor = container?.subviews.last
        previousValue = viewToMonitor?.isHidden ?? true
        previousAlpha = viewToMonitor?.alpha ?? 1.0
        
        // Observe both hidden and alpha properties
        viewToMonitor?.addObserver(self, forKeyPath: "hidden", context: nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        viewToMonitor?.removeObserver(self, forKeyPath: "hidden")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "hidden", let v = viewToMonitor {
            if previousValue != v.isHidden {
                previousValue = v.isHidden
                // Post notification instead of using delegate
                NotificationCenter.default.post(
                    name: .playerControlsVisibilityChanged,
                    object: nil,
                    userInfo: ["visible": !v.isHidden]
                )
                
                if !v.isHidden {
                    // Controls became visible - will fade in
                    NotificationCenter.default.post(
                        name: .playerControlsWillFadeIn,
                        object: nil
                    )
                }
            } else if !v.isHidden {
                // Controls are visible but might be fading out
                NotificationCenter.default.post(
                    name: .playerControlsWillFadeOut,
                    object: nil
                )
            }
        }
    }
}
