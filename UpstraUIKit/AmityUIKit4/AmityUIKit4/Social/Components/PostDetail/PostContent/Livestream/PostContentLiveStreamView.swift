//
//  PostContentLiveStreamView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/24.
//

import SwiftUI
import AmitySDK
import AVKit

struct PostContentLiveStreamView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    @State var showVideoPlayer: Bool = false
    @State private var taggedProducts: [AmityProduct] = []
    @State private var previousProductCount: Int = 0
    @State private var showProductTagSheet: Bool = false

    @Environment(\.feedAutoPlayHost) private var feedAutoPlayHost
    @ObservedObject private var autoPlay = FeedAutoPlayStore.shared
    /// The same post can be on screen twice, so each instance reports under its own key.
    @State private var autoPlayInstanceId = UUID()
    
    let post: AmityPostModel
    let room: AmityRoom?
    let isStreamDeleted: Bool
    let isStreamBanned: Bool
    var pageId: PageId? = nil
    
    private var postManager = PostManager()

    /// Resolves the thumbnail URL using priority: creator-uploaded → live thumbnail → placeholder
    private var resolvedThumbnailURL: String? {
        // 1. Creator-uploaded thumbnail (thumbnailFileId)
        if let creatorThumbnail = room?.getThumbnail()?.mediumFileURL, !creatorThumbnail.isEmpty {
            return creatorThumbnail
        }
        // 2. Live thumbnail (Mux auto-generated)
        if let liveThumbnail = room?.liveThumbnailUrl, !liveThumbnail.isEmpty {
            return liveThumbnail
        }
        
        // 3. Recorded thumbnail
        if let recordedData = room?.recordedData.first {
            return recordedData.thumbnailUrl
        }
        
        // 4. No thumbnail available → placeholder
        return nil
    }

    private var contentHeight: CGFloat {
        let height16x9: CGFloat = 208
        let height4x5: CGFloat = 480
        
        // Idle state always uses 16:9 aspect ratio with placeholder thumbnail
        if post.livestreamState == .idle {
            return height16x9
        }
        
        // Creator-uploaded thumbnail uses platform default (16:9 for iOS)
        if let creatorThumbnail = room?.getThumbnail()?.mediumFileURL, !creatorThumbnail.isEmpty {
            return height16x9
        }

        // Live/recorded thumbnails use resolution data to determine aspect ratio
        let resolution: AmityRoomResolution? = {
            switch post.livestreamState {
            case .live:
                return room?.liveResolution
            case .recorded:
                return room?.recordedResolution
            default:
                return room?.liveResolution ?? room?.recordedResolution
            }
        }()

        if let width = resolution?.width, let height = resolution?.height, width > 0, height > 0 {
            // Portrait or square → 4:5, Landscape → 16:9
            return height >= width ? height4x5 : height16x9
        }

        // iOS default: 16:9
        return height16x9
    }

    init(post: AmityPostModel, pageId: PageId? = nil) {
        self.post = post
        self.pageId = pageId
        self.room = post.room
        self.isStreamDeleted = room?.isDeleted ?? false
        self.isStreamBanned = false
//        self.isStreamBanned = room?.isBanned ?? false
        
        // Initialize tagged products from child post
        if let childPost = post.childrenPosts.first {
            let mediaProductTags = childPost.getMediaProductTags()
            self._taggedProducts = State(initialValue: mediaProductTags.compactMap { $0.product })
        }
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            
            Rectangle()
                .foregroundColor(Color.black)
            
            if isStreamDeleted {
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamErrorIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                }
                .padding(.horizontal, 16)
            } else if isStreamBanned {
                VStack(alignment: .center) {
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerBannedTitle.localizedString)
                        .applyTextStyle(.titleBold(.white))
                        .padding(.bottom, 4)
                    
                    Text( AmityLocalizedStringSet.Social.livestreamPlayerBannedMessage.localizedString)
                        .applyTextStyle(.caption(.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            } else {
                switch post.livestreamState {
                case .idle, .live, .recorded:
                    
                    AsyncImage(placeholder: AmityIcon.livestreamPlaceholderGray.imageResource, url: URL(string: resolvedThumbnailURL ?? ""), contentMode: .fill)

                    // Plays in place without counting: no viewer heartbeat, no watch session. A tap outside the
                    // sound button still opens the live player, where counting starts.
                    if isAutoPlayActive, let url = autoPlayURL {
                        FeedInlineVideoView(
                            url: url,
                            isLive: post.livestreamState == .live,
                            isReconnecting: room?.status == .waitingReconnect,
                            onReachedEnd: nextRecordingAction,
                            onWatchAgain: watchAgainAction
                        )
                        // Each recording is its own player.
                        .id(url)
                    } else if feedAutoPlayHost {
                        // Not playing: the frame reads as the thumbnail, or as the fallback when playback failed
                        // or the post is an old-protocol live stream, which never plays in the feed.
                        Color.clear
                            .allowsHitTesting(false)
                            .accessibilityElement()
                            .accessibilityIdentifier(AccessibilityID.Social.FeedPostVideo.frame)
                            .accessibilityValue(isFallback ? "fallback" : "thumbnail") // l10n:ok test value
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Spacer()
                            
                            // "RECORDED" badge moved to top-right
                            Text(post.livestreamState.badgeTitle)
                                .applyTextStyle(.captionBold(.white))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(post.livestreamState == .live ? Color(AmityFixedColor.shared.live) : Color.black.opacity(0.5))
                                .blurBackground(style: .regular)
                                .cornerRadius(4, corners: .allCorners)
                                .padding(12)
                        }
                        
                        Spacer()
                        
                        // Tag badge on bottom-left - tappable to open product tag list
                        let childPost = post.childrenPosts.first
                        let productCount = childPost?.getMediaProductTags().count ?? 0
                        
                        if productCount > 0 {
                            HStack {
                                AmityProductTagBadgeView(count: productCount)
                                    .padding(12)
                                    .onTapGesture {
                                        showProductTagSheet = true
                                    }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Image(AmityIcon.videoControlIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .isHidden(post.livestreamState == .idle || isAutoPlayActive || (autoPlay.isAutoPlayOn && autoPlayKey != nil))
                        .feedPlayButtonAccessibility(feedAutoPlayHost && !(post.livestreamState == .idle || isAutoPlayActive || (autoPlay.isAutoPlayOn && autoPlayKey != nil)))
                    
                case .ended:
                    VStack(alignment: .center) {
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .error:
                    VStack(alignment: .center) {
                        Image(AmityIcon.livestreamErrorIcon.imageResource)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 12)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerErrorTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerErrorMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .terminated:
                    VStack(alignment: .center) {
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedTitle.localizedString)
                            .applyTextStyle(.titleBold(.white))
                            .padding(.bottom, 4)
                        
                        Text( AmityLocalizedStringSet.Social.livestreamPlayerTerminatedMessage.localizedString)
                            .applyTextStyle(.caption(.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                case .none:
                    EmptyView()
                    
                }
            }
        }
        .frame(height: contentHeight)
        .contentShape(Rectangle())
        .reportsFeedAutoPlayVisibility(key: autoPlayKey)
        .onAppear {
            // A recording keeps a position; deleting the post drops it.
            guard feedAutoPlayHost, post.livestreamState == .recorded else { return }
            for url in recordingURLs {
                autoPlay.noteVideo(url, inPost: post.postId)
            }
        }
        .onTapGesture {
            guard !isStreamBanned else { return }
            
            switch post.livestreamState {
            case .live, .recorded:
                if let roomId = post.room?.roomId,
                   PiPState.shared.isPiPActive(forRoomId: roomId) {
                    PiPState.shared.restoreActivePiP()
                    return
                }
                let livestreamPlayerPage = AmityLivestreamPlayerPage(post: post.object)
                let hostController = AmitySwiftUIHostingNavigationController(rootView: livestreamPlayerPage)
                hostController.isNavigationBarHidden = true
                hostController.modalPresentationStyle = .overFullScreen
                PiPState.shared.abandonActivePiP { presenter in
                    presenter?.present(hostController, animated: true)
                }
            default:
                break
            }
        }
        .suspendsFeedAutoPlay(showProductTagSheet)
        .sheet(isPresented: $showProductTagSheet) {
            productTagListSheet
        }
    }
    
    /// The live stream while the room is live (or reconnecting), the recording once it is recorded.
    private var autoPlayURL: URL? {
        let urlString: String?
        switch post.livestreamState {
        case .live:
            urlString = room?.livePlaybackUrl
        case .recorded:
            return recordingURLs.isEmpty ? nil : recordingURLs[currentRecordingIndex]
        default:
            urlString = nil
        }
        guard let urlString, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    /// A recorded room's recordings, played back to back in the feed.
    private var recordingURLs: [URL] {
        (room?.recordedData ?? []).compactMap { data in
            data.playbackUrl.isEmpty ? nil : URL(string: data.playbackUrl)
        }
    }

    /// The recording the feed has reached this session.
    private var currentRecordingIndex: Int {
        min(autoPlay.recordingIndex(forRoom: room?.roomId), max(recordingURLs.count - 1, 0))
    }

    /// At the end of a recording followed by another, the next one plays.
    private var nextRecordingAction: (() -> Void)? {
        guard post.livestreamState == .recorded, currentRecordingIndex < recordingURLs.count - 1 else { return nil }
        let next = currentRecordingIndex + 1
        let roomId = room?.roomId
        return { FeedAutoPlayStore.shared.setRecordingIndex(next, forRoom: roomId) }
    }

    /// Watch again on a room with several recordings starts from the first.
    private var watchAgainAction: (() -> Void)? {
        guard post.livestreamState == .recorded, recordingURLs.count > 1 else { return nil }
        let urls = recordingURLs
        let roomId = room?.roomId
        return { FeedAutoPlayStore.shared.restartRecordings(urls, forRoom: roomId) }
    }

    private var autoPlayKey: String? {
        guard feedAutoPlayHost, !isStreamDeleted, !isStreamBanned, let url = autoPlayURL, !autoPlay.hasFailed(url),
              let roomId = room?.roomId else { return nil }
        return "\(roomId)#\(autoPlayInstanceId.uuidString)"
    }

    private var isAutoPlayActive: Bool {
        guard let autoPlayKey else { return false }
        return autoPlay.activeKey == autoPlayKey
    }

    /// An old-protocol live stream never plays in the feed; a room whose stream failed falls back too.
    private var isFallback: Bool {
        post.dataTypeInternal == .liveStream || autoPlay.hasFailed(autoPlayURL)
    }

    @ViewBuilder
    private var productTagListSheet: some View {
        if let childPost = post.childrenPosts.first {
            let productTags = childPost.getMediaProductTags().compactMap { mediaTag -> AmityProductTagModel? in
                guard let product = mediaTag.product else { return nil }
                return AmityProductTagModel(object: product, range: NSRange(location: 0, length: 0), contentType: .media)
            }
            if !productTags.isEmpty {
                AmityProductTagListComponent(
                    pageId: pageId,
                    productTags: productTags,
                    renderMode: .livestream,
                    sourceId: post.room?.roomId ?? "",
                    onClose: {
                        self.host.controller?.dismiss(animated: true)
                    }
                )
                .environmentObject(host)
                .halfSheetPresentation()
            }
        }
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.overrideUserInterfaceStyle = .light
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.overrideUserInterfaceStyle = .light
    }
}

extension View {
    func blurBackground(style: UIBlurEffect.Style) -> some View {
        background(BlurView(style: style))
    }
}
