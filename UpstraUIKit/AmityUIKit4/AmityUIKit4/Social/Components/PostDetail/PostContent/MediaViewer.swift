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
    
    // 1-based index of the frame the pager has settled on
    @State private var pageIndex: Int
    
    @StateObject private var viewModel: MediaViewerViewModel
    @ObservedObject var viewConfig: AmityViewConfigController
    @State private var showScaleEffect: Bool = false
    @State private var isZooming: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var showAltTextComponent: Bool = false
    @State private var hasNavigatedToPostDetail: Bool = false
    @State private var selectedProductTagMedia: AmityMedia?

    /// The audio choice for this player session. Held here because the per-page player's controller is
    /// a `@StateObject` recreated on every swipe, which would reset it. Starts unmuted.
    @State private var isPlayerMuted: Bool = false

    /// skip AuthHeader for Non-Amity hosts (e.g. customer S3)
    @State private var skipAuthHeader = false
    
    private let medias: [AmityMedia]
    private let closeAction: (() -> Void)?

    /// Reports the viewed frame live, so the carousel behind the viewer keeps pace. The composer
    /// deliberately does not wire this — it returns to the frame originally tapped.
    private let onIndexChanged: ((Int) -> Void)?
    private var url: URL? = nil
    private var showEditAction: Bool = false
    private let fileRepositoryManager = FileRepositoryManager()
    private let post: AmityPostModel?
    private let showViewParentPost: Bool
    private let pageId: PageId?

    private let onDelete: (() -> Void)?
    private let saveImageURL: URL?

    /// A single-attachment post still reads `1 / 1`. Viewers handed one media out of a larger set
    /// (profile media grid), or no set at all (chat bubble, avatar, poll image), show no counter.
    private let alwaysShowsCounter: Bool

    @State private var bottomBarToastMessage: String = ""
    @State private var bottomBarToastStyle: ToastStyle = .success
    @State private var bottomBarShowToast: Bool = false

    private var showBottomActionBar: Bool {
        onDelete != nil || saveImageURL != nil
    }
    
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
    

    init(medias: [AmityMedia], startIndex: Int, viewConfig: AmityViewConfigController, closeAction: (() -> Void)?, showEditAction: Bool = false, post: AmityPostModel? = nil, showViewParentPost: Bool = true, pageId: PageId? = nil, alwaysShowsCounter: Bool = false, onIndexChanged: ((Int) -> Void)? = nil) {
        self._page = State(initialValue: Page.withIndex(startIndex))
        self._pageIndex = State(initialValue: startIndex + 1)
        self.medias = medias
        self.closeAction = closeAction
        self.onIndexChanged = onIndexChanged
        self.viewConfig = viewConfig
        self.showEditAction = showEditAction
        self.post = post
        self.showViewParentPost = showViewParentPost
        self.pageId = pageId
        self.onDelete = nil
        self.saveImageURL = nil
        self.alwaysShowsCounter = alwaysShowsCounter
        self._viewModel = StateObject(wrappedValue: MediaViewerViewModel(post: post))
    }

    init(url: URL?, viewConfig: AmityViewConfigController, closeAction: (() -> Void)?, pageId: PageId? = nil, saveImageURL: URL? = nil, onDelete: (() -> Void)? = nil) {
        self._page = State(initialValue: Page.withIndex(0))
        self._pageIndex = State(initialValue: 1)
        let imageData = AmityImageData()
        imageData.fileURL = url?.absoluteString ?? ""
        self.medias = [AmityMedia(state: .downloadableImage(imageData: imageData, placeholder: UIImage()), type: .image)]
        self.closeAction = closeAction
        self.onIndexChanged = nil
        self.viewConfig = viewConfig
        self.post = nil
        self.showViewParentPost = true
        self.pageId = pageId
        self.onDelete = onDelete
        self.saveImageURL = saveImageURL ?? url
        self.alwaysShowsCounter = false
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
                                let frameNumber = (medias.firstIndex(of: media) ?? 0) + 1
                                // No `post` in the composer, and the player takes an optional one.
                                AmityPostMediaVideoPlayer(
                                        pageId: pageId,
                                        post: post,
                                        playerType: .video(media),
                                        hideActionMenu: !showViewParentPost,
                                        onClose: {
                                            withoutAnimation {
                                                closeAction?()
                                            }
                                        },
                                        frameIndex: frameNumber,
                                        frameTotal: medias.count,
                                        isMuted: $isPlayerMuted,
                                        isActive: frameNumber == pageIndex
                                    )
                                    .opacity((viewModel.isPostDeleted || viewModel.isMediaDeleted(media)) ? 0 : 1) // Hide when post or media is deleted
                                    .environmentObject(host)
                            } else {
                                
                                // Media content layer
                                Group {
                                    /// If the media is local file, it will load from local file path.
                                    /// When MediaViewer is used to preview attached medias in AmityComposePage, media will have localUrl.
                                    if let localImage = media.localUIImage {
                                        Image(uiImage: localImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .overlay(productTagBadge(for: media), alignment: .bottomTrailing)
                                            .adaptiveVerticalPadding(top: 35, bottom: 35)
                                    } else if let url = media.localUrl {
                                        Image(uiImage: media.type == .image ?  UIImage(contentsOfFile: url.path) ?? UIImage() : media.generatedThumbnailImage ?? UIImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .overlay(productTagBadge(for: media), alignment: .bottomTrailing)
                                            .adaptiveVerticalPadding(top: 35, bottom: 35)
                                    } else if let url = media.getImageURL() {
                                        URLImage(url, empty: {
                                            emptyView
                                        }, inProgress: {_ in
                                            emptyView
                                        },
                                        failure: { error, _ in
                                            emptyView
                                                .onAppear {
                                                    if !skipAuthHeader {
                                                        Log.warn("MediaViewer image load failed, retrying without auth header url=\(url.absoluteString) error=\(error)")
                                                        skipAuthHeader = true
                                                    } else {
                                                        Log.warn("MediaViewer image load failed url=\(url.absoluteString) error=\(error)")
                                                    }
                                                }
                                        }, content: { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .overlay(productTagBadge(for: media), alignment: .bottomTrailing)
                                        })
                                        .environment(\.urlImageOptions, skipAuthHeader ? URLImageOptions.defaultImageOptions : URLImageOptions.amityOptions)
                                        .id(skipAuthHeader)
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
                                    Image(media.type == .image ? AmityIcon.imageNotAvailableIcon.getImageResource() : AmityIcon.videoNotAvailableIcon.getImageResource())
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(size: CGSize(width: 60, height: 60))
                                    
                                    Text(media.type == .image ? AmityLocalizedStringSet.Social.photoNoLongerAvailable.localizedString : AmityLocalizedStringSet.Social.videoNoLongerAvailable.localizedString)
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
                    // Report the viewed frame live so the carousel behind the viewer keeps pace and
                    // is already settled on it when the fade-out dismiss reveals it.
                    onIndexChanged?(index)
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
                        Image(AmityIcon.closeIcon.getImageResource())
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(size: CGSize(width: 20, height: 20))
                            .foregroundColor(Color(viewConfig.defaultLightTheme.baseColor))
                            .circularBackground(radius: 24, color: Color(viewConfig.defaultLightTheme.baseColorShade4))
                            .frame(width: 32, height: 32, alignment: .leading)
                            .contentShape(Rectangle())
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
                        .isHidden(page.totalPages == 1 && !alwaysShowsCounter)
                }
                .adaptiveVerticalPadding(top: 20)
                .padding(.bottom, 15)
                .background(Color.black.opacity(0.5))
                .transition(.opacity.combined(with: .scale))
                .isHidden(!showScaleEffect || (medias[page.index].type == .video && !(viewModel.isPostDeleted || viewModel.isMediaDeleted(medias[page.index]))))
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
        .sheet(item: $selectedProductTagMedia) { media in
            let renderMode: ProductTagListRenderMode = media.type == .video ? .video : .image
            let component = AmityProductTagListComponent(
                productTags: media.produtTags,
                renderMode: renderMode,
                sourceId: post?.postId ?? ""
            )
            component
                .environmentObject(host)
                .halfSheetPresentation()
        }
        .overlay(bottomActionBar, alignment: .bottom)
        .showToast(isPresented: $bottomBarShowToast, style: bottomBarToastStyle, message: bottomBarToastMessage, bottomPadding: 80)
    }

    /// Overlaid on every image branch, not just the remote one: a composer attachment is a local
    /// image, so anchoring this to `URLImage` alone left the badge off the creation-state viewer.
    @ViewBuilder
    private func productTagBadge(for media: AmityMedia) -> some View {
        if !media.produtTags.isEmpty, !viewModel.isPostDeleted, !viewModel.isMediaDeleted(media) {
            AmityProductTagBadgeView(count: media.produtTags.count, icon: .productTagFilledIcon)
                .padding(.all, 12)
                .onTapGesture {
                    selectedProductTagMedia = media
                }
        }
    }

    @ViewBuilder
    private var bottomActionBar: some View {
        if showBottomActionBar {
            HStack {
                if onDelete != nil {
                    Button {
                        closeAction?()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onDelete?()
                        }
                    } label: {
                        Image(AmityIcon.trashBinWhiteIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(.white)
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .padding(12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if saveImageURL != nil {
                    Button(action: saveBottomBarImage) {
                        Image(AmityIcon.Chat.saveImageIcon.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(.white)
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .padding(12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func saveBottomBarImage() {
        guard let url = saveImageURL else { return }
        MessageMediaSaver.saveImage(from: url) { success in
            bottomBarToastStyle = success ? .success : .warning
            bottomBarToastMessage = success
                ? AmityLocalizedStringSet.Chat.SaveMedia.imageSuccess.localizedString
                : AmityLocalizedStringSet.Chat.SaveMedia.imageFailed.localizedString
            bottomBarShowToast = true
        }
    }
    
    private var bottomSheetView: some View {
            VStack(spacing: 0) {
                // Get current media being displayed
                let currentMedia = page.index < medias.count ? medias[page.index] : nil
                
                if showViewParentPost {
                    BottomSheetItemView(icon: AmityIcon.viewPostIcon.getImageResource(), text: AmityLocalizedStringSet.Social.socialViewPost.localizedString)
                        .onTapGesture {
                            showBottomSheet.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                goToPostDetailPage()
                            }
                        }
                }
                
                if canEditAltText {
                    BottomSheetItemView(icon: AmityIcon.editCommentIcon.getImageResource(), text: AmityLocalizedStringSet.Social.altTextEditTitle.localizedString)
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
                guard let self else { return }
                // Another post being deleted must not blank out this viewer
                guard let deletedPostId = notification.userInfo?["postId"] as? String,
                      deletedPostId == post?.postId else { return }

                isPostDeleted = true
                // A video carries its file id on `video`, an image on `image`. Collecting only the
                // image ids left every video media unmatched in isMediaDeleted.
                deletedFileIds = Set(post?.medias.compactMap({ $0.image?.fileId ?? $0.video?.fileId }) ?? [])
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
