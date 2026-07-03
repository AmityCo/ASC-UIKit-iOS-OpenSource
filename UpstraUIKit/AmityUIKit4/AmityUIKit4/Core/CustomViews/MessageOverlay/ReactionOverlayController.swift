//
//  ReactionOverlayController.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 3/5/2567 BE.
//

import SwiftUI
import AmitySDK

public class ReactionOverlayController {
    private static var currentHostingController: UIHostingController<AnyView>?
    private static var onChatDismiss: (() -> Void)?
    private static var chatHoverVM: ChatReactionPickerViewModel?
    private static var chatReactionVM: AmityLiveChatMessageReactionPickerViewModel?
    
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
        
        let hostingController = UIHostingController(rootView: AnyView(overlayView))
        hostingController.view.backgroundColor = .clear
        ReactionOverlayController.currentHostingController = hostingController
        
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
    
    public static func showChatOverlay<Content: View>(message: MessageModel, messageAction: AmityMessageAction, nameSpace: Namespace.ID, messageFrame: CGRect, content: @escaping () -> Content, onDismiss: (() -> Void)? = nil) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        onChatDismiss = onDismiss

        let screenBounds = window.windowScene?.screen.bounds ?? UIScreen.main.bounds
        let horizontalPadding: CGFloat = 16
        let gap: CGFloat = 2

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height))
        containerView.backgroundColor = .clear
        containerView.tag = 202020
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissChatDimView))
        containerView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleChatPanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)

        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // ── Helper: clamp X so card stays inside screen ────────────────────────
        func clampedX(from originX: CGFloat, width: CGFloat) -> CGFloat {
            var x = originX
            if x + width > screenBounds.width - horizontalPadding {
                x = screenBounds.width - width - horizontalPadding
            }
            return max(horizontalPadding, x)
        }

        // ── 1. Reaction picker ───────────
        let screenThreshold = (screenBounds.height - 50) * 0.7
        let isInLowerPortion = messageFrame.origin.y > screenThreshold

        // ── Hover view model for drag-to-react ───────────────────────────────
        let hoverVM = ChatReactionPickerViewModel()
        hoverVM.showTooltipBelow = !isInLowerPortion && (messageFrame.origin.y - 60 < window.safeAreaInsets.top + 40)
        chatHoverVM = hoverVM

        let viewConfig = AmityViewConfigController(pageId: .liveChatPage, componentId: .messageList)
        let reactionVC: UIViewController = AmitySwiftUIHostingController(rootView:
            ChatReactionPickerView(message: message, hoverVM: hoverVM, dismissAction: { dismissChatDimView() })
                .environmentObject(viewConfig)
        )
        reactionVC.view.backgroundColor = .clear
        reactionVC.view.alpha = 0
        let reactionSize = reactionVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let reactionX = clampedX(from: messageFrame.origin.x, width: reactionSize.width)
        let reactionFinalY = max(
            window.safeAreaInsets.top + 4,
            messageFrame.origin.y - reactionSize.height - gap
        )
        reactionVC.view.frame = CGRect(x: reactionX, y: messageFrame.origin.y - 40, width: reactionSize.width, height: reactionSize.height)
        containerView.addSubview(reactionVC.view)

        // ── 2. Action menu ─────────────────────────
        let actionVC: UIViewController = AmitySwiftUIHostingController(rootView:
            ChatActionMenuView(message: message, messageAction: messageAction, dismissAction: { dismissChatDimView() })
                .environmentObject(viewConfig)
        )
        actionVC.view.backgroundColor = .clear
        actionVC.view.alpha = 0
        let actionWidth: CGFloat = 160 + 4 + 4
        let actionHeight = actionVC.view.systemLayoutSizeFitting(
            CGSize(width: actionWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let actionX = clampedX(from: messageFrame.origin.x, width: actionWidth)
        let bottomLimit = screenBounds.height - window.safeAreaInsets.bottom - 8
        let topLimit = window.safeAreaInsets.top + 4
        let aboveReactionY = reactionFinalY - actionHeight - gap
        let belowMessageY = messageFrame.maxY + gap

        var actionFinalY: CGFloat
        if isInLowerPortion {
            actionFinalY = aboveReactionY
            if actionFinalY < topLimit {
                actionFinalY = belowMessageY
            }
        } else {
            actionFinalY = belowMessageY
        }
        if actionFinalY + actionHeight > bottomLimit {
            if aboveReactionY >= topLimit {
                actionFinalY = aboveReactionY
            } else {
                actionFinalY = max(topLimit, bottomLimit - actionHeight)
            }
        }
        actionVC.view.frame = CGRect(x: actionX, y: messageFrame.origin.y - 40, width: actionWidth, height: actionHeight)
        containerView.addSubview(actionVC.view)

        window.addSubview(containerView)

        // ── Spring entrance ──
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            reactionVC.view.frame.origin.y = reactionFinalY
            reactionVC.view.alpha = 1.0
            actionVC.view.frame.origin.y = actionFinalY
            actionVC.view.alpha = 1.0
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
                        ReactionOverlayController.currentHostingController = nil
                    })
                }
            }
        }
    }

    @objc private static func dismissChatDimView() {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        if let window = keyWindow {
            for subview in window.subviews where subview.tag == 202020 {
                UIView.animate(withDuration: 0.15, animations: {
                    subview.alpha = 0
                }, completion: { _ in
                    subview.removeFromSuperview()
                    ReactionOverlayController.currentHostingController = nil
                    ReactionOverlayController.chatHoverVM = nil
                    ReactionOverlayController.chatReactionVM = nil
                    let cb = onChatDismiss
                    onChatDismiss = nil
                    cb?()
                })
            }
        }
    }

    // MARK: - Chat reaction picker — drag-to-hover gesture

    @objc private static func handleChatPanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let hoverVM = chatHoverVM else { return }
        let point = gesture.location(in: nil)

        switch gesture.state {
        case .began:
            break
        case .changed:
            hoverVM.checkHoveredReaction(at: point)
        case .ended, .cancelled, .failed:
            if let hovered = hoverVM.hoveredReaction {
                hoverVM.commitReaction?(hovered)
                hoverVM.reset()
                dismissChatDimView()
            } else {
                hoverVM.reset()
            }
        default:
            break
        }
    }
}
