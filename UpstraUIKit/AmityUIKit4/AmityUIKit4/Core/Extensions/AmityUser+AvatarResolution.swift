//
//  AmityUser+AvatarResolution.swift
//  AmityUIKit4
//
//  Adds avatarCustomUrl rendering support.
//  Priority: avatarCustomUrl (operator CDN) → Amity file storage → nil
//
//  Related ticket: SLE-565
//  Customer impact: BNI — all member avatars blank without this fix.
//

import AmitySDK
import Foundation

// Size variants for the Amity-hosted file fallback.
// Has no effect when avatarCustomUrl is set — CDN URLs are returned as-is.
enum AmityAvatarSize {
    case standard  // fileURL
    case medium    // mediumFileURL
    case large     // largeFileURL
}

extension AmityUser {

    /// Returns the best available avatar URL for rendering.
    ///
    /// Priority order:
    ///   1. `avatarCustomUrl` — external URL set by the operator (e.g. BNI's CDN)
    ///   2. Amity-hosted file — uploaded via AmityFileRepository
    ///   3. nil — caller should show a placeholder
    ///
    /// - Note: Community avatars are separate and not affected by this property.
    var resolvedAvatarURL: URL? {
        return resolvedAvatarURL(size: .standard)
    }

    func resolvedAvatarURL(size: AmityAvatarSize = .standard) -> URL? {
        // 1. Operator-supplied external URL — size has no effect on CDN URLs
        if let custom = avatarCustomUrl,
           !custom.trimmingCharacters(in: .whitespaces).isEmpty,
           let url = URL(string: custom) {
            return url
        }
        // 2. Amity-hosted file — use requested size
        let fileURLString: String?
        switch size {
        case .medium:   fileURLString = getAvatarInfo()?.mediumFileURL
        case .large:    fileURLString = getAvatarInfo()?.largeFileURL
        case .standard: fileURLString = getAvatarInfo()?.fileURL
        }
        if let fileURLString,
           !fileURLString.trimmingCharacters(in: .whitespaces).isEmpty,
           let url = URL(string: fileURLString) {
            return url
        }
        // 3. No avatar set
        return nil
    }
}
