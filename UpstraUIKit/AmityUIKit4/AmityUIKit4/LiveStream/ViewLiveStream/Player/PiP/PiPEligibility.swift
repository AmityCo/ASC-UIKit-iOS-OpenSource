//
//  PiPEligibility.swift
//  AmityUIKit4
//
//  the single eligibility gate every Picture-in-Picture
//  entry path consults. If any condition fails, playback stops exactly as it
//  did before PiP — no floating window, no error, no user-visible difference.
//

import Foundation
import AVFoundation
import AVKit
import AmitySDK

enum PiPIneligibilityReason: String {
    case unsupportedOS       = "unsupported_os"
    case hostAppSetupMissing = "host_app_setup_missing"
    case broadcaster         = "broadcaster"
    case outOfScopeContent   = "out_of_scope_content"
    case noPlayableMedia     = "no_playable_media"
    case deliberateExit      = "deliberate_exit"
}

struct PiPEligibility {

    struct Context {
        /// Page state is `.viewer` — not host, co-host, or backstage.
        let isViewer: Bool
        /// Current room status, if known.
        let roomStatus: AmityRoomStatus?
        /// A non-empty playback URL exists for the current status.
        let hasPlayableURL: Bool
        /// The surface is the room-based livestream player (not a video post/clip).
        let isLivestreamSurface: Bool
        /// The viewer is deliberately leaving (close / back / leave-room).
        let isDeliberateExit: Bool
    }

    /// Returns the blocking reason, or `nil` when PiP is allowed.
    static func ineligibleReason(_ context: Context) -> PiPIneligibilityReason? {
        // Covers OS version + device capability in one check.
        if !AVPictureInPictureController.isPictureInPictureSupported() { return .unsupportedOS }
        if !isBackgroundModesAudioEnabled { return .hostAppSetupMissing }
        if !context.isViewer { return .broadcaster }
        if !context.isLivestreamSurface { return .outOfScopeContent }
        guard let status = context.roomStatus, status == .live || status == .recorded else {
            return .noPlayableMedia
        }
        if !context.hasPlayableURL { return .noPlayableMedia }
        if context.isDeliberateExit { return .deliberateExit }
        return nil
    }

    static func isAllowed(_ context: Context) -> Bool {
        if let reason = ineligibleReason(context) {
            return false
        }
        return true
    }

    static var isBackgroundModesAudioEnabled: Bool {
        guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return modes.contains("audio")
    }
}
