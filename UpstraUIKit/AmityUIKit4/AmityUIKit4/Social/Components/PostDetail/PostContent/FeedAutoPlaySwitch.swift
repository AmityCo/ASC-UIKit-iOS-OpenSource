//
//  FeedAutoPlaySwitch.swift
//  AmityUIKit4
//

import AmitySDK
import Combine
import Foundation

/// The network's feed auto-play switch: the `post` feed's `autoPlay` on the video content setting.
///
/// It is read the way the SDK reads the other network settings: each time the SDK session is established,
/// which means at login, at a cold start and after a reconnect, not on every return to the foreground. A
/// session starts at login (or when the client is set up already logged in) and ends at logout. Until the
/// first read returns, and whenever a read fails or the field is missing, the switch is off and feeds keep
/// the thumbnail and play icon.
@MainActor
final class FeedAutoPlaySwitch: ObservableObject {

    static let shared = FeedAutoPlaySwitch()

    @Published private(set) var isOn = false

    /// Changes when a session starts or ends, so what was kept for the old session (positions, the sound
    /// state) is dropped. A read again inside the same session keeps it.
    @Published private(set) var sessionGeneration = 0

    /// The user whose session the current value belongs to; `nil` when no session has started.
    private var sessionUserId: String?
    private var readTask: Task<Void, Never>?
    private var sessionStateCancellable: AnyCancellable?

    private init() {}

    /// Starts a new session for the logged-in user and reads the switch again.
    func startSession() {
        let userId = AmityUIKitManagerInternal.shared.currentUserId
        guard !userId.isEmpty else {
            endSession()
            return
        }
        sessionUserId = userId
        sessionGeneration += 1
        isOn = false
        observeSessionState()
        read(for: userId)
    }

    /// Starts a session only when none is running for the logged-in user, for hosts that appear before login completes.
    func startSessionIfNeeded() {
        let userId = AmityUIKitManagerInternal.shared.currentUserId
        guard !userId.isEmpty, userId != sessionUserId else { return }
        startSession()
    }

    /// Ends the session at logout; auto-play stays off until the next login.
    func endSession() {
        readTask?.cancel()
        readTask = nil
        sessionStateCancellable = nil
        sessionUserId = nil
        sessionGeneration += 1
        isOn = false
    }

    /// Reads the switch again each time the SDK session is established, as for the other network settings.
    /// The client can be replaced when the UIKit is set up again, so the current one is observed per session.
    private func observeSessionState() {
        sessionStateCancellable = AmityUIKitManagerInternal.shared.client.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, case .established = state else { return }
                self.refresh()
            }
    }

    /// A read inside the running session: the current value stays until the new one returns.
    private func refresh() {
        let userId = AmityUIKitManagerInternal.shared.currentUserId
        // The SDK can report `.established` twice for one login, and a login is read by `startSession()`.
        guard let sessionUserId, sessionUserId == userId, readTask == nil else { return }
        read(for: userId)
    }

    private func read(for userId: String) {
        readTask?.cancel()
        readTask = Task { [weak self] in
            let autoPlay: Bool
            do {
                let settings = try await AmityUIKitManagerInternal.shared.client.getContentSettings()
                autoPlay = settings.post?.videoSettings?.autoPlay ?? false
            } catch {
                Log.warn("Feed auto-play switch read failed, auto-play stays off: \(error)")
                autoPlay = false
            }
            guard let self, !Task.isCancelled, self.sessionUserId == userId else { return }
            self.isOn = autoPlay
            self.readTask = nil
        }
    }
}
