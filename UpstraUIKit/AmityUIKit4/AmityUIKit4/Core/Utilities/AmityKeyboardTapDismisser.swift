//
//  AmityKeyboardTapDismisser.swift
//  AmityUIKit4
//

import SwiftUI
import UIKit

/// Closes the keyboard when the user taps anywhere on the attached view except
/// an input field, a navigation bar or a "skip" area.
///
/// `AmitySwiftUIHostingController` attaches one to its view, so every page gets the
/// rule. Content shown outside that controller (SwiftUI `.sheet` / `.fullScreenCover`)
/// uses `.dismissKeyboardOnTapOutside()`.
final class AmityKeyboardTapDismisser: NSObject, UIGestureRecognizerDelegate {

    /// Marked areas (weak, so closed screens are freed).
    static let markers = NSHashTable<AmityKeyboardMarkerView>.weakObjects()

    private lazy var tap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        return tap
    }()

    func attach(to view: UIView) {
        guard tap.view !== view else { return }
        tap.view?.removeGestureRecognizer(tap)
        view.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        // Let the tapped control run first, then close the keyboard. With no keyboard open
        // the action reaches no responder and does nothing.
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Which taps count

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Input fields (UITextField, UITextView, subclasses, custom text inputs)
        // and the system nav bar keep the keyboard open.
        var view = touch.view
        while let current = view {
            if current is UITextInput || current is UINavigationBar {
                return false
            }
            view = current.superview
        }

        // Nav bar, mention list, composer bar and search bar box keep the keyboard open.
        let point = touch.location(in: nil)
        return !Self.markers(in: touch.window).contains { $0.windowFrame.contains(point) }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    private static func markers(in window: UIWindow?) -> [AmityKeyboardMarkerView] {
        guard let window else { return [] }
        return markers.allObjects.filter { $0.window === window }
    }
}

// MARK: - Markers

/// Invisible view marking an area where taps keep the keyboard open
/// (nav bar, mention list, composer bar, search bar box).
final class AmityKeyboardMarkerView: UIView {

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        AmityKeyboardTapDismisser.markers.add(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var windowFrame: CGRect {
        convert(bounds, to: nil)
    }
}

private struct AmityKeyboardMarker: UIViewRepresentable {
    func makeUIView(context: Context) -> AmityKeyboardMarkerView {
        AmityKeyboardMarkerView()
    }

    func updateUIView(_ uiView: AmityKeyboardMarkerView, context: Context) {}
}

// MARK: - Extension for content outside AmitySwiftUIHostingController

/// Attaches a dismisser to the view of the controller hosting this SwiftUI content.
private final class AmityKeyboardTapAttacherView: UIView {
    private let dismisser = AmityKeyboardTapDismisser()

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController {
                dismisser.attach(to: controller.view)
                return
            }
            responder = current.next
        }
    }
}

private struct AmityKeyboardTapAttacher: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = AmityKeyboardTapAttacherView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    /// Same tap-outside rule as `AmitySwiftUIHostingController`, for content shown
    /// outside it (SwiftUI `.sheet` / `.fullScreenCover`).
    func dismissKeyboardOnTapOutside() -> some View {
        background(AmityKeyboardTapAttacher())
    }

    /// Taps on this view keep the keyboard open.
    func keyboardTapOutsideSkip() -> some View {
        background(AmityKeyboardMarker())
    }
}
