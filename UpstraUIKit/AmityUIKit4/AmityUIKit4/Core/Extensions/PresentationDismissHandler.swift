//
//  PresentationDismissHandler.swift
//  AmityUIKit4
//

import UIKit

/// A lightweight `UIViewController` that acts as a `UIAdaptivePresentationControllerDelegate`,
/// combining both dismiss callbacks in one reusable class.
///
/// **Two usage patterns:**
///
/// 1. **SwiftUI sheet interception** – embed via `UIViewControllerRepresentable` and set as the
///    parent's `presentationController?.delegate` to intercept swipe-to-dismiss when
///    `isModalInPresentation = true`.
///
/// 2. **Plain delegate** – retain via `objc_setAssociatedObject` and assign to
///    `presentationController?.delegate` to be notified when a sheet is actually dismissed.
class PresentationDismissHandler: UIViewController, UIAdaptivePresentationControllerDelegate {

    /// Called when the sheet is actually dismissed (swipe completed / not blocked).
    var onDismiss: (() -> Void)?

    /// Called when the user attempts to swipe-to-dismiss but the sheet is blocked
    /// (`isModalInPresentation = true`).
    var onDismissAttempted: (() -> Void)?

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss?()
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        onDismissAttempted?()
    }
}
