//
//  MessageOverlay.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI

public class MessageOverlay: UIViewController {
    
    var message: MessageModel?
    var nameSpace: Namespace.ID?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
    }
    
    public static func showOverlay(message: MessageModel, messageAction: AmityMessageAction, nameSpace: Namespace.ID, position: CGPoint) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        blurEffectView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blurEffectView)
        
        let overlayView = MessageOverlayView(isMenuActive: true, message: message, messageAction: messageAction, namespace: nameSpace, dismissAction: {
            dismissBlurView()
            
        }).environmentObject(AmityViewConfigController(pageId: .liveChatPage, componentId: .messageList))

        let hostingController = UIHostingController(rootView: overlayView)
        hostingController.view.backgroundColor = .clear
        
        let hostingView = hostingController.view!
        
        let contentSize = hostingView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: CGFloat.infinity))
        
        // Set the frame of the hostingController.view based on the content size and desired position
        hostingController.view.frame = CGRect(x: position.x, y: position.y, width: contentSize.width, height: contentSize.height)
        hostingController.view.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]

        
        hostingController.view.frame = CGRect(x: position.x - 50, y: position.y - 50, width: 300, height: 300) // Adjust the width and height as needed
        hostingController.view.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        
        blurEffectView.contentView.addSubview(hostingController.view)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissBlurView))
        blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private static func dismissBlurView() {
        
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        
        if let window = keyWindow {
            for subview in window.subviews {
                if subview is UIVisualEffectView {
                    UIView.animate(withDuration: 0.2, animations: {
                        subview.alpha = 0.0
                    }, completion: { _ in
                        subview.removeFromSuperview()
                    })
                }
            }
        }
    }
}
