//
//  GestureView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/28/23.
//

import UIKit
import SwiftUI

enum DragGestureDirection {
    case rightward, leftward, downward, upward
}

struct GestureView: UIViewRepresentable {
    var onLeftTap: (() -> Void)?
    var onRightTap: (() -> Void)?
    var onTouchAndHoldStart: (() -> Void)?
    var onTouchAndHoldEnd: (() -> Void)?
    var onDragBegan: ((DragGestureDirection, CGPoint) -> Void)?
    var onDragChanged: ((DragGestureDirection, CGPoint) -> Void)?
    var onDragEnded: ((DragGestureDirection, CGPoint) -> Void)?

    func makeUIView(context: Context) -> GestureUIView {
        let gestureView = GestureUIView()

        gestureView.onLeftTap = onLeftTap
        gestureView.onRightTap = onRightTap
        gestureView.onTouchAndHoldStart = onTouchAndHoldStart
        gestureView.onTouchAndHoldEnd = onTouchAndHoldEnd
        gestureView.onDragBegan = onDragBegan
        gestureView.onDragChanged = onDragChanged
        gestureView.onDragEnded = onDragEnded

        return gestureView
    }

    func updateUIView(_ uiView: GestureUIView, context: Context) {
        // Nothing to update the view
    }
}


class GestureUIView: UIView {
    var onLeftTap: (() -> Void)?
    var onRightTap: (() -> Void)?
    var onTouchAndHoldStart: (() -> Void)?
    var onTouchAndHoldEnd: (() -> Void)?
    var onDragBegan: ((DragGestureDirection, CGPoint) -> Void)?
    var onDragChanged: ((DragGestureDirection, CGPoint) -> Void)?
    var onDragEnded: ((DragGestureDirection, CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.1
        
        let panAndScaleGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanAndScale(_:)))
        
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(longPressGesture)
        self.addGestureRecognizer(panAndScaleGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)

        if tapLocation.x < bounds.width / 2 {
            onLeftTap?()
        } else {
            onRightTap?()
        }
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            onTouchAndHoldStart?()
        } else if gesture.state == .ended {
            onTouchAndHoldEnd?()
        }
    }
    
    @objc private func handlePanAndScale(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
        let translation = gesture.translation(in: gestureView)
        let velocity = gesture.velocity(in: gestureView)
        let direction: DragGestureDirection
        
        if abs(translation.x) > abs(translation.y) {
            // Horizontal movement
            if velocity.x > 0 {
                // Rightward movement
                direction = .rightward
            } else {
                // Leftward movement
                direction = .leftward
            }
        } else {
            // Vertical movement
            if velocity.y > 0 {
                // Downward movement
                direction = .downward
            } else {
                // Upward movement
                direction = .upward
            }
        }
        
        switch gesture.state {
        case .began:
            onDragBegan?(direction, translation)
        case .changed:
            onDragChanged?(direction, translation)
        case .ended:
            onDragEnded?(direction, translation)
        default:
            break
        }
    }
}


struct InteractionReaderViewModifier: ViewModifier {
    
    var longPressSensitivity: Int
    var tapAction: () -> Void
    var longPressAction: () -> Void
    var dragChangedAction: (CGPoint) -> Void
    var dragEndedAction: (CGPoint) -> Void
    var scaleEffect: Bool = false
    
    @State private var isPressing: Bool = Bool()
    @State private var currentDismissId: DispatchTime = DispatchTime.now()
    @State private var lastInteractionKind: String = String()
    
    func body(content: Content) -> some View {
        
        let processedContent = content
            .gesture(gesture)
            .onChange(of: isPressing) { newValue in
                
                currentDismissId = DispatchTime.now() + .milliseconds(longPressSensitivity)
                let dismissId: DispatchTime = currentDismissId
                
                if isPressing {
                    DispatchQueue.main.asyncAfter(deadline: dismissId) {
                        if isPressing {
                            if (dismissId == currentDismissId) {
                                lastInteractionKind = "longPress";
                                longPressAction()
                            }
                        }
                    }
                }
                else {
                    if (lastInteractionKind != "longPress") {
                        lastInteractionKind = "tap"
                        tapAction()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                        lastInteractionKind = "none"
                    }
                }
                
            }
        
        return processedContent
    }
    
    var gesture: some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
            .onChanged() { value in
                if !isPressing {
                    isPressing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(longPressSensitivity + 10)) {
                        dragChangedAction(value.location)
                    }
                } else {
                    dragChangedAction(value.location)
                }
            }
            .onEnded() {
                value in
                isPressing = false
                dragEndedAction(value.location)
            }
    }
    
}


extension View {
    func tapAndDragSimutaneousGesture(longPressSensitivity: Int,
                           tapAction: @escaping () -> Void,
                           longPressAction: @escaping () -> Void,
                           dragChangedAction: @escaping (CGPoint) -> Void,
                           dragEndedAction: @escaping (CGPoint) -> Void) -> some View {
        return self.modifier(InteractionReaderViewModifier(longPressSensitivity: longPressSensitivity,
                                                           tapAction: tapAction,
                                                           longPressAction: longPressAction,
                                                           dragChangedAction: dragChangedAction,
                                                           dragEndedAction: dragEndedAction))
    }
}
