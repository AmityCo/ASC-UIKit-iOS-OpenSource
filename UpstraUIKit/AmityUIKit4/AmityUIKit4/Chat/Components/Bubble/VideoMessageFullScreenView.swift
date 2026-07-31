//
//  VideoMessageFullScreenView.swift
//  AmityUIKit4
//

import SwiftUI

struct VideoMessageFullScreenView: View {

    @ObservedObject var viewConfig: AmityViewConfigController
    let videoURL: URL
    var downloadURL: URL? = nil
    let onClose: () -> Void
    /// When non-nil, a delete (trash) control is shown. Left unset for messages
    /// the current user cannot delete (e.g. received messages).
    var onDelete: (() -> Void)? = nil

    /// Save-to-device is temporarily disabled: transcoded videos are served as an
    /// HLS stream the Photos library can't reliably save. `saveVideo` stays wired
    /// — set this to `true` to re-enable the download control.
    private let isSaveVideoEnabled = false

    var body: some View {
        AmityPostMediaVideoPlayer(
            post: nil,
            playerType: .chat(url: videoURL),
            hideActionMenu: true,
            onClose: onClose,
            onDownload: (isSaveVideoEnabled && downloadURL != nil) ? saveVideo : nil,
            onDelete: onDelete
        )
        .environmentObject(viewConfig)
        .ignoresSafeArea()
    }

    private func saveVideo() {
        guard let downloadURL else { return }
        MessageMediaSaver.saveVideo(from: downloadURL) { success in
            let key = success
                ? AmityLocalizedStringSet.Chat.SaveMedia.videoSuccess
                : AmityLocalizedStringSet.Chat.SaveMedia.videoFailed
            Toast.showToast(style: success ? .success : .warning, message: key.localizedString)
        }
    }
}
