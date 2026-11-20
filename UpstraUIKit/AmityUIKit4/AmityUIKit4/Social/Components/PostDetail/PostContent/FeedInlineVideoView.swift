//
//  FeedInlineVideoView.swift
//  AmityUIKit4
//

import SwiftUI
import AVFoundation
import AmitySDK

/// A feed video playing in place, drawn over its thumbnail while `FeedAutoPlayStore` makes it active.
///
/// It plays in the session sound state (muted until the member unmutes) from where the video last stopped,
/// once: at the end it stops on its last frame, dimmed, with Watch again in the centre. The sound button sits
/// bottom-right while it plays and after it ends. Coming back to a video that ended shows that end state again instead of
/// replaying it. The position and the end state are written back to the store when it stops.
///
/// The video starts at once. If its first frame takes longer than a second, the spinner shows over the thumbnail
/// until that frame is drawn, with no time limit; a quick start goes from the thumbnail straight to the video.
/// A stall while playing, and a live stream reconnecting, show the spinner at once. A video that fails
/// to load or play is marked failed in the store, which takes it out of the running: its frame falls back to
/// the thumbnail and play icon, and the next most visible video plays.
///
/// A live stream has no end and no position: it always joins at the live edge, never shows Watch again, and
/// shows the spinner while its room is reconnecting. Like any feed video it sends no viewer heartbeat and
/// starts no watch session; those start only in the live player.
struct FeedInlineVideoView: View {

    @ObservedObject private var store = FeedAutoPlayStore.shared
    /// Set up before the player is made: `AmityMediaPlayer` configures it on creation, before `onAppear`, and
    /// a controller that sets the audio session itself would do so on the main thread at every start.
    @StateObject private var controller: AmityMediaPlayerController = {
        let controller = AmityMediaPlayerController()
        controller.autoReplay = false
        controller.holdsLastFrameAtEnd = true
        controller.configuresAudioSession = false
        controller.startsQuickly = true
        return controller
    }()
    /// Set a second after the view appears: the first load shows the spinner only once it takes that long.
    @State private var firstLoadIsSlow = false
    /// True for a second after the system paused the player and it was asked to play on (headphones went
    /// away, the audio was given back): the restart waits for data briefly, which is not a stall.
    @State private var isResuming = false

    let url: URL
    /// Fill for feed media at the post's locked ratio; a clip in fit mode letterboxes like its thumbnail.
    let videoGravity: AVLayerVideoGravity
    /// A live stream, as opposed to a video or a recorded live stream.
    let isLive: Bool
    /// True while a live stream's room waits to reconnect.
    let isReconnecting: Bool
    /// What the frame reads out, from the frame that hosts this player.
    let accessibilityLabel: String
    /// Whether the video had already played to its end when this view first appeared.
    private let startsEnded: Bool
    /// A clip saved as muted: it always plays muted and its sound button is disabled.
    let isForceMuted: Bool
    /// Set for a recording followed by another: at its end the next one plays instead of Watch again.
    let onReachedEnd: (() -> Void)?
    /// Set for a room with several recordings: Watch again starts from the first.
    let onWatchAgain: (() -> Void)?

    init(url: URL, videoGravity: AVLayerVideoGravity = .resizeAspectFill, isLive: Bool = false, isReconnecting: Bool = false,
         accessibilityLabel: String = "", isForceMuted: Bool = false, onReachedEnd: (() -> Void)? = nil,
         onWatchAgain: (() -> Void)? = nil) {
        self.isForceMuted = isForceMuted
        self.onReachedEnd = onReachedEnd
        self.onWatchAgain = onWatchAgain
        self.accessibilityLabel = accessibilityLabel
        self.url = url
        self.videoGravity = videoGravity
        self.isLive = isLive
        self.isReconnecting = isReconnecting
        self.startsEnded = !isLive && FeedAutoPlayStore.shared.hasEnded(url)
    }

    var body: some View {
        ZStack {
            AmityMediaPlayer(url: url, controller: controller, autoPlay: !startsEnded)
                .allowsHitTesting(false)

            // The frame as one element whose value is its state, so tests read it by id; the buttons on top
            // stay their own elements.
            Color.clear
                .allowsHitTesting(false)
                .accessibilityElement()
                .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.frame)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(accessibilityState)

            if showsLoadingRing {
                FeedVideoLoadingOverlay()
            }

            if isShowingEnd {
                endedOverlay
            }

            soundButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onAppear {
            controller.enableFrameCapture()
            store.applyAudioSession()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { firstLoadIsSlow = true }
            // Drawn like the thumbnail underneath.
            controller.setVideoGravity(videoGravity)
            controller.setMuted(isMuted)
            store.setPlayingForceMuted(isForceMuted)
            let start = isLive ? 0 : store.position(for: url)
            if start > 0 {
                controller.seek(to: start)
            }
        }
        .onChange(of: store.isMuted) { _ in
            controller.setMuted(isMuted)
        }
        // The system paused the player (headphones went away, or the audio was given back): play on.
        .onChange(of: store.resumeRequest) { _ in
            guard !isShowingEnd, !controller.hasFailed else { return }
            isResuming = true
            controller.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isResuming = false }
        }
        .onChange(of: controller.hasEnded) { ended in
            guard ended, !isLive else { return }
            if let onReachedEnd {
                store.setPosition(0, for: url)
                onReachedEnd()
            } else {
                store.setEnded(true, for: url)
            }
        }
        .onChange(of: controller.hasFailed) { failed in
            // A live stream that drops while its room reconnects is not a failure; the room status decides.
            if failed && !isReconnecting {
                store.setFailed(for: url)
            }
        }
        // In the background the view may not update until the app returns, so the player stops here at once
        // instead of waiting for the store to take it off screen.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            savePosition()
            controller.pause()
        }
        .onDisappear {
            savePosition()
            controller.pause()
            keepFrame()
            if isForceMuted { store.setPlayingForceMuted(false) }
        }
    }

    /// Keeps the frame the video stopped on, so the post shows it when scrolled back to.
    private func keepFrame() {
        guard !isLive, controller.hasFirstFrame, !controller.hasFailed else { return }
        let url = self.url
        controller.currentFrameImage { image in
            guard let image else { return }
            FeedAutoPlayStore.shared.keepFrame(image, for: url)
        }
    }

    /// The last frame dimmed with black at 50%, and the full video player's Watch again in the centre at the feed's
    /// size: a 40 × 40 black-at-50% circle (the full player uses 48 × 48) with the 24 pt rotate-left icon, and the
    /// label (Caption Bold, 18 pt line height) 4 pt under it, in a group padded 7 top and bottom and 15 left and
    /// right (Figma 18:2027, Replay state; Video Controls · Replay).
    private var endedOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .allowsHitTesting(false)

            VStack(spacing: 4) {
                Image(AmityIcon.watchAgainIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.5)))

                Text(AmityLocalizedStringSet.Social.feedVideoWatchAgain.localizedString)
                    .applyTextStyle(.captionBold(.white))
                    .frame(height: 18)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 15)
            .contentShape(Rectangle())
            // A gesture, not a Button: the frame's own tap (open the full player) would otherwise win.
            .highPriorityGesture(TapGesture().onEnded { watchAgain() })
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.replayButton)
        }
    }

    /// A 24 × 24 black-at-50% circle, 12 from the bottom and the right, with a white speaker: slashed while
    /// muted. One tap sets the sound for the rest of the session (Figma 16:1319, 36:12236).
    private var soundButton: some View {
        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") // l10n:ok SF Symbol name
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color.black.opacity(0.5)))
            .contentShape(Circle().inset(by: -10))
            // A gesture, not a Button: the frame's own tap (open the full player) would otherwise win.
            // A clip saved as muted keeps the button, disabled; a tap on it does nothing.
            .opacity(isForceMuted ? 0.5 : 1)
            .highPriorityGesture(TapGesture().onEnded { if !isForceMuted { store.setMuted(!store.isMuted) } })
            .padding(12)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.soundButton)
            .accessibilityValue(isMuted ? "muted" : "sound_on") // l10n:ok test value, not read out as text
            .disabled(isForceMuted)
            .accessibilityLabel(isMuted
                                ? AmityLocalizedStringSet.Social.feedVideoSoundOn.localizedString
                                : AmityLocalizedStringSet.Social.feedVideoSoundOff.localizedString)
    }

    /// The sound state this video plays in: the session's, or always muted for a clip saved as muted.
    private var isMuted: Bool {
        isForceMuted || store.isMuted
    }

    private var isShowingEnd: Bool {
        !isLive && onReachedEnd == nil && (controller.hasEnded || (startsEnded && !controller.isPlaying))
    }

    /// Before playback has really started: a stream may draw its first frame and still wait a moment, which is
    /// part of the start, so the 1 s delay covers it.
    private var isFirstLoading: Bool {
        // A quick start reports playing before it has drawn anything, so the start ends at the first frame too.
        !startsEnded && !(controller.hasStartedPlaying && controller.hasFirstFrame) && !controller.hasFailed
    }

    /// A stall once playback has started, while it should be playing. A stream often waits again in its first
    /// moments while it settles on a quality; within the first second that is still the start, under the 1 s
    /// delay, so a quick start shows no spinner.
    private var isStalled: Bool {
        controller.hasStartedPlaying && controller.isStalled && !isShowingEnd && !isResuming && firstLoadIsSlow
    }

    private var showsLoadingRing: Bool {
        isReconnecting || isStalled || (isFirstLoading && firstLoadIsSlow)
    }

    private var accessibilityState: String {
        if isShowingEnd { return "ended" } // l10n:ok test value
        if isReconnecting || isStalled || isFirstLoading { return "loading" } // l10n:ok test value
        return isMuted ? "playing_muted" : "playing_sound" // l10n:ok test value
    }

    private func savePosition() {
        guard !isLive, !controller.hasEnded || onReachedEnd == nil else { return }
        store.setPosition(controller.currentTime, for: url)
    }

    private func watchAgain() {
        if let onWatchAgain {
            onWatchAgain()
            return
        }
        store.setEnded(false, for: url)
        store.setPosition(0, for: url)
        controller.restart()
    }
}

/// The video spinner of the full player and of every feed video while it loads, stalls or a live stream
/// reconnects: a white 2 pt quarter arc with no track at 40×40, one turn a second.
struct FeedVideoLoadingRing: View {
    var body: some View {
        LiveStreamCircularProgressBar(
            progress: .constant(25),
            config: LiveStreamCircularProgressBar.Config(
                backgroundColor: .clear,
                foregroundColor: .white,
                strokeWidth: 2,
                rotationDuration: 1.0
            )
        )
        .frame(width: 40, height: 40)
    }
}

/// The feed's loading state: the frame dimmed with black at 50% and the spinner in the centre. The sound
/// button, tag badge and counter stay on top and keep working.
struct FeedVideoLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            FeedVideoLoadingRing()
        }
        .allowsHitTesting(false)
    }
}

/// A feed video that is the pick while it is still being processed after upload: the spinner over its
/// thumbnail at once (no 1 s delay, no time limit), and the file looked up again every 3 s. Once it has a
/// playable stream it plays like any feed video. Scrolling it below half removes this view, which stops
/// the lookups and hands the player to the next video. It never shows the fallback.
struct FeedProcessingVideoView: View {
    /// The post that holds the video; it is fetched again to learn when the video is ready.
    let postId: String
    let fileId: String
    let accessibilityLabel: String

    @State private var readyURL: URL?
    @State private var lookUpToken: AmityNotificationToken?
    private let tick = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        if let readyURL {
            FeedInlineVideoView(url: readyURL, accessibilityLabel: accessibilityLabel)
        } else {
            ZStack {
                Color.clear
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.frame)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityValue("loading") // l10n:ok test value
                FeedVideoLoadingOverlay()
            }
            .onAppear { lookUp() }
            .onReceive(tick) { _ in lookUp() }
            .onDisappear {
                lookUpToken?.invalidate()
                lookUpToken = nil
            }
        }
    }

    /// Fetches the post from the server (the file repository answers from its cache, so it never sees the
    /// video finish processing) and plays once its video is transcoded.
    private func lookUp() {
        guard readyURL == nil else { return }
        lookUpToken?.invalidate()
        let fileId = self.fileId
        lookUpToken = AmityPostRepository().getPost(withId: postId).observe { live, _ in
            guard live.dataStatus == .fresh, let post = live.snapshot else { return }
            guard let video = post.childrenPosts.compactMap({ $0.getVideoInfo() }).first(where: { $0.fileId == fileId }),
                  video.status == .transcoded,
                  let urlString = video.getVideo(resolution: .original) ?? (video.fileURL.isEmpty ? nil : video.fileURL),
                  let url = URL(string: urlString) else { return }
            readyURL = url
        }
    }
}
