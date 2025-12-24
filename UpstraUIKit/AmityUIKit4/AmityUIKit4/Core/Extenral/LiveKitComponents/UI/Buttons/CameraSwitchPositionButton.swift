//
//  CameraSwitchPositionButton.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/21/25.
//

import AmityLiveKit
import SwiftUI
import AVKit

/// The Camera Switch Position Button is a button that toggles the camera position front and back.
public struct CameraSwitchPositionButton<Label: View, PublishedLabel: View>: View {
    private let _label: ComponentBuilder<Label>
    private let _publishedLabel: ComponentBuilder<PublishedLabel>

    @EnvironmentObject private var _room: Room
    @State private var _isBusy = false

    public var cameraPosition: AVCaptureDevice.Position {
        guard let capture = getCameraCapturer() else { return .unspecified }
        return capture.position
    }

    public init(@ViewBuilder label: @escaping ComponentBuilder<Label>,
                @ViewBuilder published: @escaping ComponentBuilder<PublishedLabel>)
    {
        _label = label
        _publishedLabel = published
    }

    public var body: some View {
        Button {
            Task {
                _isBusy = true
                defer { Task { @MainActor in _isBusy = false } }
                try await switchCameraPosition()
            }
        } label: {
            if cameraPosition == .front {
                _label()
            } else {
                _publishedLabel()
            }
        }.disabled(_isBusy)
    }
    
    private func switchCameraPosition() async throws {
        guard let capture = getCameraCapturer() else { return }
        try await capture.switchCameraPosition()
    }
    
    private func getCameraCapturer() -> CameraCapturer? {
        guard let cameraTrack = _room.localParticipant.firstCameraVideoTrack as? LocalVideoTrack else { return nil }
        return cameraTrack.capturer as? CameraCapturer
    }
}
