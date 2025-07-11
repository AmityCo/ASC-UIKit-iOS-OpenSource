//
//  AmityCreateClipPostPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 18/6/25.
//

import Foundation
import SwiftUI
import AVFoundation

class AmityCreateClipPostPageViewModel: ObservableObject {
        
    @Published var videoURL: URL?
    
    @Published var isCapturingVideo = false
    @Published var videoDurationLabel = "00:00"
    @Published var videoCaptureProgress: CGFloat = 0 // 0.0 - 1.0 range
    @Published var videoCaptureDuration: TimeInterval = 0 // seconds
    @Published var cameraFlashMode: CameraFlashMode = .off
    private var videoCaptureTimer: Timer?
    var startedVideoCaptureAt: Date?
    let maxAllowedVideoLength: Double = 15 * 60 // seconds
    let minAllowedVideoLength: Double = 1 // seconds
    
    var cameraManager = CameraManager()
        
    @Published var clipPostAlert = ClipPostAlert()
    
    private var minuteAndSecondFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    init() {
        cameraManager.shouldRespondToOrientationChanges = false
        cameraManager.shouldFlipFrontCameraImage = true
        cameraManager.cameraOutputMode = .videoWithMic
        cameraManager.showAccessPermissionPopupAutomatically = true
        // cameraManager.writeFilesToPhoneLibrary = false
    }
    
    func toggleFlash() {
        cameraManager.flashMode = cameraFlashMode == .off ? .on : .off
        cameraFlashMode = cameraManager.flashMode
    }
    
    func switchCamera() {
        let cameraDevice = cameraManager.cameraDevice
        cameraManager.cameraDevice = cameraDevice == .front ? .back : .front
    }
    
    func startCapture() {
        guard cameraManager.cameraIsReady else { return }

        // Start capturing video
        cameraManager.startRecordingVideo()
        
        // Start timer
        startVideoCaptureTimer()
    }
    
    func stopCapture() {
        cameraManager.stopVideoRecording { [weak self] videoURL, error in
            guard let self else { return }
            
            if let error {
                Log.warn("Error occurred Cannot save video. \(error)")
                return
            }
                        
            if videoCaptureDuration < 1 {
                Log.add(event: .info, "Captured clip is < 1 second")
                DispatchQueue.main.async {
                    self.showAlert(state: .clipTooShort)
                }
                return
            }
            
            if let videoURL {
                DispatchQueue.main.async {
                    self.videoURL = videoURL
                }
                Log.add(event: .info, "Recorded clip url: \(videoURL)")
            } else {
                Log.warn("Cannot get recorded clip url")
            }
        }
                
        stopVideoCaptureTimer()
    }
    
    private func stopVideoCaptureTimer() {
        isCapturingVideo = false

        videoCaptureTimer?.invalidate()
        videoCaptureTimer = nil
        
        startedVideoCaptureAt = Date()
    }
    
    private func startVideoCaptureTimer() {
        isCapturingVideo = true
        videoCaptureDuration = 0
        videoCaptureProgress = 0
        videoDurationLabel = "00:00"

        startedVideoCaptureAt = Date()
        videoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            
            if videoCaptureDuration + 1 >= maxAllowedVideoLength {
                // Stop video capture
                Log.add(event: .warn, "Reached maximum time allowed for clip capture")
                
                // Stop capturing video
                self.stopCapture()
            }
            
            videoCaptureDuration += 1
            updateDurationLabel(duration: videoCaptureDuration)
            
            // Progress
            videoCaptureProgress = min(videoCaptureDuration / maxAllowedVideoLength, 1)
        }
    }
    
    func updateDurationLabel(duration: TimeInterval) {
        guard let startedVideoCaptureAt else {
            return
        }
        
        let dateFormatter: DateComponentsFormatter = minuteAndSecondFormatter
        guard let durationText = dateFormatter.string(from: startedVideoCaptureAt, to: Date()) else {
            return
        }
        
        self.videoDurationLabel = durationText
    }
    
    func processSelectedMedia(url: URL?) {
        guard let url else { return }
        
        let maxFileSize: Int64 = 2147483648
        let fileSize = try? AmityMediaMetadata.getFileSize(from: url)
        
        if let fileSize, fileSize > maxFileSize {
            showAlert(state: .maxFileSize)
            return
        }
                
        if #available(iOS 15, *) {
            // If duration cannot be determined locally, we will handle it
            // through backend validation.
            Task { @MainActor in
                let duration = try await AmityMediaMetadata.getDuration(from: AVAsset(url: url))
                if duration > maxAllowedVideoLength {
                    showAlert(state: .maxClipDuration)
                } else {
                    self.videoURL = url
                }
            }
        } else {
            // For devices running < ios 15, we will handle size validation through
            // backend.
            self.videoURL = url
        }
    }
    
    private func showAlert(state: ClipPostAlert.State) {
        self.clipPostAlert.show(for: state)
        self.objectWillChange.send()
    }
}
