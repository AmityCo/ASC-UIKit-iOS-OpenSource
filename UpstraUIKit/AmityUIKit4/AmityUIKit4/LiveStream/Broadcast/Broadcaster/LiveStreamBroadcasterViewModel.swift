//
//  LiveStreamBroadcasterViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/21/25.
//

import Foundation
import AmityLiveKit
import AVFoundation

enum LiveStreamBroadcasterState: Int, Equatable {
    case disconnected
    case disconnecting
    case connecting
    case connected
    case reconnecting
    case idle
    
    var strValue: String {
        switch self {
        case .disconnected:
            "Disconnected"
        case .disconnecting:
            "Disconnecting"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .reconnecting:
            "Reconnecting"
        case .idle:
            "idle"
        @unknown default:
            "none"
        }
    }
}

public enum LiveStreamParticipantRole {
    case host
    case coHost
    case viewer
}

enum LiveStreamBroadcasterCameraRatio {
    case full
    case half
    
    func getDimensions() -> Dimensions {
        switch self {
        case .full: return Dimensions(width: 1280, height: 720)
        case .half: return Dimensions(width: 1000, height: 1080)
        }
    }
}

class LiveStreamBroadcasterViewModel: ObservableObject {
    
    var cameraPreviewTrack: LocalVideoTrack = LocalVideoTrack.createCameraTrack()
    
    // Camera postion for live stream preview and live kit broadcaster
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    
    // Microphone enable/disable for live kit broadcaster
    @Published var enableMicrophone: Bool = true
    
    // Room object for live kit broadcaster
    let room: Room

    // Connection state of the live kit broadcaster
    @Published var broadcasterState: LiveStreamBroadcasterState = .idle
    
    // Camera enable/disable for live stream broadcaster
    // If disabled, it will be the audio only live stream
    private var enabledCamera: Bool = true
    
    @Published var forceRefreshID = UUID()
    
    // Current broadcaster camera capture ratio
    private var currentCaptureRatio: LiveStreamBroadcasterCameraRatio = .full
    
    var role: LiveStreamParticipantRole
    private var url: String = ""
    private var token: String = ""
    
    init(role: LiveStreamParticipantRole = .host) {
        self.role = role
        self.room = Room(connectOptions: ConnectOptions(reconnectAttempts: 10),
                        roomOptions: RoomOptions())
        self.room.add(delegate: self)
    }
    
    // Toggle camera position between front and back
    func switchCamera() {
        cameraPosition = cameraPosition == AVCaptureDevice.Position.front ? AVCaptureDevice.Position.back : AVCaptureDevice.Position.front
        
        Task {
            await switchCameraPosition(to: cameraPosition)
        }
    }
    
    private func switchCameraPosition(to position: AVCaptureDevice.Position) async {
        guard let cameraTrack = room.localParticipant.firstCameraVideoTrack as? LocalVideoTrack else { return }
        guard let capture = cameraTrack.capturer as? CameraCapturer else { return }
        
        do {
            try await capture.set(cameraPosition: position)
        } catch {
            print("Error switching camera position: \(error.localizedDescription)")
        }
    }
    
    // Toggle microphone enable/disable
    func toggleMicrophone() {
        enableMicrophone.toggle()
        Task {
            try await room.localParticipant.setMicrophone(enabled: enableMicrophone)
        }
    }
    
    // Toggle camera enable/disable
    private func toggleCamera() {
        Task {
            try await room.localParticipant.setCamera(enabled: !enabledCamera)
        }
    }
    
    // Start broadcasting the live stream
    func startBroadcast(url: String, token: String, captureRatio: LiveStreamBroadcasterCameraRatio) {
        currentCaptureRatio = captureRatio
        
        Task {
            let captureOptions = CameraCaptureOptions(position: cameraPosition, dimensions: captureRatio.getDimensions())
            try await room.connect(url: url, token: token, roomOptions: RoomOptions(defaultCameraCaptureOptions: captureOptions))
            if enabledCamera { try await room.localParticipant.setCamera(enabled: true, captureOptions: captureOptions) }
            if enableMicrophone { try await room.localParticipant.setMicrophone(enabled: true) }
        }
    }
    
    func switchCapturerRatio(to ratio: LiveStreamBroadcasterCameraRatio) {
        guard currentCaptureRatio != ratio else { return }
        guard let cameraTrack = room.localParticipant.firstCameraVideoTrack as? LocalVideoTrack else { return }
        guard let capture = cameraTrack.capturer as? CameraCapturer else { return }
        
        currentCaptureRatio = ratio
        Log.add(event: .info, "Switching capturer ratio to: \(ratio)")
        
        Task { @MainActor in
            do {
                try await capture.set(options: CameraCaptureOptions(position: cameraPosition, dimensions: ratio.getDimensions()))
                self.forceRefreshID = UUID()
            } catch {
                print("Error switching camera position: \(error.localizedDescription)")
            }
        }
    }
    
    // Stop broadcasting the live stream
    func stopBroadcast() {
        Task {
            await room.disconnect()
        }
    }
}

// MARK: - RoomDelegate
extension LiveStreamBroadcasterViewModel: RoomDelegate {
    func room(_ room: AmityLiveKit.Room, didUpdateConnectionState connectionState: AmityLiveKit.ConnectionState, from oldConnectionState: AmityLiveKit.ConnectionState) {
        let newState = connectionState.toBroadcasterState()
        
        // Only update if the state actually changed to prevent unnecessary UI updates
        if newState != broadcasterState {
            DispatchQueue.main.async {
                self.broadcasterState = newState
            }
        }
    }
    
    func room(_ room: AmityLiveKit.Room, didStartReconnectWithMode reconnectMode: AmityLiveKit.ReconnectMode) {
        if broadcasterState != .reconnecting {
            DispatchQueue.main.async {
                self.broadcasterState = .reconnecting
            }
        }
    }
    
    func room(_ room: AmityLiveKit.Room, didCompleteReconnectWithMode reconnectMode: AmityLiveKit.ReconnectMode) {
        let newState = room.connectionState.toBroadcasterState()
        if newState != broadcasterState {
            DispatchQueue.main.async {
                self.broadcasterState = newState
            }
        }
    }
    
    func room(_ room: AmityLiveKit.Room, didDisconnectWithError error: AmityLiveKit.LiveKitError?) {
        Log.add(event: .info, "Room disconnected with error: \(String(describing: error))")
    }
}

extension AmityLiveKit.ConnectionState {
    func toBroadcasterState() -> LiveStreamBroadcasterState {
        switch self {
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .reconnecting:
            return .reconnecting
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnecting
        @unknown default:
            return .idle
        }
    }
}
