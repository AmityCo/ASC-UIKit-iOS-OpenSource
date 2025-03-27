//
//  LiveStreamPermissionChecker.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 3/3/25.
//

import SwiftUI
import AVKit

enum PermissionState {
    case notDetermined
    case granted
    case denied
}

class LiveStreamPermissionChecker: ObservableObject {
    
    @Published var cameraPermissionState: PermissionState = .notDetermined
    @Published var microphonePermissionState: PermissionState = .notDetermined
    
    init() {
        checkCameraAndMicrophonePermissionStatus()
    }
    
    @MainActor
    func requestCameraAndAudioPermission() async {
        await requestCameraPermission()
        
        await requestAudioPermission()
    }
    
    @MainActor
    func requestCameraPermission() async {
        let cameraPermission = await AVCaptureDevice.requestAccess(for: .video)
        self.cameraPermissionState = cameraPermission ? .granted : .denied
    }
    
    @MainActor
    func requestAudioPermission() async {
        // Microphone Permission
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.microphonePermissionState = granted ? .granted : .denied
                    continuation.resume()
                }
            }
        }
    }
    
    func shouldAskForCameraPermission() -> Bool {
        let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
        return cameraAuth == .notDetermined
    }
    
    func shouldAskForMicrophonePermission() -> Bool {
        return AVAudioSession.sharedInstance().recordPermission == .undetermined
    }
    
    func checkCameraAndMicrophonePermissionStatus() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .notDetermined:
            cameraPermissionState = .notDetermined
        case .restricted, .denied:
            cameraPermissionState = .denied
        case .authorized:
            cameraPermissionState = .granted
        @unknown default:
            cameraPermissionState = .notDetermined
        }
        
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        switch microphoneStatus {
        case .undetermined:
            microphonePermissionState = .notDetermined
        case .denied:
            microphonePermissionState = .denied
        case .granted:
            microphonePermissionState = .granted
        @unknown default:
            microphonePermissionState = .notDetermined
        }
    }
}
