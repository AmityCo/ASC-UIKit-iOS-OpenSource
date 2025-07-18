//
//  LiveReactionUIView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/1/25.
//

import UIKit
import SwiftUI

class LiveReactionUIView: UIView {
    private let viewModel: LiveReactionViewModel
    
    init(viewModel: LiveReactionViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect(x: 0, y: 0, width: viewModel.width, height: viewModel.height))
        viewModel.containerView = self
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        clipsToBounds = false
    }
    
    func addReaction(_ reaction: ReactionAnimationModel) {
        // Create UIImageView for the reaction
        let imageView = UIImageView()
        imageView.image = UIImage(resource: reaction.icon)
        imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        imageView.center = reaction.position
        imageView.transform = CGAffineTransform(scaleX: reaction.scale, y: reaction.scale)
            .rotated(by: CGFloat(reaction.angle * .pi / 180))
        imageView.alpha = reaction.opacity
        
        // Add to view hierarchy
        addSubview(imageView)
    
        // Animate the reaction
        animateReaction(imageView, reaction: reaction)
    }
    
    private func animateReaction(_ imageView: UIImageView, reaction: ReactionAnimationModel) {
        // Calculate end position
        let endX = reaction.position.x + CGFloat.random(in: -50...50)
        let endY: CGFloat = 0
        
        // Create animations
        UIView.animate(withDuration: 4.5, delay: 0, options: [.curveEaseOut], animations: {
            // Position animation
            imageView.center = CGPoint(x: endX, y: endY)
            
            // Scale animation
            imageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                .rotated(by: 0)
            
            // Opacity animation
            imageView.alpha = 0
            
        }) { _ in
            // Remove the image view after animation completes
            imageView.removeFromSuperview()
        }
    }
}

struct LiveReactionView: UIViewRepresentable {
    private let viewModel: LiveReactionViewModel
    
    init(viewModel: LiveReactionViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIView(context: Context) -> LiveReactionUIView {
        return LiveReactionUIView(viewModel: viewModel)
    }
    
    func updateUIView(_ uiView: LiveReactionUIView, context: Context) {
        // No updates needed
    }
}
