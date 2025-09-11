//
//  ClipFeedViewCell.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import UIKit
import SwiftUI
import AVFoundation

class ClipFeedViewCell: UICollectionViewCell {
    
    static let identifier = "ClipFeedViewCell"
        
    private var playerController: AmityMediaPlayerController?
    private var hostingController: UIHostingController<ClipFeedItemOverlayView>?
    
    var onCommentTapAction: DefaultTapAction?
    var onTapAction: ((ClipFeedAction) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black
        contentView.backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cleanup()
        
        playerController = nil
        hostingController = nil
    }
    
    func configure(clip: ClipPost) {
        if playerController == nil {
            playerController = AmityMediaPlayerController()
        }
        
        setupPlayer(clip: clip)
        setupOverlay(clip: clip)
    }
    
    private func setupPlayer(clip: ClipPost) {
        guard let playerController else {
            Log.warn("❌ Weird 👀 PlayerController instance is nil")
            return
        }
        
        guard playerController.player == nil else {
            Log.warn("❌ PlayerController is already setup for this cell - \(clip.model.postId)")
            return
        }
        
        let playerLayer = AVPlayerLayerCache.shared.getPlayerLayer(for: clip.url, id: clip.id)
        playerController.configure(playerLayer: playerLayer)
        playerLayer.frame = contentView.bounds
        
        if case .clip(let data) = clip.model.content {
            playerController.isMuted = data.isMuted
            playerLayer.player?.isMuted = data.isMuted
            
            if data.displayMode == .fit {
                playerLayer.videoGravity = .resizeAspect
            }
        }

        contentView.layer.addSublayer(playerLayer)
    }

    private func setupOverlay(clip: ClipPost) {
        guard let playerController else {
            Log.warn("❌ Weird 👀 PlayerController instance is nil")
            return
        }
        
        guard hostingController == nil else {
            Log.warn("❌ HostingController is not nil - \(clip.model.postId)")
            return
        }
                
        let overlayView = ClipFeedItemOverlayView(post: clip.model, playerController: playerController, isInteractionEnabled: clip.isInteractionEnabled, onTapAction: onTapAction)
        hostingController = UIHostingController(rootView: overlayView)
        
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.frame = contentView.bounds
        hostingController?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // we are 100% sure that hosting controller exists at this point
        contentView.addSubview(hostingController!.view)
    }
    
    func playVideo() {
        guard playerController?.player != nil else { return }
        
        playerController?.play()
    }
    
    func pauseVideo() {
        guard playerController?.player != nil else { return }
        
        playerController?.pause()
    }
    
    func cleanup() {
        playerController?.cleanup()
        
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        hostingController?.view.frame = contentView.bounds
    }
    
    deinit {
        Log.add(event: .info, "ClipFeedCell deinitialized")
        cleanup()
    }
}
