//
//  FeedAutoPlayStore.swift
//  AmityUIKit4
//

import SwiftUI
import Combine
import AVFoundation
import AmitySDK

/// Decides which feed video plays, and remembers where each video stopped.
///
/// Every video frame on screen in a feed that hosts auto-play reports where it is. One video plays at a time:
/// the most visible one at 50% or more, on a tie the higher one. It starts as soon as it is the pick, with no
/// wait, and a frame a fast scroll carries past stops loading as soon as it drops below 50%.
/// The playing video keeps the player until it drops below 50%. A frame that is not reported (off screen,
/// a carousel page swiped away, a feed hidden behind a pushed page) cannot play.
///
/// Nothing plays while the network switch (`FeedAutoPlaySwitch`) is off, or while the member's setting
/// (`FeedAutoPlaySetting`) does not allow the current connection. When either turns auto-play off, the playing
/// video stops at once, its position kept; when auto-play applies again, the most visible video starts. Positions are keyed by video URL
/// and live for the session only, and so do the videos that failed to play, which stop being candidates.
@MainActor
final class FeedAutoPlayStore: ObservableObject {

    static let shared = FeedAutoPlayStore()

    /// The frame that plays, as reported by `report(key:frame:)`.
    @Published private(set) var activeKey: String?

    /// True while the network switch and the member's setting both allow auto-play. Then a video that is not
    /// playing shows no play icon, so the icon does not flash on and off as the pick moves.
    @Published private(set) var isAutoPlayOn = false

    /// The session sound state: every feed video starts muted until the member unmutes one, and then plays
    /// with sound until they mute again. A new session starts muted.
    @Published private(set) var isMuted: Bool = true

    /// True while something covers the feed (the full player, a sheet or menu) or the app is in the
    /// background, so the frame underneath stops. It resumes from the same point once nothing covers it.
    @Published private(set) var isSuspended: Bool = false

    /// Bumped when the playing video should play on after the system paused it: headphones or a Bluetooth
    /// device went away, or the audio was given back while it played muted.
    @Published private(set) var resumeRequest = 0

    private struct Visibility {
        let share: CGFloat
        let top: CGFloat
    }

    private static let threshold: CGFloat = 0.5

    private var visibilities: [String: Visibility] = [:]
    private var positions: [String: Double] = [:]
    private var endedVideos: Set<String> = []
    /// The videos each post shows, so a post deleted on this device can drop their positions.
    private var videosByPost: [String: Set<String>] = [:]
    /// Videos that failed to load or play this session; their frames show the thumbnail and play icon.
    @Published private(set) var failedVideos: Set<String> = []
    /// The frame each video stopped on when it was scrolled away, shown in place of the post's thumbnail while
    /// auto-play is on, until it plays again. A stream it cannot be read from keeps the thumbnail.
    @Published private(set) var keptFrames: [String: UIImage] = [:]
    /// The recording each recorded live room has reached, by room ID, for a room with several recordings.
    @Published private(set) var recordingIndexes: [String: Int] = [:]
    private var isSwitchOn = false
    private var isSettingAllowed = true
    private var switchCancellables: Set<AnyCancellable> = []
    /// Each cover reports under its own reason, so one closing does not uncover the feed while another is open.
    private var suspendReasons: Set<String> = []
    private var appStateCancellables: Set<AnyCancellable> = []
    private static let backgroundReason = "background"
    /// True while the app holds the audio for a video with sound, so other apps' audio is paused.
    private var holdsAudio = false
    /// True while the playing video is a clip saved as muted: it has no sound, so the app does not hold the audio.
    private var isPlayingForceMuted = false

    private init() {
        FeedAutoPlaySwitch.shared.$isOn
            .removeDuplicates()
            .sink { [weak self] isOn in
                guard let self else { return }
                self.isSwitchOn = isOn
                self.recompute()
            }
            .store(in: &switchCancellables)

        FeedAutoPlaySetting.shared.allowsAutoPlayPublisher
            .sink { [weak self] allowed in
                guard let self else { return }
                self.isSettingAllowed = allowed
                self.recompute()
            }
            .store(in: &switchCancellables)

        // A new session keeps no positions and starts muted; a read again inside the session keeps both.
        FeedAutoPlaySwitch.shared.$sessionGeneration
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.positions.removeAll()
                self.endedVideos.removeAll()
                self.failedVideos.removeAll()
                self.keptFrames.removeAll()
                self.recordingIndexes.removeAll()
                self.isMuted = true
            }
            .store(in: &switchCancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.setSuspended(true, reason: Self.backgroundReason) }
            .store(in: &appStateCancellables)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.setSuspended(false, reason: Self.backgroundReason) }
            .store(in: &appStateCancellables)

        // A post deleted on this device drops its videos' positions, ended and failed states.
        NotificationCenter.default.publisher(for: .didPostDeleted)
            .compactMap { $0.userInfo?["postId"] as? String }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] postId in self?.forgetVideos(ofPost: postId) }
            .store(in: &appStateCancellables)

        // Phone calls and other audio interruptions are out of scope: the player keeps the system behaviour.

        // Headphones or a Bluetooth device going away pauses the player; the video plays on, with sound
        // through the speaker if it had sound.
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .compactMap { ($0.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt).flatMap(AVAudioSession.RouteChangeReason.init(rawValue:)) }
            .filter { $0 == .oldDeviceUnavailable }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.resumeRequest += 1 }
            .store(in: &appStateCancellables)
    }

    // MARK: - Visibility

    /// `frame` is in global coordinates. The share is the larger of the visible part of the frame and the
    /// visible part of the screen it fills, so a video taller than the screen counts once it fills half of
    /// it. The horizontal share counts too, so a carousel page swiped out of view drops out.
    func report(key: String, frame: CGRect, viewportTop: CGFloat = 0) {
        visibilities[key] = Visibility(share: Self.visibleShare(of: frame, viewportTop: viewportTop), top: frame.minY)
        recompute()
    }

    func remove(key: String) {
        visibilities[key] = nil
        recompute()
    }

    func setSuspended(_ suspended: Bool, reason: String) {
        if suspended {
            suspendReasons.insert(reason)
        } else {
            suspendReasons.remove(reason)
        }
        let isCovered = !suspendReasons.isEmpty
        guard isSuspended != isCovered else { return }
        isSuspended = isCovered
        recompute()
    }

    /// `viewportTop` is where the feed's visible area starts on screen: the part of a frame above it (scrolled
    /// under a navigation bar or a sticky header) is not visible.
    private static func visibleShare(of frame: CGRect, viewportTop: CGFloat) -> CGFloat {
        let bounds = UIScreen.main.bounds
        let top = min(max(viewportTop, 0), bounds.maxY)
        let screen = CGRect(x: bounds.minX, y: top, width: bounds.width, height: bounds.maxY - top)
        let visible = frame.intersection(screen)
        guard !visible.isNull, frame.width > 0, frame.height > 0 else { return 0 }
        let vertical = min(1, max(visible.height / frame.height, visible.height / screen.height))
        let horizontal = visible.width / frame.width
        return vertical * horizontal
    }

    private func recompute() {
        defer { updateAudioFocus() }
        let on = isSwitchOn && isSettingAllowed
        if isAutoPlayOn != on { isAutoPlayOn = on }
        guard isSwitchOn, isSettingAllowed, !isSuspended else {
            if activeKey != nil { activeKey = nil }
            return
        }

        // The playing video keeps going until it drops below the threshold.
        if let activeKey, (visibilities[activeKey]?.share ?? 0) >= Self.threshold {
            return
        }

        // Below the threshold it stops at once, and the new pick, if any, starts at once.
        let candidate = bestCandidate()
        if activeKey != candidate { activeKey = candidate }
    }

    private func bestCandidate() -> String? {
        visibilities
            .filter { $0.value.share >= Self.threshold }
            .sorted { lhs, rhs in
                if abs(lhs.value.share - rhs.value.share) > 0.01 { return lhs.value.share > rhs.value.share }
                return lhs.value.top < rhs.value.top
            }
            .first?.key
    }

    // MARK: - Sound

    func setMuted(_ muted: Bool) {
        isMuted = muted
        // Sound on takes the audio and ends a floating livestream window, so only one thing is heard.
        if !muted {
            PiPState.shared.stopActivePiPForExcludedSurface()
        }
        applyAudioSession()
    }

    /// The app holds the audio only while a video with sound can play: sound is on and a video is the pick,
    /// or the feed is covered or in the background (the video ended, a sheet or the full player is open).
    private var wantsAudio: Bool {
        !isMuted && ((activeKey != nil && !isPlayingForceMuted) || isSuspended)
    }

    /// While muted, a feed video mixes with other apps (the member's music keeps playing) and takes no audio
    /// focus. With sound on it plays like any video, also in silent mode. On mute, or when no video with sound
    /// is left, the audio is given back with `notifyOthersOnDeactivation`, so a music app that supports it
    /// resumes. A floating livestream window keeps its own audio session.
    func applyAudioSession() {
        guard !PiPState.shared.isActive else { return }
        if wantsAudio {
            holdsAudio = true
            Self.audioQueue.async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback)
                try? session.setActive(true)
            }
        } else {
            // A player over the feed (the full player) still uses the session: give the audio back once it
            // closes, so it is not stopped.
            let givesBack = holdsAudio && !isSuspended
            if givesBack { holdsAudio = false }
            Self.audioQueue.async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.ambient, options: [.mixWithOthers])
                guard givesBack else { return }
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
                // Deactivating stops the players that use the session, so a muted video playing on is resumed.
                DispatchQueue.main.async {
                    if FeedAutoPlayStore.shared.activeKey != nil { FeedAutoPlayStore.shared.resumeRequest += 1 }
                }
            }
        }
    }

    /// Activating and deactivating the audio session blocks until the system answers, so the calls run off the
    /// main thread, in order.
    private static let audioQueue = DispatchQueue(label: "amity.feed-autoplay.audio-session", qos: .userInitiated)

    func setPlayingForceMuted(_ forceMuted: Bool) {
        guard isPlayingForceMuted != forceMuted else { return }
        isPlayingForceMuted = forceMuted
        updateAudioFocus()
    }

    private func updateAudioFocus() {
        guard wantsAudio != holdsAudio, wantsAudio || !isSuspended else { return }
        applyAudioSession()
    }

    // MARK: - Positions

    /// The key a video's state is kept under: its URL without the query. A Mux stream's URL carries a signed
    /// token that the server renews, and different servers sign it differently, so a refreshed post can come
    /// back with a new token for the same video.
    static func stateKey(_ videoURL: URL) -> String {
        guard var parts = URLComponents(url: videoURL, resolvingAgainstBaseURL: false) else {
            return videoURL.absoluteString
        }
        parts.query = nil
        parts.fragment = nil
        return parts.string ?? videoURL.absoluteString
    }

    func position(for videoURL: URL?) -> Double {
        guard let videoURL else { return 0 }
        return positions[Self.stateKey(videoURL)] ?? 0
    }

    func setPosition(_ seconds: Double, for videoURL: URL?) {
        guard let videoURL, seconds.isFinite else { return }
        positions[Self.stateKey(videoURL)] = seconds
    }

    /// A video that played to its end shows its last frame and Watch again when the member comes back to it.
    func hasEnded(_ videoURL: URL?) -> Bool {
        guard let videoURL else { return false }
        return endedVideos.contains(Self.stateKey(videoURL))
    }

    /// A video that failed falls back to its thumbnail and play icon for the rest of the session, and the
    /// next most visible video takes over.
    func hasFailed(_ videoURL: URL?) -> Bool {
        guard let videoURL else { return false }
        return failedVideos.contains(Self.stateKey(videoURL))
    }

    func recordingIndex(forRoom roomId: String?) -> Int {
        guard let roomId else { return 0 }
        return recordingIndexes[roomId] ?? 0
    }

    func setRecordingIndex(_ index: Int, forRoom roomId: String?) {
        guard let roomId else { return }
        recordingIndexes[roomId] = index
    }

    /// Watch again on a room with several recordings: every recording starts over, from the first.
    func restartRecordings(_ urls: [URL], forRoom roomId: String?) {
        for url in urls {
            setEnded(false, for: url)
            setPosition(0, for: url)
        }
        setRecordingIndex(0, forRoom: roomId)
    }

    func keepFrame(_ image: UIImage, for videoURL: URL?) {
        guard let videoURL else { return }
        keptFrames[Self.stateKey(videoURL)] = image
    }

    /// The frame to show for a video that is not playing, while auto-play is on.
    func keptFrame(for videoURL: URL?) -> UIImage? {
        guard isAutoPlayOn, let videoURL else { return nil }
        return keptFrames[Self.stateKey(videoURL)]
    }

    func setFailed(for videoURL: URL?) {
        guard let videoURL else { return }
        failedVideos.insert(Self.stateKey(videoURL))
    }

    func setEnded(_ ended: Bool, for videoURL: URL?) {
        guard let videoURL else { return }
        if ended {
            endedVideos.insert(Self.stateKey(videoURL))
        } else {
            endedVideos.remove(Self.stateKey(videoURL))
        }
    }

    /// Records that a post shows this video, so deleting the post drops the video's state.
    func noteVideo(_ videoURL: URL?, inPost postId: String?) {
        guard let videoURL, let postId else { return }
        videosByPost[postId, default: []].insert(Self.stateKey(videoURL))
    }

    private func forgetVideos(ofPost postId: String) {
        guard let urls = videosByPost.removeValue(forKey: postId) else { return }
        for url in urls {
            positions.removeValue(forKey: url)
            endedVideos.remove(url)
            failedVideos.remove(url)
            keptFrames.removeValue(forKey: url)
        }
    }
}

// MARK: - Feeds that host auto-play

private struct FeedAutoPlayHostKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside the feeds that auto-play videos; elsewhere (search results, pending posts) videos keep
    /// their thumbnail and play icon.
    var feedAutoPlayHost: Bool {
        get { self[FeedAutoPlayHostKey.self] }
        set { self[FeedAutoPlayHostKey.self] = newValue }
    }
}

extension View {
    /// Lets the videos in this feed auto-play.
    func hostsFeedAutoPlay() -> some View {
        environment(\.feedAutoPlayHost, true)
    }

    /// Gives the feeds inside a visible area that starts below the top of the screen; each part that covers or
    /// bounds the feed's top reports itself with `limitsFeedAutoPlayViewport(_:)`.
    func feedAutoPlayViewport() -> some View {
        modifier(FeedAutoPlayViewportRoot())
    }

    /// The feed's visible area starts at this view's top edge (a scroll view under a navigation bar) or its
    /// bottom edge (a sticky header drawn over the feed), while the view is shown.
    func limitsFeedAutoPlayViewport(_ edge: FeedAutoPlayViewportEdge) -> some View {
        background(FeedAutoPlayViewportLimit(edge: edge))
    }

    /// Reports this frame's place on screen under `key` while it is shown, so it can be picked to play.
    /// A nil key reports nothing, and a frame that stops reporting can no longer play.
    func reportsFeedAutoPlayVisibility(key: String?) -> some View {
        background(FeedAutoPlayVisibilityReporter(key: key))
    }

    /// In a feed that auto-plays, the thumbnail's play icon is its own element with the test ID
    /// `feed_post_video/play_button`; elsewhere it stays part of the media, as before.
    @ViewBuilder
    func feedPlayButtonAccessibility(_ inFeed: Bool) -> some View {
        if inFeed {
            accessibilityElement()
                .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.playButton)
        } else {
            self
        }
    }

    /// Stops the feed video while `isCovering` is true, for a sheet, menu or player shown over the feed.
    func suspendsFeedAutoPlay(_ isCovering: Bool) -> some View {
        modifier(FeedAutoPlayCoverModifier(isCovering: isCovering))
    }
}

/// Which edge of a view bounds the feed's visible area (`VerticalEdge` needs iOS 15).
enum FeedAutoPlayViewportEdge {
    case top
    case bottom
}

/// Where a feed's visible area starts on screen: the lowest edge any of its limits reports.
final class FeedAutoPlayViewportState {
    private var limits: [String: CGFloat] = [:]

    var top: CGFloat { limits.values.max() ?? 0 }

    func set(_ y: CGFloat?, for id: String) {
        limits[id] = y
    }
}

private struct FeedAutoPlayViewportKey: EnvironmentKey {
    static let defaultValue: FeedAutoPlayViewportState? = nil
}

extension EnvironmentValues {
    var feedAutoPlayViewport: FeedAutoPlayViewportState? {
        get { self[FeedAutoPlayViewportKey.self] }
        set { self[FeedAutoPlayViewportKey.self] = newValue }
    }
}

private struct FeedAutoPlayViewportRoot: ViewModifier {
    @State private var state = FeedAutoPlayViewportState()

    func body(content: Content) -> some View {
        content.environment(\.feedAutoPlayViewport, state)
    }
}

private struct FeedAutoPlayViewportLimit: View {
    let edge: FeedAutoPlayViewportEdge
    @Environment(\.feedAutoPlayViewport) private var viewport
    @State private var id = UUID().uuidString

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear { update(geometry.frame(in: .global)) }
                .onChange(of: geometry.frame(in: .global)) { update($0) }
                .onDisappear { viewport?.set(nil, for: id) }
        }
    }

    private func update(_ frame: CGRect) {
        viewport?.set(edge == .top ? frame.minY : frame.maxY, for: id)
    }
}

private struct FeedAutoPlayVisibilityReporter: View {
    let key: String?
    @Environment(\.feedAutoPlayViewport) private var viewport

    var body: some View {
        if let key {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        FeedAutoPlayStore.shared.report(key: key, frame: geometry.frame(in: .global),
                                                        viewportTop: viewport?.top ?? 0)
                    }
                    .onChange(of: geometry.frame(in: .global)) { frame in
                        FeedAutoPlayStore.shared.report(key: key, frame: frame, viewportTop: viewport?.top ?? 0)
                    }
                    .onDisappear {
                        FeedAutoPlayStore.shared.remove(key: key)
                    }
            }
        }
    }
}

private struct FeedAutoPlayCoverModifier: ViewModifier {
    let isCovering: Bool
    @State private var reason = UUID().uuidString

    func body(content: Content) -> some View {
        content
            .onAppear {
                if isCovering {
                    FeedAutoPlayStore.shared.setSuspended(true, reason: reason)
                }
            }
            .onChange(of: isCovering) { covering in
                FeedAutoPlayStore.shared.setSuspended(covering, reason: reason)
            }
            .onDisappear {
                FeedAutoPlayStore.shared.setSuspended(false, reason: reason)
            }
    }
}

extension AmityMedia {
    /// A video still being processed after upload: it has no playable stream yet. It can still be the pick;
    /// while it is, it shows the spinner and is looked up again every 3 s until it is ready.
    var isProcessingVideo: Bool {
        guard type == .video, let status = video?.status else { return false }
        return status == .uploaded || status == .transcoding
    }

    /// A video whose processing failed on the server: it never plays and shows the fallback.
    var isFailedTranscodeVideo: Bool {
        guard type == .video, let status = video?.status else { return false }
        return status == .transcodeFailed || status == .error
    }

    /// The URL the feed and the full player both play, so positions match across them. A clip post keeps its
    /// video in `clip`, the URL the clip feed plays.
    var autoPlayVideoURL: URL? {
        if let urlStr = video?.getVideo(resolution: .original) {
            return URL(string: urlStr)
        } else if let urlStr = video?.fileURL {
            return URL(string: urlStr)
        } else if let urlStr = clip?.fileURL, !urlStr.isEmpty {
            return URL(string: urlStr)
        }
        return nil
    }
}
