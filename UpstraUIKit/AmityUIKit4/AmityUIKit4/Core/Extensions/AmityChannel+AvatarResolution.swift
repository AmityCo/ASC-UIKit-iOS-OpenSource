//
//  AmityChannel+AvatarResolution.swift
//  AmityUIKit4
//
//  Related ticket: PDT-5070
//

import AmitySDK
import Foundation

extension AmityChannel {

    /// Avatar URL for this channel, or `nil` when the channel has no avatar.
    ///
    /// `avatarFileId` is the authority rather than `getAvatarInfo()`. `getAvatarInfo()` returns the
    /// SDK's cached `avatar` relationship, which is not cleared when an avatar is removed, so it
    /// keeps serving the previous file until the channel is refetched — the whole of PDT-5070. The
    /// id is written on every channel update, so an empty or absent one means "no avatar" today.
    func resolvedChannelAvatarURL(size: AmityAvatarSize = .standard) -> URL? {
        guard let avatarFileId,
              !avatarFileId.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        let fileURLString: String?
        switch size {
        case .medium:   fileURLString = getAvatarInfo()?.mediumFileURL
        case .large:    fileURLString = getAvatarInfo()?.largeFileURL
        case .standard: fileURLString = getAvatarInfo()?.fileURL
        }

        guard let fileURLString,
              !fileURLString.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return URL(string: fileURLString)
    }
}
