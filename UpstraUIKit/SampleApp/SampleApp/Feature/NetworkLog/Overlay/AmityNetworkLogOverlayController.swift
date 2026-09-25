//
//  AmityNetworkLogOverlayController.swift
//  SampleApp
//

import SwiftUI
import UIKit
import Combine
import AmitySDK

/// Owns capture, the launcher button, and presentation of the viewer.
///
/// ## Why this is a presentation rather than a dock
///
/// The feature was specified as a panel docked beside the running app, so a tester could watch
/// traffic while driving the UIKit. That needs the log to live in a window above the app and to
/// pass touches through everywhere it is not — and hosting SwiftUI in such a window proved
/// fragile: hit testing had to be told which rects were live, and insetting the app's root view
/// controller to make room relayouted the whole hierarchy on every drag frame.
///
/// The viewer is now presented modally instead. The app is not interactive while it is open,
/// which is a real loss against the original requirement, but everything that made the docked
/// version unusable is gone with it. The launcher stays in its own window so it survives page
/// transitions; it is plain UIKit, so its hit testing is correct without any special casing.
final class AmityNetworkLogOverlayController: ObservableObject {

    static let shared = AmityNetworkLogOverlayController()

    private enum DefaultsKey {
        static let isVisible = "asc_sample_network_log_button_visible"
    }

    let collector = AmityNetworkLogCollector()
    let viewModel = AmityNetworkLogViewModel()

    private var overlayWindow: AmityNetworkLogOverlayWindow?
    private var launcher: AmityNetworkLogLauncherViewController?
    private weak var hostScene: UIWindowScene?
    private weak var presentedViewer: UIViewController?
    private var cancellables = Set<AnyCancellable>()
    /// Type-erased because the delegate type is iOS 15 and a stored property cannot be gated.
    private var sheetObserver: AnyObject?

    /// Whether the viewer is at the full-height detent. Drives the expand/collapse control,
    /// and is kept in step when the tester drags the sheet instead of tapping it.
    @Published private(set) var isViewerExpanded = false

    private init() {}

    /// Whether the tester has hidden the launcher from Advanced options.
    ///
    /// Hiding removes the button only — the collector stays subscribed, so switching it back on
    /// shows everything captured while it was hidden.
    var isButtonVisible: Bool {
        get {
            guard UserDefaults.standard.object(forKey: DefaultsKey.isVisible) != nil else { return true }
            return UserDefaults.standard.bool(forKey: DefaultsKey.isVisible)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKey.isVisible)
            newValue ? show() : hide()
        }
    }

    var isPresented: Bool { presentedViewer != nil }

    // MARK: - Lifecycle

    /// Subscribes the collector, long before any UI exists. The stream has no replay, so a
    /// subscription deferred until the viewer opens silently loses the login burst.
    func startCapturing(client: AmityClient) {
        collector.start(client: client)
        NetworkLogUITestSeed.seedIfRequested(into: collector)
    }

    /// Attaches the launcher window to a scene. Safe to call more than once.
    func attach(to scene: UIWindowScene) {
        hostScene = scene
        guard isButtonVisible else { return }
        show()
    }

    func show() {
        guard let scene = hostScene, isButtonVisible else { return }

        if overlayWindow == nil {
            let launcher = AmityNetworkLogLauncherViewController()
            launcher.onTap = { [weak self] in self?.present() }

            let window = AmityNetworkLogOverlayWindow(windowScene: scene)
            window.windowLevel = .alert - 1
            window.backgroundColor = .clear
            window.rootViewController = launcher
            window.isHidden = false

            overlayWindow = window
            self.launcher = launcher
            observeCaptureCount()
        }

        overlayWindow?.isHidden = false
    }

    func hide() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
        launcher = nil
        cancellables.removeAll()
    }

    // MARK: - Presentation

    func present() {
        guard presentedViewer == nil, let presenter = topmostViewController() else { return }
        // The viewer is an iOS 15 surface; on iOS 14 capture still runs with nothing to show it.
        guard #available(iOS 15.0, *) else { return }

        let viewer = UIHostingController(
            rootView: AmityNetworkLogPageContainer(controller: self)
        )
        viewer.modalPresentationStyle = .pageSheet
        configureSheet(on: viewer)

        presentedViewer = viewer
        // The launcher would otherwise sit on top of the viewer it opened.
        overlayWindow?.isHidden = true
        presenter.present(viewer, animated: true)
    }

    /// Two detents, and no dimming at the smaller one.
    ///
    /// `largestUndimmedDetentIdentifier` is what makes this worth doing: at the half-height
    /// detent the app behind stays interactive, so a tester can drive the UIKit and watch the
    /// traffic it makes. That was the point of the original docked panel, and the system sheet
    /// provides it without an overlay window to hit-test by hand.
    @available(iOS 15.0, *)
    private func configureSheet(on viewer: UIViewController) {
        guard let sheet = viewer.sheetPresentationController else { return }
        sheet.detents = [.medium(), .large()]
        sheet.selectedDetentIdentifier = .medium
        sheet.largestUndimmedDetentIdentifier = .medium
        sheet.prefersGrabberVisible = true
        // Otherwise scrolling the timeline to its top expands the sheet under your finger.
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        let observer = SheetDetentObserver()
        observer.onDetentChange = { [weak self] identifier in
            self?.isViewerExpanded = identifier == .large
        }
        // A sheet can be swiped away as well as closed, and that path never reaches dismiss().
        // Without this the launcher stayed hidden and the viewer looked gone for good.
        observer.onDismiss = { [weak self] in
            self?.viewerWasDismissed()
        }
        sheetObserver = observer
        sheet.delegate = observer
        isViewerExpanded = false
    }

    /// Toggles between the two detents, animated, so the control and the drag agree.
    @available(iOS 15.0, *)
    func toggleViewerSize() {
        guard let sheet = presentedViewer?.sheetPresentationController else { return }
        let next: UISheetPresentationController.Detent.Identifier = isViewerExpanded ? .medium : .large
        sheet.animateChanges {
            sheet.selectedDetentIdentifier = next
        }
        isViewerExpanded = next == .large
    }

    func dismiss() {
        guard let viewer = presentedViewer else { return }
        presentedViewer = nil
        viewer.dismiss(animated: true) { [weak self] in
            self?.restoreLauncher()
        }
    }

    /// Called when the sheet goes away by any route, including a swipe.
    private func viewerWasDismissed() {
        presentedViewer = nil
        isViewerExpanded = false
        restoreLauncher()
    }

    private func restoreLauncher() {
        guard isButtonVisible else { return }
        overlayWindow?.isHidden = false
    }

    // MARK: - Internals

    private func observeCaptureCount() {
        collector.$entries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                let status = entries.last(where: { $0.statusLabel != nil })?.statusLabel ?? "—"
                self?.launcher?.button.update(count: entries.count, status: status)
            }
            .store(in: &cancellables)
    }

    /// The app's own topmost controller — never the launcher window's, which would present the
    /// viewer into a window that is about to be hidden.
    private func topmostViewController() -> UIViewController? {
        let appWindow = hostScene?.windows.first { $0 !== overlayWindow && $0.isKeyWindow }
            ?? hostScene?.windows.first { $0 !== overlayWindow }
        var top = appWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Relays detent changes so the expand control stays in step when the sheet is dragged.
@available(iOS 15.0, *)
private final class SheetDetentObserver: NSObject, UISheetPresentationControllerDelegate {

    var onDetentChange: ((UISheetPresentationController.Detent.Identifier?) -> Void)?

    var onDismiss: (() -> Void)?

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        onDetentChange?(sheetPresentationController.selectedDetentIdentifier)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss?()
    }
}

/// Keeps the page bound to the controller's published detent state.
///
/// A `UIHostingController` captures its root view once, so the page has to observe the
/// controller rather than be handed a snapshot — otherwise the expand control would never
/// change after a drag.
@available(iOS 15.0, *)
private struct AmityNetworkLogPageContainer: View {

    @ObservedObject var controller: AmityNetworkLogOverlayController

    var body: some View {
        AmityNetworkLogPage(
            collector: controller.collector,
            model: controller.viewModel,
            onDismiss: { controller.dismiss() },
            isExpanded: controller.isViewerExpanded,
            onToggleSize: { controller.toggleViewerSize() }
        )
    }
}
