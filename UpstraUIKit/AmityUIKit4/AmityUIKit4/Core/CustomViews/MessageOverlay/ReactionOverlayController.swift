//
//  ReactionOverlayController.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI

public class ReactionOverlayController {
    
    public static func showOverlay<Content: View>(message: MessageModel, messageAction: AmityMessageAction, nameSpace: Namespace.ID, messageFrame: CGRect, content: @escaping () -> Content) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.effect = nil
        
        blurEffectView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blurEffectView)
        
        let actionMenuWidth: CGFloat = 245
        
        let overlayView = MessageActionOverlayView(isMenuActive: true, message: message, messageAction: messageAction, namespace: nameSpace, actionMenuWidth: actionMenuWidth , content: {
            content()
        },  dismissAction: {
            dismissBlurView()
        }).environmentObject(AmityViewConfigController(pageId: .liveChatPage, componentId: .messageList))
        
        let hostingController = UIHostingController(rootView: overlayView)
        hostingController.view.backgroundColor = .clear
        
        let hostingView = hostingController.view!
        
        let overlayViewWidth: CGFloat = max(messageFrame.width, actionMenuWidth)
        
        let contentSize = hostingView.sizeThatFits(CGSize(width: overlayViewWidth, height: CGFloat.infinity))
        
        let messagePosition = messageFrame.origin
        // Set the frame of the hostingController.view based on the content size and desired position
        let positionY: CGFloat
        if let screenHeight = window.windowScene?.screen.bounds.height, screenHeight - messagePosition.y < contentSize.height {
            /// If the content will present exceed window height, we fix the position to screen height - it's size - bottom inset
            positionY = screenHeight - contentSize.height - window.safeAreaInsets.bottom
        } else if messagePosition.y < window.safeAreaInsets.top {
            positionY = window.safeAreaInsets.top
        } else {
            /// The height of reaction picker view is 54 and the padding is 8 so we deduct 62 more for Y position
            positionY = messagePosition.y - 62
        }
        hostingController.view.frame = CGRect(x: messagePosition.x, y: positionY, width: contentSize.width, height: contentSize.height)
        hostingController.view.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        
        blurEffectView.contentView.addSubview(hostingController.view)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissBlurView))
        blurEffectView.addGestureRecognizer(tapGestureRecognizer)

        UIView.animate(withDuration: 0.3) {
            blurEffectView.effect = UIBlurEffect(style: .light)
        } completion: { isCompleted in
            // Hide keyboard if its present.
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
