//
//  AmitySocialReactionPicker.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/13/25.
//

import SwiftUI
import Combine
import AmitySDK

public class AmitySocialReactionPickerOverlay {
    public static let shared = AmitySocialReactionPickerOverlay()
    private var viewModel = AmitySocialReactionPickerViewModel(referenceType: .post, referenceId: "")
    private var shouldShownBottom: Bool = false
    
    private init() {}
    
    public func show(frame: CGRect,
                     viewModel: AmitySocialReactionPickerViewModel,
                     alignRight: Bool = false) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        let oneThirdScreenHeight = UIScreen.main.bounds.height / 3.1
        shouldShownBottom = frame.origin.y >= 0 && frame.origin.y <= oneThirdScreenHeight
        
        self.viewModel = viewModel
        self.viewModel.animateToTop = shouldShownBottom ? false : true
        
        let vc = AmitySwiftUIHostingController(rootView: AmitySocialReactionPicker(viewModel: viewModel, pageId: nil))
        
        let intrinsicSize = vc.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let x = alignRight ? frame.origin.x - intrinsicSize.width : frame.origin.x
        let startY = frame.origin.y - 40
        let finalY = shouldShownBottom ? frame.origin.y + 20 : frame.origin.y - 68
        vc.view.frame = CGRect(x: x, y: startY, width: intrinsicSize.width, height: intrinsicSize.height)
        vc.view.backgroundColor = .clear
        vc.view.alpha = 0
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        containerView.tag = 101010
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        containerView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
                
        containerView.addSubview(vc.view)
        window.addSubview(containerView)
        
        // Animate to final position
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            vc.view.frame.origin.y = finalY
            vc.view.alpha = 1.0
        }
    }
    
    @discardableResult
    public func checkHoveredReactionOnDrag(at point: CGPoint) -> String? {
        // Save the initial drag point
        if viewModel.initialDragPoint == .zero {
            viewModel.initialDragPoint = point
        }
        
        guard arePointsDistinct(point, viewModel.initialDragPoint, distance: 10) else { return nil }
        return viewModel.checkHoveredReaction(at: point)
    }
    
    public func addHoveredReactionDragEnded(at point: CGPoint) {
        if let hoveredReaction = viewModel.hoveredReaction {
            viewModel.setReaction(reaction: hoveredReaction)
            AmitySocialReactionPickerOverlay.shared.dismiss()
        } else if arePointsDistinct(point, viewModel.initialDragPoint, distance: 40) {
            AmitySocialReactionPickerOverlay.shared.dismiss()
        }
    }
  
    @objc public func dismiss() {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        
        if let window = keyWindow {
            for subview in window.subviews {
                if subview.tag == 101010 {
                    // Animate to orginal position
                    UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
                        subview.frame.origin.y = self.shouldShownBottom ? subview.frame.origin.y - 35 : subview.frame.origin.y + 35
                        subview.alpha = 0.0
                    } completion: { _ in
                        subview.removeFromSuperview()
                        self.cleanUpDataOnDismiss()
                    }
                }
            }
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: nil)
        
        switch gesture.state {
        case .began: break
            
        case .changed:
            checkHoveredReactionOnDrag(at: point)
            
        case .ended:
            addHoveredReactionDragEnded(at: point)
            
        default: break
        }
    }
    
    private func arePointsDistinct(_ point1: CGPoint, _ point2: CGPoint, distance: CGFloat) -> Bool {
        let deltaX = abs(point1.x - point2.x)
        let deltaY = abs(point1.y - point2.y)
        return deltaX >= distance || deltaY >= distance
    }
    
    private func cleanUpDataOnDismiss() {
        self.viewModel = AmitySocialReactionPickerViewModel(referenceType: .post, referenceId: "")
    }
}


public struct AmitySocialReactionPicker: AmityComponentView {
    
    public var pageId: PageId?
    public var id: ComponentId {
        .reactionBar
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @ObservedObject private var viewModel: AmitySocialReactionPickerViewModel
    
    public init(viewModel: AmitySocialReactionPickerViewModel, pageId: PageId? = nil) {
        self.viewModel = viewModel
        self.pageId = pageId
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .reactionBar))
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(SocialReactionConfiguration.shared.allReactions, id: \.id) { reaction in
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.all, 8)
        .background(Color(viewConfig.theme.backgroundColor))
        .cornerRadius(999)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .overlay(
            HStack(spacing: 8) {
                ForEach(SocialReactionConfiguration.shared.allReactions, id: \.id) { reaction in
                    Image(reaction.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .scaleEffect(viewModel.hoveredReaction ?? "" == reaction.name ? 1.25 : 1.0)
                        .offset(y: viewModel.hoveredReaction ?? "" == reaction.name ? (viewModel.animateToTop ? -10 : 10) : 0)
                        .background(
                            Circle()
                                .fill(Color(viewConfig.theme.baseColorShade4))
                                .frame(width: 38, height: 38)
                                .isHidden(reaction.name != viewModel.currentReaction)
                        )
                        .zIndex(viewModel.hoveredReaction ?? "" == reaction.name ? 1 : 0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.35), value: viewModel.hoveredReaction)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: SingleReactionFrameKey.self,
                                        value: ReactionFrame(
                                            id: reaction.name,
                                            frame: geometry.frame(in: .global)
                                        )
                                    )
                            }
                        )
                        .onPreferenceChange(SingleReactionFrameKey.self) { reactionFrame in
                            if let frame = reactionFrame {
                                viewModel.reactionFrames[frame.id] = frame.frame
                            }
                        }
                        .overlay(
                            ZStack {
                                Text(reaction.name.capitalizeFirstLetter())
                                    .applyTextStyle(.captionSmall(.white))
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(20, corners: .allCorners)
                                    .opacity(viewModel.hoveredReaction ?? "" == reaction.name ? 1.0 : 0.0)
                                    .offset(y: viewModel.animateToTop ? -60 : 30)
                            }
                            .allowsHitTesting(false)
                            .frame(width: 70, height: 200) // Make frame larger than needed
                            .frame(maxWidth: 80)
                            .offset(y: 14)
                            .clipped(antialiased: false)
                        )
                        .onTapGesture {
                            viewModel.setReaction(reaction: reaction.name)
                            AmitySocialReactionPickerOverlay.shared.dismiss()
                        }
                }
            }
        )
    }
}

public class AmitySocialReactionPickerViewModel: ObservableObject {
    @Published var reactionFrames: [String: CGRect] = [:]
    @Published var hoveredReaction: String? = nil
    private let reactionManager = ReactionManager()
    
    let referenceType: AmityReactionReferenceType
    let referenceId: String
    let currentReaction: String?
    let onReactionAdded: ((String) -> Void)?
    let onReactionRemoved: ((String) -> Void)?
    
    var initialDragPoint: CGPoint = .zero
    var animateToTop: Bool = true
    
    init(referenceType: AmityReactionReferenceType, referenceId: String, currentReaction: String? = nil, onReactionAdded: ((String) -> Void)? = nil, onReactionRemoved: ((String) -> Void)? = nil) {
        self.referenceType = referenceType
        self.referenceId = referenceId
        self.currentReaction = currentReaction
        self.onReactionAdded = onReactionAdded
        self.onReactionRemoved = onReactionRemoved
    }
    
    @discardableResult
    public func checkHoveredReaction(at point: CGPoint) -> String? {
        var matchedReaction: String? = nil
        
        for (reactionName, frame) in reactionFrames {
            let enlargedFrame = enlargeFrame(frame: frame, width: 10, height: 200)
            
            if enlargedFrame.contains(point) {
                matchedReaction = reactionName
            }
        }
        
        if matchedReaction != nil, hoveredReaction != matchedReaction {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            hoveredReaction = matchedReaction
        }
        
        if matchedReaction == nil {
            hoveredReaction = nil
        }
        
        return matchedReaction
    }
    
    public func setReaction(reaction: String) {
        ImpactFeedbackGenerator.impactFeedback(style: .medium)
        Task.runOnMainActor {
            do {
                if let currentReaction = self.currentReaction, currentReaction == reaction {
                    try await self.reactionManager.removeReaction(currentReaction, referenceId: self.referenceId, referenceType: self.referenceType)
                    self.onReactionRemoved?(currentReaction)
                } else {
                    try await self.reactionManager.addReaction(reaction, referenceId: self.referenceId, referenceType: self.referenceType)
                    
                    if let currentReaction = self.currentReaction {
                        try await self.reactionManager.removeReaction(currentReaction, referenceId: self.referenceId, referenceType: self.referenceType)
                        self.onReactionRemoved?(currentReaction)
                    }
                    
                    self.onReactionAdded?(reaction)
                }
            } catch {
                Log.add(event: .error, "Failed to add or remove reaction: \(error.localizedDescription)")
                Toast.showToast(style: .warning, message: "Oops, something went wrong.")
            }
        }
    }
    
    private func enlargeFrame(frame: CGRect, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(
            x: frame.origin.x - width,
            y: frame.origin.y - height,
            width: frame.width + width * 2,
            height: frame.height + height * 2
        )
    }
}

struct ReactionFrame: Equatable {
    let id: String
    let frame: CGRect
}

struct SingleReactionFrameKey: PreferenceKey {
    static var defaultValue: ReactionFrame? = nil
    static func reduce(value: inout ReactionFrame?, nextValue: () -> ReactionFrame?) {
        // This will be called multiple times, but SwiftUI handles it
        value = nextValue() ?? value
    }
}
