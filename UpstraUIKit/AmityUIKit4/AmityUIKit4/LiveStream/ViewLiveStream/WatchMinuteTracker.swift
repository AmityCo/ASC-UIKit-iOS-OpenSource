//
//  WatchMinuteTracker.swift
//  AmityUIKit4
//
//  Created by Copilot on 12/29/24.
//

import Foundation
import AmitySDK

/// Helper class to manage watch minute tracking for livestream rooms
class WatchMinuteTracker {
    
    // MARK: - Properties

    private var sessionId: String?
    private var sessionStartTime: Date?
    private var updateTimer: Timer?
    private weak var room: AmityRoom?

    // Track accumulated watch time when pausing/resuming
    private var accumulatedDuration: TimeInterval = 0
    private var lastResumeTime: Date?
    private var isTrackingPaused: Bool = false
    
    // MARK: - Lifecycle
    
    deinit {
        stopTracking()
    }
    
    // MARK: - Public Methods
    
    /// Start tracking watch minutes for a room
    /// - Parameter room: The room to track
    /// - Important: Call this on the same thread where the room object was created (typically main thread)
    func startTracking(for room: AmityRoom) {
        // Extract data from the Realm object before crossing async boundaries
        let roomStatus = room.status
        let roomId = room.roomId
        let analytics = room.analytics()
        
        guard roomStatus == .live || roomStatus == .recorded else {
            Log.add(event: .info, "WatchMinuteTracker: Room is not in watchable state (status: \(roomStatus))")
            return
        }
        
        self.room = room
        
        Task { [weak self] in
            do {
                let sessionId = try await analytics.createWatchSession(startedAt: Date())
                
                await MainActor.run {
                    self?.sessionId = sessionId
                    self?.sessionStartTime = Date()
                    self?.lastResumeTime = Date()
                    self?.accumulatedDuration = 0
                    self?.isTrackingPaused = false
                    self?.startUpdateTimer()
                }
                
                Log.add(event: .info, "WatchMinuteTracker: Started tracking session \(sessionId) for room \(roomId)")
            } catch {
                Log.add(event: .error, "WatchMinuteTracker: Failed to create watch session: \(error.localizedDescription)")
            }
        }
    }
    
    /// Stop tracking and perform final update
    func stopTracking() {
        guard let sessionId = sessionId,
              let sessionStartTime = sessionStartTime,
              let room = room else {
            return
        }

        let finalDuration = calculateCurrentDuration()
        let analytics = room.analytics()

        if Thread.isMainThread {
            updateTimer?.invalidate()
            updateTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateTimer?.invalidate()
                self?.updateTimer = nil
            }
        }

        self.sessionId = nil
        self.sessionStartTime = nil
        self.room = nil
        self.accumulatedDuration = 0
        self.lastResumeTime = nil
        self.isTrackingPaused = false

        Task {
            do {
                try await analytics.updateWatchSession(
                    sessionId: sessionId,
                    duration: finalDuration,
                    endedAt: Date()
                )

                Log.add(event: .info, "WatchMinuteTracker: Final update for session \(sessionId) with duration \(finalDuration)s")
                analytics.syncPendingWatchSessions()
            } catch {
                Log.add(event: .error, "WatchMinuteTracker: Failed to update watch session: \(error.localizedDescription)")
            }
        }
    }

    /// Pause tracking (e.g., when video is paused or seeking)
    func pauseTracking() {
        guard !isTrackingPaused else { return }

        if let lastResumeTime = lastResumeTime {
            accumulatedDuration += Date().timeIntervalSince(lastResumeTime)
        }

        isTrackingPaused = true
        lastResumeTime = nil

        if Thread.isMainThread {
            updateTimer?.invalidate()
            updateTimer = nil
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateTimer?.invalidate()
                self?.updateTimer = nil
            }
        }

        Log.add(event: .info, "WatchMinuteTracker: Paused tracking (accumulated: \(Int(accumulatedDuration))s)")
    }

    /// Resume tracking (e.g., when video resumes playing)
    func resumeTracking() {
        guard isTrackingPaused else { return }

        isTrackingPaused = false
        lastResumeTime = Date()
        startUpdateTimer()

        Log.add(event: .info, "WatchMinuteTracker: Resumed tracking")
    }
    
    // MARK: - Private Methods
    
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateWatchSession()
            }
        }
    }
    
    private func updateWatchSession() {
        guard let sessionId = sessionId,
              let sessionStartTime = sessionStartTime,
              let room = room else {
            return
        }

        let duration = calculateCurrentDuration()
        let analytics = room.analytics()

        Task {
            do {
                try await analytics.updateWatchSession(
                    sessionId: sessionId,
                    duration: duration,
                    endedAt: Date()
                )
            } catch {
                Log.add(event: .error, "WatchMinuteTracker: Failed to update watch session: \(error.localizedDescription)")
            }
        }
    }

    private func calculateCurrentDuration() -> Int {
        var totalDuration = accumulatedDuration

        if !isTrackingPaused, let lastResumeTime = lastResumeTime {
            totalDuration += Date().timeIntervalSince(lastResumeTime)
        }

        return Int(totalDuration)
    }
}
