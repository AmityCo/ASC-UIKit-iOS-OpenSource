//
//  AmityPipController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/30/25.
//

import SwiftUI
import UIKit
import AVFoundation
import AVKit
import Combine

/// Shared PiP state for livestream content — both LIVE streams and RECORDED
/// livestream playback (room recordings). Clips and regular video posts are
/// out of scope and never enter PiP.
final class PiPState: ObservableObject {

    static let shared = PiPState()

    /// POC feature toggle. Flip to `false` for legacy pause-on-background.
    var isEnabled = true

    /// Whether this device/OS can do inline PiP at all.
    var isSupported: Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    /// True once a PiP session is (about to be) active.
    @Published private(set) var isActive = false

    /// The controller currently owning PiP, so views can request a stop.
    private weak var activeController: AmityPipController?

    private(set) var activeRoomId: String?

    func setActiveRoom(_ roomId: String?) {
        activeRoomId = roomId
    }

    private weak var activeLivestreamHost: UIViewController?

    func setActiveLivestreamHost(_ controller: UIViewController?) {
        activeLivestreamHost = controller
    }

    func isPiPActive(forRoomId roomId: String) -> Bool {
        isActive && activeRoomId == roomId
    }

    fileprivate func setActive(_ active: Bool) {
        isActive = active
    }

    fileprivate func register(_ controller: AmityPipController?) {
        activeController = controller
    }

    func stopActivePiP() {
        activeController?.stop()
    }

    /// Quietly stop the floating window because the user entered a surface that
    /// excludes PiP — other media (a clip / regular video post: two players must
    /// not run at once) or a broadcaster surface (co-host backstage/stage).
    func stopActivePiPForExcludedSurface() {
        guard isActive else { return }
        activeController?.stopWithoutRestore()
    }

    /// Stop the floating window because the viewer closed the livestream on purpose
    /// (the ✕). PiP exists to keep playback alive while they navigate AWAY, not when
    /// they deliberately leave, so the window must not outlive the page.
    ///
    /// `isActive` is cleared synchronously: the delegate's `didStop` is async and the
    /// page is about to be dismissed, so `Coordinator.deinit` would otherwise still
    /// see an active session and hand it to `LiveStreamPiPRetainer` — keeping alive
    /// the very window this is meant to close.
    func stopActivePiPForDeliberateExit() {
        guard isActive else { return }
        activeController?.stopWithoutRestore()
        setActive(false)
    }

    /// Temporarily prevent PiP from starting at all — used while the co-host
    /// invitation sheet is visible (a floating window would cover the sheet).
    /// Suppresses BOTH the explicit navigate-away start (`startPiPIfNeeded`)
    /// and the OS auto-start on backgrounding (must be set BEFORE any gesture:
    /// iOS evaluates auto-PiP at gesture start, so acting later is too late).
    /// Cleared when the sheet is dismissed.
    func setAutoPiPSuppressed(_ suppressed: Bool) {
        isSuppressed = suppressed
        activeController?.setSuppressed(suppressed)
    }

    func abandonActivePiP(thenPresentFrom present: @escaping (UIViewController?) -> Void) {
        activeController?.stopWithoutRestore()
        guard let base = activeLivestreamHost?.presentingViewController else {
            activeLivestreamHost = nil
            present(UIApplication.topViewController())
            return
        }
        activeLivestreamHost = nil
        base.dismiss(animated: false) {
            present(base)
        }
    }

    func restoreActivePiP() {
        activeController?.restore()
    }

    /// The livestream page became visible again while its own floating window is still
    /// up — the viewer popped or dismissed whatever they had navigated to, rather than
    /// tapping expand. Collapse the window back into the page, so they are never left
    /// with a window floating over the page it mirrors.
    ///
    /// Identity-checked against the registered livestream host so this fires for that
    /// page only, not for every hosted page that happens to appear.
    func restoreActivePiPIfReturningToLivestream(_ controller: UIViewController) {
        guard isActive, controller === activeLivestreamHost else { return }
        restoreActivePiP()
    }

    func startPiPIfNeeded() {
        guard !isSuppressed else { return }
        activeController?.start()
    }

    /// True while PiP must not start at all (e.g. the co-host invitation sheet
    /// is visible). Gates both the explicit navigate-away start and — via the
    /// controller's auto flag — the OS auto-start on backgrounding.
    private(set) var isSuppressed = false

    var hasActiveController: Bool {
        activeController != nil
    }

    // NOTE (design decision): a PiP window started by an in-app action (product
    // tag / navigate-away) PERSISTS across backgrounding, matching standard iOS
    // behavior (Twitch, YouTube do the same). The OS "Start PiP Automatically"
    // setting governs automatic starts only — it is unreadable by apps, and a
    // torn-down window can never be re-granted on a Home flick (iOS evaluates
    // auto-PiP candidates at gesture start; verified on device). See PDT-4392.
    private init() {}
}

final class AmityPipController: NSObject {

    private var pipController: AVPictureInPictureController?

    /// Called when the user taps "restore" on the PiP window.
    var onRestoreUI: (() -> Void)?

    /// Called when the PiP window is closed with the OS close (✕) button — PiP
    /// stopped WITHOUT a restore. Lets the viewer stop playback so audio doesn't
    /// keep playing in the background (PDT-4390 Scenario: close the window).
    var onStopUI: (() -> Void)?

    /// True between a restore request and the matching `didStop`, so `didStop`
    /// can distinguish an expand (restore) from a close (✕).
    private var isRestoringFromPiP = false

    private var isProgrammaticRestore = false

    private var isAbandoning = false

    /// PiP silently never starts without the Background Modes
    /// capability, so warn at every PiP setup attempt, naming the exact step,
    /// instead of failing invisibly.
    private static func warnIfHostAppSetupMissing() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        if !modes.contains("audio") {
            Log.add(event: .warn, "[PiP] Picture-in-Picture is unavailable: the host app is missing the Background Modes capability. Enable Signing & Capabilities → Background Modes → \"Audio, AirPlay, and Picture in Picture\" (adds \"audio\" to UIBackgroundModes in Info.plist). Playback will stop on leave, as before PiP.")
        }
    }

    private var didRegisterBackgroundObserver = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// In-App PIP PAUSED should stop on background same as PIP on background
    @objc private func handleAppDidEnterBackground() {
        guard let pip = pipController, pip.isPictureInPictureActive,
              let player = pip.playerLayer.player,
              player.timeControlStatus == .paused else { return }
        // A session held by the retainer is deliberately frozen on its last frame
        // after its page was deallocated; that window must persist, so skip the
        // paused-on-background teardown.
        if LiveStreamPiPRetainer.shared.isHolding(self) {
            return
        }
        let layer = pip.playerLayer
        pip.delegate = nil
        pipController = nil
        PiPState.shared.setActive(false)
        onStopUI?()
        attach(to: layer)
    }

    /// Attach PiP to a player layer that already has an `AVPlayer` set.
    func attach(to playerLayer: AVPlayerLayer) {
        guard PiPState.shared.isEnabled else { return }
        if !didRegisterBackgroundObserver {
            didRegisterBackgroundObserver = true
            NotificationCenter.default.addObserver(self,
                selector: #selector(handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil)
        }
        Self.warnIfHostAppSetupMissing()
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }

        configureAudioSession()

        if pipController?.playerLayer === playerLayer { return }

        guard let controller = AVPictureInPictureController(playerLayer: playerLayer) else {
            return
        }
        controller.delegate = self
        if #available(iOS 14.2, *) {
            // Respect an active suppression (e.g. co-host invitation sheet up).
            controller.canStartPictureInPictureAutomaticallyFromInline = !PiPState.shared.isSuppressed
        }
        pipController = controller
        PiPState.shared.register(self)
    }

    /// The layer to re-attach to when suppression lifts (see `setSuppressed`).
    private weak var suppressedLayer: AVPlayerLayer?

    /// Hard-suppress PiP while the co-host invitation sheet is visible.
    /// Flipping `canStartPictureInPictureAutomaticallyFromInline` to false is
    /// NOT honored by iOS once the controller is armed (device-verified) — the
    /// only reliable suppress is having no controller at all. Tears it down
    /// (killing any floating window) and re-attaches to the same layer when the
    /// sheet dismisses.
    func setSuppressed(_ suppressed: Bool) {
        if suppressed {
            guard let pip = pipController else { return }
            suppressedLayer = pip.playerLayer
            let wasActive = pip.isPictureInPictureActive
            pip.delegate = nil
            pipController = nil
            if wasActive {
                PiPState.shared.setActive(false)
                onStopUI?()   // window died silently — stop playback audio too
            }
        } else {
            if pipController == nil, let layer = suppressedLayer {
                attach(to: layer)
            }
            suppressedLayer = nil
        }
    }

    func stop() {
        pipController?.stopPictureInPicture()
    }

    func stopWithoutRestore() {
        guard let pipController else { return }
        isAbandoning = true
        pipController.stopPictureInPicture()
    }

    func start() {
        guard let pipController else { return }
        guard pipController.isPictureInPicturePossible else {
            return
        }
        guard !pipController.isPictureInPictureActive else { return }
        pipController.startPictureInPicture()
    }

    func restore() {
        guard let pipController else { return }
        isRestoringFromPiP = true
        isProgrammaticRestore = true
        onRestoreUI?()
        pipController.stopPictureInPicture()
    }

    func detach() {
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        }
        pipController?.stopPictureInPicture()
        pipController?.delegate = nil
        pipController = nil
        PiPState.shared.register(nil)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }
}

extension AmityPipController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        PiPState.shared.setActive(true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        PiPState.shared.setActive(false)
        if isAbandoning {
            isAbandoning = false
            onStopUI?()
        } else if isRestoringFromPiP {
            isRestoringFromPiP = false
        } else {
            onStopUI?()
        }
        isProgrammaticRestore = false
        LiveStreamPiPRetainer.shared.releaseIfHolding(self)
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        PiPState.shared.setActive(false)
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if isAbandoning {
            completionHandler(false)
            return
        }
        isRestoringFromPiP = true
        if !isProgrammaticRestore {
            onRestoreUI?()
        }
        completionHandler(true)
    }
}

/// Keeps a live-stream PiP session alive across the SwiftUI page being deallocated.
///
/// The livestream player (AVPlayer + AVPlayerLayer + AmityPipController) is owned by a
/// SwiftUI `LiveStreamPlayerView.Coordinator`. If that page is deallocated while PiP is
/// active — a global ban rewinds the navigation stack to Social Home — the player layer
/// the floating window renders from would be torn down with it, closing the window. So
/// `Coordinator.deinit` hands ownership here instead of detaching.
///
/// A handoff only happens because the page died under us, which is itself the terminal
/// event, so playback stops immediately: the window holds its last frame until the
/// viewer expands or closes it.
final class LiveStreamPiPRetainer {

    static let shared = LiveStreamPiPRetainer()
    private init() {}

    private var pipController: AmityPipController?
    private var player: AVPlayer?
    // Strong ref keeps the AVPlayerLayer (owned by this view) alive for PiP.
    private var playerView: UIView?

    /// Take ownership of an active PiP session whose owning view is going away, and
    /// freeze playback on the last frame.
    func retain(pipController: AmityPipController, player: AVPlayer, playerView: UIView) {
        // Drop any previous session first.
        releaseNow()
        // The closures captured the now-dead SwiftUI view; clear them so a stale
        // restore/stop callback can't run against a torn-down view.
        pipController.onRestoreUI = nil
        pipController.onStopUI = nil
        self.pipController = pipController
        self.player = player
        self.playerView = playerView
        player.pause()
    }

    /// True when this controller's session is currently owned by the retainer (its page
    /// has been deallocated and the window is being kept alive here).
    func isHolding(_ controller: AmityPipController) -> Bool {
        pipController === controller
    }

    /// Release an orphaned session when fresh in-page playback starts, so a retained
    /// window can't keep playing (or keep audio going) alongside the new player.
    func releaseForNewPlayback() {
        guard pipController != nil else { return }
        releaseNow()
    }

    /// Release the retained session once PiP has stopped (called from the controller's
    /// didStop). No-op if this isn't the controller we're holding.
    func releaseIfHolding(_ controller: AmityPipController) {
        guard pipController === controller else { return }
        releaseNow()
    }

    private func releaseNow() {
        player?.pause()
        pipController?.detach()
        pipController = nil
        player = nil
        playerView = nil
    }
}
