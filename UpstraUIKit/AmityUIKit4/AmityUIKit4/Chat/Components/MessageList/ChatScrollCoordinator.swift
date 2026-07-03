//
//  ChatScrollCoordinator.swift
//  AmityUIKit4
//
//  Single owner of every scroll-position DECISION for the chat v4 message list
//  (when to follow the bottom, FAB/banner visibility). The actual scroll ACTION
//  is delegated to `requestScrollToBottom`, which the view wires to SwiftUI's
//  `proxy.scrollTo(bottomAnchor, .bottom)`.
//
//  Why proxy.scrollTo and NOT raw contentOffset: a LazyVStack's contentSize is
//  ESTIMATED until rows are realized, so setting raw contentOffset to a computed
//  "bottom" during a full-array rebuild (cold .fresh load, message delete) lands
//  the viewport in unrealized rows → BLANK. proxy.scrollTo realizes the target
//  row first, so it can't blank. (That raw-offset pin was a regression; this
//  replaces it while keeping the single-owner latch + hysteresis.)
//
//  Replaces the previous tangle (two retry ladders, duplicate userHasScrolled,
//  contentSize-KVO raw pin, keyboard handlers, isInitialLoad/isAdjustingForKeyboard).
//
//  NOTE: iOS 14 SwiftUI scroll timing is fragile — verify ON DEVICE.
//

import SwiftUI
import UIKit

final class ChatScrollCoordinator: ObservableObject {

    // MARK: - Tunables

    private let enterFollowBand: CGFloat = 24
    private let leaveFollowBand: CGFloat = 80
    private let dragSlop: CGFloat = 10
    /// Bounded, re-arming follow schedule after the last content/viewport change
    /// (catches LazyVStack relayout batching + the .local→.fresh rebuild, which
    /// land with no user interaction). NOT the old 0...10s ladder.
    private let settleDelays: [TimeInterval] = [0.0, 0.1, 0.3]

    // MARK: - Published (drives FAB + new-message banner visibility)

    @Published private(set) var isNearBottom: Bool = true

    // MARK: - Action (wired by the view to proxy.scrollTo)

    /// Scroll the list to the bottom anchor. `animated` chooses the transition.
    /// Set by the view inside its ScrollViewReader.
    var requestScrollToBottom: ((_ animated: Bool) -> Void)?

    // MARK: - Private state

    private weak var scrollView: UIScrollView?
    private var offsetObs: NSKeyValueObservation?
    private var sizeObs: NSKeyValueObservation?
    private var boundsObs: NSKeyValueObservation?

    private var hasUserScrolled = false
    private var userIsDragging = false
    private var isPrepending = false
    private var lastBoundsHeight: CGFloat = 0
    private var settleWorkItems: [DispatchWorkItem] = []

    /// The single source of truth for "stick to the bottom?".
    private var autoFollow: Bool { !hasUserScrolled || isNearBottom }

    // MARK: - Lifecycle

    init() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardSettled),
                       name: UIResponder.keyboardDidShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardSettled),
                       name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    deinit {
        offsetObs?.invalidate()
        sizeObs?.invalidate()
        boundsObs?.invalidate()
        settleWorkItems.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Attach (called by the ScrollViewAttacher probe)

    func attach(_ sv: UIScrollView) {
        guard scrollView !== sv else { return }
        offsetObs?.invalidate()
        sizeObs?.invalidate()
        boundsObs?.invalidate()

        scrollView = sv
        lastBoundsHeight = sv.bounds.height

        sv.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))

        // contentOffset → maintain near-bottom hysteresis (UIScrollView KVO is main-thread).
        offsetObs = sv.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.offsetChanged(sv)
        }
        // contentSize grows (new message / media bubble settle) → re-follow.
        sizeObs = sv.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            self?.followIfNeeded()
            self?.scheduleSettleFollow()
        }
        // viewport height changes (keyboard avoidance, rotation) → re-follow.
        boundsObs = sv.observe(\.bounds, options: [.new]) { [weak self] sv, _ in
            self?.boundsChanged(sv)
        }
    }

    // MARK: - KVO handlers

    private func distanceFromBottom(_ sv: UIScrollView) -> CGFloat {
        let bottom = sv.contentSize.height + sv.adjustedContentInset.bottom
        let visibleBottom = sv.contentOffset.y + sv.bounds.height
        return max(0, bottom - visibleBottom)
    }

    private func offsetChanged(_ sv: UIScrollView) {
        guard hasUserScrolled else {
            if !isNearBottom { isNearBottom = true }
            return
        }
        let d = distanceFromBottom(sv)
        if d <= enterFollowBand {
            if !isNearBottom { isNearBottom = true }
        } else if d >= leaveFollowBand {
            if isNearBottom { isNearBottom = false }
        }
    }

    private func boundsChanged(_ sv: UIScrollView) {
        let h = sv.bounds.height
        guard h != lastBoundsHeight else { return } // ignore pure scrolls (origin change)
        lastBoundsHeight = h
        followIfNeeded()
        scheduleSettleFollow()
    }

    @objc private func keyboardSettled() {
        guard let sv = scrollView else { return }
        lastBoundsHeight = sv.bounds.height
        followIfNeeded()
        scheduleSettleFollow()
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began, .changed:
            if abs(gr.translation(in: gr.view).y) > dragSlop {
                hasUserScrolled = true
                userIsDragging = true
            }
        case .ended, .cancelled, .failed:
            userIsDragging = false
        default:
            break
        }
    }

    // MARK: - Follow (delegates to proxy.scrollTo via requestScrollToBottom)

    private func followIfNeeded() {
        guard autoFollow, !userIsDragging, !isPrepending else { return }
        requestScrollToBottom?(false)
    }

    /// Bounded, re-arming re-follow. Each call cancels the prior schedule so the
    /// window is measured from the LAST change and never accumulates.
    private func scheduleSettleFollow() {
        settleWorkItems.forEach { $0.cancel() }
        settleWorkItems.removeAll()
        for delay in settleDelays {
            let item = DispatchWorkItem { [weak self] in self?.followIfNeeded() }
            settleWorkItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
    }

    // MARK: - Intent API (called from the SwiftUI view)

    /// Follow to the bottom now and re-arm auto-follow (own-send, FAB tap,
    /// banner tap, initial load).
    func followToBottom(animated: Bool) {
        isNearBottom = true // re-arm: autoFollow becomes true
        requestScrollToBottom?(animated)
        scheduleSettleFollow()
    }

    /// Suppress the follow while older messages prepend, so restoring the read
    /// position (proxy.scrollTo(anchor, .top)) isn't yanked to the newest.
    func beginPrepend() { isPrepending = true }

    func endPrepend() {
        DispatchQueue.main.async { [weak self] in
            self?.isPrepending = false
        }
    }

    /// A centered jump-to-message is an explicit "reading up here" signal: drop
    /// auto-follow so the next media growth doesn't snap the user to the bottom.
    func markJumpedAway() {
        hasUserScrolled = true
        if isNearBottom { isNearBottom = false }
    }
}

// MARK: - ScrollView attach probe

/// Zero-size bridge that walks up to the `UIScrollView` SwiftUI creates for the
/// chat `ScrollView` and hands it to the coordinator (for the offset/size/bounds KVO).
struct ScrollViewAttacher: UIViewRepresentable {
    let coordinator: ChatScrollCoordinator

    func makeUIView(context: Context) -> UIView {
        let view = ProbeView()
        view.coordinator = coordinator
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? ProbeView)?.coordinator = coordinator
    }

    private final class ProbeView: UIView {
        weak var coordinator: ChatScrollCoordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var v: UIView? = superview
            while v != nil, !(v is UIScrollView) { v = v?.superview }
            if let sv = v as? UIScrollView { coordinator?.attach(sv) }
        }
    }
}
