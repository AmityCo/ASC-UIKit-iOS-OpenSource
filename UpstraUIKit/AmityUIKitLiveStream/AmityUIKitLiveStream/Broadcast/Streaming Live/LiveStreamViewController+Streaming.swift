//
//  LiveStreamViewController+Streaming.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 2/9/2564 BE.
//

import UIKit

extension LiveStreamBroadcastViewController {
    
    func startLiveDurationTimer() {
        updateStreamingStatusText()
        liveDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            #if DEBUG
            dispatchPrecondition(condition: .onQueue(.main))
            #endif
            self?.updateStreamingStatusText()
        }
    }
    
    func stopLiveDurationTimer() {
        liveDurationTimer?.invalidate()
        liveDurationTimer = nil
    }
    
    func updateStreamingStatusText() {
        guard let broadcaster = broadcaster else {
            streamingStatusLabel.text = "LIVE"
            return
        }
        var streamingStatus = ""
        switch broadcaster.state {
        case .connected:
            if !isStartStreaming {
                startedAt = Date()
                isStartStreaming = true
            }
            streamingStatus = "LIVE"
        case .connecting, .disconnected, .idle:
            streamingStatus = "CONNECTING"
        @unknown default:
            streamingStatus = "LIVE"
        }
        
        guard let startedAt = startedAt,
              let durationText = liveDurationFormatter.string(from: startedAt, to: Date()) else {
            streamingStatusLabel.text = streamingStatus
            return
        }
        
        /// Display finish button after streaming for 2 or more seconds, to prevent no streaming data being sent to server side.
        if finishButton.isHidden, Date().timeIntervalSince(startedAt) > 2 {
            finishButton.isHidden = false
        }
        streamingStatusLabel.text = "\(streamingStatus) \(durationText)"
    }
    
}
