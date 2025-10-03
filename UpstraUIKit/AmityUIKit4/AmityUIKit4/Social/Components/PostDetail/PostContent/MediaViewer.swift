//
//  MediaViewer.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/13/24.
//

import Foundation
import SwiftUI
import AmitySDK
import AVKit

struct MediaViewer: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    @State private var offset = CGSize.zero
    @State private var backgroundOpacity: CGFloat = 1.0
    @State private var page: Page
    @State private var dragStart: CGPoint?
    @State private var isHorizontalDragEnabled = false
    
    // use for showing image index at top
    @State private var pageIndex: Int
    
    @State private var showVideoPlayer: Bool = false
    @State private var hideOverlay: Bool = false
    @StateObject private var viewModel: MediaViewerViewModel
    @ObservedObject var viewConfig: AmityViewConfigController
    @State private var showScaleEffect: Bool = false
    @State private var isZooming: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var showAltTextComponent: Bool = false
    @State private var hasNavigatedToPostDetail: Bool = false
    
    private let medias: [AmityMedia]
    private let closeAction: (() -> Void)?
    private var url: URL? = nil
    private var showEditAction: Bool = false
    private let fileRepositoryManager = FileRepositoryManager()
    private let post: AmityPostModel?
    private let showViewParentPost: Bool
    
    private var canEditAltText: Bool {
        guard let post else { return false }
        
        let isImagePost = post.dataTypeInternal == .image
        let isImagePollPost = post.dataTypeInternal == .poll && (post.poll?.isImagePoll ?? false)
        
        return post.isOwner && (isImagePost || isImagePollPost)
    }
    
    private var hasBottomSheetOptions: Bool {
        // Get current media being displayed
        let currentMedia = page.index < medias.count ? medias[page.index] : nil
        
        // Don't show options if post is deleted or the current media is deleted
        if viewModel.isPostDeleted || (currentMedia != nil && viewModel.isMediaDeleted(currentMedia!)) {
            return false
        }
        
        guard let _ = post else { return false }
        
        return canEditAltText || showViewParentPost
    }
    
    init(medias: [AmityMedia], startIndex: Int, viewConfig: AmityViewConfigController, closeAction: (() -> Void)?, showEditAction: Bool = false, post: AmityPostModel? = nil, showViewParentPost: Bool = true) {
        self._page = State(initialValue: Page.withIndex(startIndex))
        self._pageIndex = State(initialValue: startIndex + 1)
        self.medias = medias
        self.closeAction = closeAction
        self.viewConfig = viewConfig
        self.showEditAction = showEditAction
        self.post = post
        self.showViewParentPost = showViewParentPost
        self._viewModel = StateObject(wrappedValue: MediaViewerViewModel(post: post))
    }
    
    init(url: URL?, viewConfig: AmityViewConfigController, closeAction: (() -> Void)?) {
        self._page = State(initialValue: Page.withIndex(0))
        self._pageIndex = State(initialValue: 1)
        let imageData = AmityImageData()
        imageData.fileURL = url?.absoluteString ?? ""
        self.medias = [AmityMedia(state: .downloadableImage(imageData: imageData, placeholder: UIImage()), type: .image)]
        self.closeAction = closeAction
        self.viewConfig = viewConfig
        self.post = nil
        self.showViewParentPost = true
        self._viewModel = StateObject(wrappedValue: MediaViewerViewModel(post: nil))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(backgroundOpacity)
                    .transition(.opacity)
                    .isHidden(!showScaleEffect)
                
                Pager(page: page, data: medias, id: \.id) { media in
                    ZoomableScrollView(isZooming: $isZooming, isZoomable: media.type == .image) {
                        ZStack {
                            // Create a properly centered placeholder with maximum height using solid theme color
                            let emptyView = GeometryReader { geometry in
                                Color(viewConfig.theme.baseColorShade4) // Use the theme color directly as a solid color
                                    .frame(maxWidth: geometry.size.width, maxHeight: 480)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                            }
                            
                            
                            if media.type == .video {
                                if let urlStr = media.video?.getVideo(resolution: .original) {
                                    if let url = URL(string: urlStr) {
                                        AmityCustomMediaPlayer(url: url, onBackgroundTap: { isHiding in
                                            withAnimation {
                                                hideOverlay = isHiding
                                            }
                                        })
                                    }
                                } else {
                                    if let url = URL(string: media.video?.fileURL ?? "") {
                                        AmityCustomMediaPlayer(url: url, onBackgroundTap: { isHiding in
                                            hideOverlay = isHiding
                                            withAnimation {
                                                hideOverlay = isHiding
                                            }
                                        })
                                    }
                                }
                            } else {
                                
                                // Media content layer
                                Group {
                                    /// If the media is local file, it will load from local file path.
                                    /// When MediaViewer is used to preview attached medias in AmityComposePage, media will have localUrl.
                                    if let url = media.localUrl {
                                        Image(uiImage: media.type == .image ?  UIImage(contentsOfFile: url.path) ?? UIImage() : media.generatedThumbnailImage ?? UIImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .adaptiveVerticalPadding(top: 35, bottom: 35)
                                    } else if let url = media.getImageURL() {
                                        URLImage(url, empty: {
                                            emptyView
                                        }, inProgress: {_ in
                                            emptyView
                                        },
                                        failure: {_, _ in
                                            emptyView
                                        }, content: { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        })
                                        .environment(\.urlImageOptions, URLImageOptions.amityOptions)
                                        .adaptiveVerticalPadding(top: 35, bottom: 35)
                                    } else {
                                        // Add placeholder for missing image URLs - properly centered
                                        emptyView
                                    }
                                }
                                .opacity((viewModel.isPostDeleted || viewModel.isMediaDeleted(media)) ? 0 : 1) // Hide when post or media is deleted
                            }
                            
                            ZStack {
                                Color.black
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // Message and icon
                                VStack(spacing: 16) {
                                    Image(AmityIcon.imageNotAvailableIcon.getImageResource())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(size: CGSize(width: 60, height: 60))
                                    
                                    Text(media.type == .image ? "This photo is no longer available." : "This video is no longer available.")
                                        .applyTextStyle(.title(.white))
                                }
                            }
                            .opacity((viewModel.isPostDeleted || viewModel.isMediaDeleted(media)) ? 1 : 0)
                        }
                    }
                    .applyIf(media.getAltText() != nil) {
                        $0
                            .accessibility(children: .ignore, labelKey: "Photo \(pageIndex) of \(medias.count): \(media.getAltText()!)")
                            .accessibilityHint("Swipe to move between images")
                            .accessibilityScrollAction { edge in
                                switch edge {
                                case .leading:
                                    page.update(.next)
                                    UIAccessibility.post(notification: .announcement, argument: "Photo \(pageIndex) of \(medias.count): \(media.getAltText()!)")
                                case .trailing:
                                    page.update(.previous)
                                    UIAccessibility.post(notification: .announcement, argument: "Photo \(pageIndex) of \(medias.count): \(media.getAltText()!)")
                                default: break
                                }
                            }
                    }
                }
                .allowsDragging(!isZooming)
                .sensitivity(.high)
                .delaysTouches(true)
                .onPageChanged({ index in
                    pageIndex = index + 1
                })
                .draggingAnimation(.custom(animation: .easeIn(duration: 0.05)))
                .background(Color.clear)
                .scaleEffect(showScaleEffect ? 1.0 : 0.0)
                .onAppear {
                    if !hasNavigatedToPostDetail {
                        withAnimation(.bouncy(duration: 0.3)) {
                            showScaleEffect = true
                        }
                    } else {
                        // When returning from post detail, show immediately without animation
                        showScaleEffect = true
                    }
                }
                .onDisappear {
                    // Only reset if we're actually closing the MediaViewer, not navigating
                    if !hasNavigatedToPostDetail {
                        showScaleEffect = false
                    }
                    
                    // Remove notification observers
                    viewModel.removeNotificationObservers()
                }
                .offset(offset)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { gesture in
                            guard !isZooming else { return }
                            
                            if dragStart == nil {
                                dragStart = gesture.startLocation
                            }
                            guard let dragStart else { return }
                            
                            let verticalDrag = abs(gesture.location.y - dragStart.y)
                            if verticalDrag > 60  {
                                isHorizontalDragEnabled = true
                            }
                            
                            // Only enable horizontal drag if vertical movement exceeds threshold
                            if isHorizontalDragEnabled {
                                withAnimation(.easeIn(duration: 0.05)) {
                                    self.offset = gesture.translation
                                    self.updateOpacity(for: gesture.translation.height, maxHeight: geometry.size.height)
                                }
                            }
                        }
                        .onEnded { _ in
                            guard !isZooming else { return }
                            
                            withAnimation(.easeIn(duration: 0.05)) {
                                guard backgroundOpacity > 0.65 else {
                                    
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        showScaleEffect.toggle()
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withoutAnimation {
                                            closeAction?()
                                        }
                                    }
                                    return
                                }
                                
                                self.dragStart = nil
                                self.isHorizontalDragEnabled = false
                                self.offset = .zero
                                self.backgroundOpacity = 1.0 // Reset opacity when drag ends
                            }
                        }
                )
                
                ZStack(alignment: .center) {
                    HStack(spacing: 0) {
                        Image(AmityIcon.circleCloseIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(size: CGSize(width: 32, height: 32))
                            .onTapGesture {
                                withoutAnimation {
                                    closeAction?()
                                }
                            }
                        Spacer()
                        // Show three-dot menu if there are any options available
                        if hasBottomSheetOptions {
                            Image(AmityIcon.meetballIcon.getImageResource())
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color.white)
                                .aspectRatio(contentMode: .fit)
                                .frame(size: CGSize(width: 18, height: 28))
                                .onTapGesture {
                                    showBottomSheet.toggle()
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    Text("\(pageIndex) / \(page.totalPages)")
                        .applyTextStyle(.title(.white))
                        .isHidden(page.totalPages == 1)
                }
                .adaptiveVerticalPadding(top: 20)
                .padding(.bottom, 15)
                .background(Color.black.opacity(0.5))
                .transition(.opacity.combined(with: .scale))
                .isHidden(!showScaleEffect)
                .opacity(hideOverlay ? 0 : 1) // Hide it when video player is shown
                .opacity(backgroundOpacity == 1 ? 1 : 0) // Hide it when dragging
            }
        }
        .background(ClearBackgroundView())
        .ignoresSafeArea(.all)
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor), sheetContent: {
            bottomSheetView
        })
        .sheet(isPresented: $showAltTextComponent) {
            let media = medias[page.index]
            if let imageData = media.image {
                let altText = media.getAltText(hasDefault: false)
                AmityAltTextConfigComponent(mode: .edit(altText ?? "", .image(imageData)), result: { altText in
                    media.altText = altText
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.altTextUpdated.localizedString)
                })
            }
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoURL = viewModel.videoURL {
                AVPlayerView(url: videoURL)
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    private var bottomSheetView: some View {
            VStack(spacing: 0) {
                // Get current media being displayed
                let currentMedia = page.index < medias.count ? medias[page.index] : nil
                let isCurrentMediaDeleted = currentMedia != nil && viewModel.isMediaDeleted(currentMedia!)
                
                if showViewParentPost {
                    BottomSheetItemView(icon: AmityIcon.viewPostIcon.getImageResource(), text: "View original post")
                        .onTapGesture {
                            showBottomSheet.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                goToPostDetailPage()
                            }
                        }
                }
                
                if canEditAltText {
                    BottomSheetItemView(icon: AmityIcon.editCommentIcon.getImageResource(), text: "Edit alt text")
                        .onTapGesture {
                            showBottomSheet.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                showAltTextComponent.toggle()
                            }
                        }
                }
            }
            .padding(.bottom, 32)
        }
    
    private func updateOpacity(for yOffset: CGFloat, maxHeight: CGFloat) {
        let maximumDragDistance: CGFloat = 400
        let normalizedOffset = max(0, min(abs(yOffset) / maximumDragDistance, 1.0))
        self.backgroundOpacity = Double(1.0 - normalizedOffset)
    }
    
    private func goToPostDetailPage() {
        guard let post else { return }
        
        // Mark that we're navigating to post detail
        hasNavigatedToPostDetail = true
        
        let postDetailPage = AmityPostDetailPage(post: post.object, context: nil)
        let controller = AmitySwiftUIHostingController(rootView: postDetailPage)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}

class MediaViewerViewModel: ObservableObject {
    var videoURL: URL?
    @Published var isPostDeleted: Bool = false
    @Published var shouldDismiss: Bool = false
    
    // Track deleted file IDs
    @Published var deletedFileIds: Set<String> = []
    
    private var post: AmityPostModel?
    
    // Check if a specific media is deleted
    func isMediaDeleted(_ media: AmityMedia) -> Bool {
        if media.type == .image {
            if let fileId = media.image?.fileId {
                return deletedFileIds.contains(fileId)
            }
        } else {
            if let fileId = media.video?.fileId {
                return deletedFileIds.contains(fileId)
            }
        }
        return false
    }
    
    init(post: AmityPostModel? = nil) {
        self.post = post
        setupNotificationObservers()
    }
    
    func setupNotificationObservers() {
        
        NotificationCenter.default.addObserver(
            forName: .didPostLocallyDeleted,
            object: nil,
            queue: .main) { [weak self] notification in
                self?.deletedFileIds = Set(self?.post?.medias.compactMap({$0.image?.fileId}) ?? [])
            }
        
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
    }
    
    // Remove all notification observers
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .didPostDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostLocallyDeleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostImageUpdated, object: nil)
    }
    
    deinit {
        removeNotificationObservers()
    }
}


struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    
    private var content: Content
    @Binding private var isZooming: Bool  // Add a binding for zooming state
    private var isZoomable: Bool
    
    init(isZooming: Binding<Bool>, isZoomable: Bool, @ViewBuilder content: () -> Content) {
        self._isZooming = isZooming
        self.isZoomable = isZoomable
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:) and zooming state
        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        // create a UIHostingController to hold our SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        hostedView.backgroundColor = .clear
        scrollView.addSubview(hostedView)
        
        context.coordinator.scrollView = scrollView
        if isZoomable {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
            scrollView.addGestureRecognizer(tapGesture)
        }
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isZooming: $isZooming, isZoomable: isZoomable, hostingController: UIHostingController(rootView: self.content))
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        @Binding var isZooming: Bool
        var isZoomable: Bool
        weak var scrollView: UIScrollView?
        
        init(isZooming: Binding<Bool>, isZoomable: Bool, hostingController: UIHostingController<Content>) {
            self._isZooming = isZooming
            self.isZoomable = isZoomable
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            isZoomable ? hostingController.view : nil
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Update the isZooming binding whenever the zoom scale changes
            isZooming = scrollView.zoomScale > 1.0
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer){
            guard let scrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)  // Reset to default zoom scale
            }
        }
    }
}
