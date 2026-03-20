//
//  AmityPostMediaVideoPlayer.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/23/26.
//

import SwiftUI
import AVFoundation
import SafariServices
import AmitySDK

enum VideoPlayerType {
    case video(AmityMedia)
    case livestream(AmityRoom)

    var isLivestream: Bool {
        if case .livestream = self { return true }
        return false
    }
}

struct AmityPostMediaVideoPlayer: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var pageId: PageId? = nil
    let post: AmityPostModel
    let playerType: VideoPlayerType
    let hideActionMenu: Bool
    var onClose: (() -> Void)? = nil
    var onTagProducts: (() -> Void)? = nil
    @Binding var liveProductTags: [AmityProductTagModel]

    @State private var showBottomSheet: Bool = false
    @State private var showProductTagSheet: Bool = false

    @StateObject private var playerController = AmityMediaPlayerController()
    @StateObject private var deletedStateViewModel: VideoPlayerDeletedStateViewModel
    @State private var sliderValue: Double = 0

    private var isDeleted: Bool {
        deletedStateViewModel.isPostDeleted || deletedStateViewModel.isVideoDeleted(videoURL)
    }

    // Extract video URL based on player type
    private var videoURL: URL? {
        switch playerType {
        case .video(let media):
            if let urlStr = media.video?.getVideo(resolution: .original) {
                return URL(string: urlStr)
            } else if let urlStr = media.video?.fileURL {
                return URL(string: urlStr)
            }
            return nil
        case .livestream(let room):
            return URL(string: room.recordedData.first?.playbackUrl ?? "")
        }
    }

    // Get product tags based on player type
    private func getMediaProductTags() -> [AmityProductTagModel] {
        switch playerType {
        case .video(let media):
            return media.produtTags
        case .livestream:
            return liveProductTags
        }
    }

    init(pageId: PageId? = nil, post: AmityPostModel, playerType: VideoPlayerType, hideActionMenu: Bool = true, onClose: (() -> Void)? = nil, onTagProducts: (() -> Void)? = nil, liveProductTags: Binding<[AmityProductTagModel]> = .constant([])) {
        self.pageId = pageId
        self.post = post
        self.hideActionMenu = hideActionMenu
        self.playerType = playerType
        self.onClose = onClose
        self.onTagProducts = onTagProducts
        self._liveProductTags = liveProductTags
        self._deletedStateViewModel = StateObject(wrappedValue: VideoPlayerDeletedStateViewModel(post: post))
    }

    var body: some View {
        ZStack {
            if isDeleted {
                deletedStateView
            } else {
                playerContentView
            }
        }
        .background(Color.black)
        .onAppear {
            playerController.autoReplay = false
        }
        .onChange(of: sliderValue) { newValue in
            if playerController.isSeeking {
                playerController.setCurrentTime(newValue)
            }
        }
        .onChange(of: playerController.currentTime) { newTime in
            if !playerController.isSeeking {
                sliderValue = newTime
            }
        }
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: onTagProducts != nil ? Color(viewConfig.defaultDarkTheme.backgroundColor) : Color(.systemBackground), sheetContent: {
            bottomSheetView
        })
        .sheet(isPresented: $showProductTagSheet) {
            productTagListSheet
        }
    }

    // MARK: - Deleted State View
    private var deletedStateView: some View {
        ZStack {
            Color.black

            VStack(spacing: 16) {
                Image(AmityIcon.videoNotAvailableIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)

                Text("This video is no longer available.")
                    .foregroundColor(.white)
                    .font(.system(size: 17))
            }

            VStack {
                HStack {
                    Button(action: { onClose?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)

                Spacer()
            }
            .padding(.top, 64)
            .padding(.bottom, 36)
        }
    }

    // MARK: - Player Content View
    private var playerContentView: some View {
        ZStack {
            // Video player layer
            if let url = videoURL {
                AmityMediaPlayer(url: url, controller: playerController)
                    .onTapGesture {
                        playerController.togglePlayPause()
                    }
                    .onDisappear {
                        playerController.pause()
                    }
            } else {
                Color.black
                    .overlay(
                        Text("Video is not available")
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                    )
            }

            // Overlay controls
            VStack(spacing: 0) {
                topNavigationBar
                Spacer()
                bottomContentContainer
            }
            .padding(.top, 64)
            .padding(.bottom, 36)

            // Center play icon (shown only when paused)
            centerPlayPauseButton
                .opacity(playerController.isPlaying ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: playerController.isPlaying)
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 16) {
            // Close button
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }

            Spacer()

            // Volume button
            Button(action: {
                playerController.toggleMute()
            }) {
                Image(systemName: playerController.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }

            // More options button
            if !hideActionMenu {
                Button(action: {
                    showBottomSheet.toggle()
                }) {
                    Image(playerType.isLivestream ? AmityIcon.livestreamPostPlayerActionButton.getImageResource() : AmityIcon.postPlayerActionButton.getImageResource())                    
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Center Play Icon
    private var centerPlayPauseButton: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 0.5)

            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bottom Content Container
    private var bottomContentContainer: some View {
        VStack(spacing: 0) {
            // Product tag badge (if any)
            let productTags = getMediaProductTags()
            if !productTags.isEmpty {
                HStack {
                    Spacer()

                    AmityProductTagBadgeView(count: productTags.count)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .onTapGesture {
                            if onTagProducts != nil {
                                onTagProducts?()
                            } else {
                                showProductTagSheet = true
                            }
                        }
                }
            }

            // Video seeker bar section
            VStack(spacing: 16) {
                // Time labels
                HStack {
                    Text(formatTime(playerController.currentTime))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)

                    Spacer()

                    Text(formatTime(playerController.duration))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)

                // Progress slider
                VideoProgressSlider(
                    value: $sliderValue,
                    range: 0...max(playerController.duration, 1),
                    onEditingChanged: { editing in
                        if editing {
                            playerController.beginSeeking()
                        } else {
                            playerController.seek(to: sliderValue)
                        }
                    }
                )
                .padding(.horizontal, 12)
                .frame(height: 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Bottom Sheet Content
    @ViewBuilder
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            if let onTagProducts = onTagProducts {
                // Tag products row (dark-themed, host only)
                let productCount = liveProductTags.count
                Button {
                    showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onTagProducts()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(viewConfig.defaultDarkTheme.backgroundShade1Color))
                                .frame(width: 32, height: 32)
                            Image(AmityIcon.LiveStream.productTaggingIcon.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColor))
                        }
                        Text("Tag products")
                            .applyTextStyle(.bodyBold(Color(viewConfig.defaultDarkTheme.baseColor)))
                        Spacer()
                        Text("\(productCount)")
                            .applyTextStyle(.body(Color(viewConfig.defaultDarkTheme.baseColorShade1)))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColorShade1))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                BottomSheetItemView(
                    icon: AmityIcon.viewPostIcon.getImageResource(),
                    text: "View post"
                )
                .onTapGesture {
                    showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        goToPostDetailPage()
                    }
                }
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Product Tag List Sheet
    @ViewBuilder
    private var productTagListSheet: some View {
        let productTags = getMediaProductTags()
        if !productTags.isEmpty {
            let component = AmityProductTagListComponent(
                pageId: pageId,
                productTags: productTags,
                renderMode: playerType.isLivestream ? .livestream : .video,
                sourceId: post.postId,
                onClose: {
                    UIApplication.topViewController()?.dismiss(animated: true)
                },
                onProductClick:  { productTag in
                    if let url = URL(string: productTag.object.productUrl) {
                        let browserVC = SFSafariViewController(url: url)
                        browserVC.modalPresentationStyle = .pageSheet
                        UIApplication.topViewController()?.present(browserVC, animated: true)
                    }
                })
            component
                .environmentObject(host)
                .halfSheetPresentation()
        }
    }

    // MARK: - Helper Functions
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "00:00:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func goToPostDetailPage() {
        playerController.pause()
        let postDetailPage = AmityPostDetailPage(post: post.object, context: nil)
        let controller = AmitySwiftUIHostingController(rootView: postDetailPage)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Video Player Deleted State ViewModel
class VideoPlayerDeletedStateViewModel: ObservableObject {
    @Published var isPostDeleted: Bool = false
    @Published var deletedFileIds: Set<String> = []

    private var post: AmityPostModel?

    func isVideoDeleted(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        let urlString = url.absoluteString
        return deletedFileIds.contains { fileId in
            urlString.contains(fileId)
        }
    }

    init(post: AmityPostModel?) {
        self.post = post
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .didPostImageUpdated,
            object: nil,
            queue: .main) { [weak self] notification in
                if let deletedFileIds = notification.userInfo?["deletedFileIds"] as? [String],
                   !deletedFileIds.isEmpty {
                    DispatchQueue.main.async {
                        for fileId in deletedFileIds {
                            self?.deletedFileIds.insert(fileId)
                        }
                    }
                }
            }

        NotificationCenter.default.addObserver(
            forName: .didPostLocallyDeleted,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.deletedFileIds = Set(self?.post?.medias.compactMap({ $0.video?.fileId }) ?? [])
            }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Video Progress Slider
struct VideoProgressSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void = { _ in }

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    @State private var isDragging = false
    private let sliderHeight: Double = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track (gray with opacity)
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: sliderHeight)

                // Filled progress (white)
                Capsule()
                    .fill(Color.white)
                    .frame(width: CGFloat(progress) * geometry.size.width, height: sliderHeight)

                // Knob (always visible based on Figma design)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0.5)
                    .offset(x: max(0, min(CGFloat(progress) * geometry.size.width - 12, geometry.size.width - 24)))
            }
            .contentShape(Rectangle())
            .frame(height: 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        onEditingChanged(true)

                        let location = gesture.location.x
                        let clamped = min(max(0, location), geometry.size.width)
                        let newValue = range.lowerBound + (Double(clamped / geometry.size.width) * (range.upperBound - range.lowerBound))
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 20)
    }
}
