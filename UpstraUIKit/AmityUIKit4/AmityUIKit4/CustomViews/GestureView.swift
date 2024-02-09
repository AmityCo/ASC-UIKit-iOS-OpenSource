//
//  GestureView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/28/23.
//

import UIKit
import SwiftUI

struct GestureView: UIViewRepresentable {
    var onLeftTap: (() -> Void)?
    var onRightTap: (() -> Void)?
    var onTouchAndHoldStart: (() -> Void)?
    var onTouchAndHoldEnd: (() -> Void)?
    var onDragBegan: ((CGPoint) -> Void)?
    var onDragChanged: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

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
    var onDragBegan: ((CGPoint) -> Void)?
    var onDragChanged: ((CGPoint) -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

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

        switch gesture.state {
        case .began:
            let translation = gesture.translation(in: gestureView)
            onDragBegan?(translation)
        case .changed:
            let translation = gesture.translation(in: gestureView)
            onDragChanged?(translation)
        case .ended:
            let translation = gesture.translation(in: gestureView)
            onDragEnded?(translation)
        default:
            break
        }
    }
}