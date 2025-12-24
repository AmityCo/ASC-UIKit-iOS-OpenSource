/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AmityLiveKit
import SwiftUI
import AVKit

public struct LocalCameraPreview: View {
    private let _localVideoTrack: LocalVideoTrack
    @Binding private var _cameraPosition: AVCaptureDevice.Position

    @Environment(\.liveKitUIOptions) var ui: UIOptions

    public init(localVideoTrack: LocalVideoTrack? = nil,
                cameraPosition: Binding<AVCaptureDevice.Position> = .constant(.front)) {
        _localVideoTrack = localVideoTrack ?? LocalVideoTrack.createCameraTrack()
        __cameraPosition = cameraPosition
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
//                ui.videoDisabledView(geometry: geometry)

                SwiftUIVideoView(_localVideoTrack)
                    .onAppear {
                        Task {
                            try await _localVideoTrack.start()
                        }
                    }
                    .onDisappear {
                        Task {
                            try await _localVideoTrack.stop()
                        }
                    }
            }
        }
        .onChange(of: _cameraPosition) { newPosition in
            Task {
                try await switchCameraPosition(to: newPosition)
            }
        }
    }
    
    private func switchCameraPosition(to position: AVCaptureDevice.Position) async throws {
        guard let capture = _localVideoTrack.capturer as? CameraCapturer else { return }
        try await capture.set(cameraPosition: position)
    }
}
