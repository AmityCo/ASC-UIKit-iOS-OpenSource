//
//  LiveStreamTimerService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 12/3/25.
//

import SwiftUI

// All duration are in seconds
struct LiveStreamDurationThreshold {
    
    // Max seconds to wait for reconnection before stream ends
    let streamReconnectionWaitDuration: Int
    
    // Max seconds allowed to stream live
    let streamMaxLiveDuration: Int
    
    // Seconds before `streamMaxLiveDuration` to warn user that stream is about to end.
    // If stream max duration is 60 minutes & streamEndWarningDuration is 180, it means user will be notified 3 minutes before stream ends
    let streamEndWarningDuration: Int
    
    // Seconds to countdown before stream is ended automatically.
    // If stream max duration is 60 minutes & streamEndCountdownDuration is 10, it means countdown will begin 10 seconds before stream ends
    let streamEndCountdownDuration: Int
    
    init(streamReconnectionWaitDuration: Int = 180, streamMaxLiveDuration: Int = 14400, streamEndWarningDuration: Int = 180, streamEndCountdownDuration: Int = 10) {
        self.streamReconnectionWaitDuration = streamReconnectionWaitDuration
        self.streamMaxLiveDuration = streamMaxLiveDuration
        self.streamEndWarningDuration = streamEndWarningDuration
        self.streamEndCountdownDuration = streamEndCountdownDuration
    }
    
    static let mock = LiveStreamDurationThreshold(streamReconnectionWaitDuration: 20, streamMaxLiveDuration: 3600, streamEndWarningDuration: 180, streamEndCountdownDuration: 10)
}

class LiveStreamTimerService {
    
    static let threshold: LiveStreamDurationThreshold = LiveStreamDurationThreshold()
    //static let threshold: LiveStreamDurationThreshold = LiveStreamDurationThreshold.mock

    /// Timer which tracks connection issue
    private var connectionProblemTimer: Timer?
    
    /// We use this date to keep track of connection issue
    private var connectionProblemStartedAt: Date?
    
    /// We start this timer when we begin to publish stream.
    private var liveDurationTimer: Timer?
    
    /// This is set when this page start live publishing live stream.
    /// We use this state to display live stream timer.
    private var liveStartedAt: Date?
    
    private var countdownTimer: Timer?
    
    private var currentCountdown: Int = LiveStreamTimerService.threshold.streamEndCountdownDuration
    
    /// Formatter to render live duration in streamingStatusLabel
    private var hourMinuteAndSecondFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var minuteAndSecondFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    // Live Duration
    
    func startLiveDurationTimer(onUpdate: @escaping (_ duration: String, _ seconds: Int) -> Void) {
        guard liveDurationTimer == nil else { return }
        
        liveStartedAt = Date()
        liveDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
            
            guard let self, let liveStartedAt else { return }
            
            let secondsElapsed = Calendar.current.dateComponents([.second], from: liveStartedAt, to: Date()).second ?? 0
            let dateFormatter: DateComponentsFormatter = secondsElapsed >= 3600 ? hourMinuteAndSecondFormatter : minuteAndSecondFormatter
            
            guard let durationText = dateFormatter.string(from: liveStartedAt, to: Date()) else {
                return
            }
            
            onUpdate(durationText, secondsElapsed)
        })
    }
    
    func stopLiveDurationTimer() {
        liveDurationTimer?.invalidate()
        liveDurationTimer = nil
        liveStartedAt = nil
    }
    
    // Reconnection
    
    func startReconnectionTimer(onUpdate: @escaping (_ seconds: Int) -> Void) {
        guard connectionProblemTimer == nil else { return }
        
        connectionProblemStartedAt = Date()
        connectionProblemTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self]  _ in
            guard let self, let connectionProblemStartedAt else { return }
            
            let secondsElapsed = Calendar.current.dateComponents([.second], from: connectionProblemStartedAt, to: Date()).second ?? 0
            onUpdate(secondsElapsed)
        })
    }
    
    func stopReconnectionTimer() {
        connectionProblemTimer?.invalidate()
        connectionProblemTimer = nil
        connectionProblemStartedAt = nil
    }
    
    // Livestream Termination Countdown
    
    func startLivestreamCountdownTimer(onUpdate: @escaping (_ countdown: Int) -> Void) {
        guard countdownTimer == nil else { return }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self]  _ in
            guard let self else { return }
            
            self.currentCountdown = max(0, self.currentCountdown - 1)
            onUpdate(currentCountdown)
            
            if currentCountdown == 0 { stopLivestreamCountdownTimer() }
        })
    }
    
    func stopLivestreamCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        currentCountdown = LiveStreamTimerService.threshold.streamEndCountdownDuration
    }
    
    func invalidateTimers() {
        stopLiveDurationTimer()
        stopReconnectionTimer()
        stopLivestreamCountdownTimer()
    }
}
