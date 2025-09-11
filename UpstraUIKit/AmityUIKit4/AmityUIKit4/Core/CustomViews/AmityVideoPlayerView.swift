//
//  AmityVideoPlayerView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 24/7/2568 BE.
//

import SwiftUI
import AVKit

struct AmityVideoPlayerView: View {
    
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @Environment(\.presentationMode) private var presentationMode
    // Video properties
    private let url: URL
    private let autoPlay: Bool
    private let post: AmityPostModel?
    
    // Optional properties for the container
    private var cornerRadius: CGFloat = 0
    private let closeAction: (() -> Void)?
    
    // State variables
    @State private var isPlaying: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var hasNavigatedToPostDetail: Bool = false
    @StateObject private var viewModel: VideoPlayerViewModel
    
    private var showViewParentPost: Bool = true
    
    private var hasBottomSheetOptions: Bool {
        // Only show if we have a post and showViewParentPost is true
        // Don't show options if post is deleted or video is deleted
        if viewModel.isPostDeleted || viewModel.isVideoDeleted(url) {
            return false
        }
        return post != nil && showViewParentPost
    }
    
    init(url: URL,
         autoPlay: Bool = true,
         topRightButtonImage: UIImage? = nil,
         topRightButtonAction: (() -> Void)? = nil,
         post: AmityPostModel? = nil,
         closeAction: (() -> Void)? = nil) {
        self.url = url
        self.autoPlay = autoPlay
        self.post = post
        self.closeAction = closeAction
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(post: post))

    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AVPlayerView(
                url: url,
                autoPlay: autoPlay,
                post: post
            )
            .cornerRadius(cornerRadius)
            .overlay(
                ZStack(alignment: .top) {
                    if viewModel.isPostDeleted || viewModel.isVideoDeleted(url) {
                        Color.black
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        VStack {
                            // Close button in top left
                            HStack {
                                Image(AmityIcon.circleCloseIcon.getImageResource())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(size: CGSize(width: 32, height: 32))
                                    .onTapGesture {
                                        withoutAnimation {
                                            if let action = closeAction {
                                                action()
                                            } else {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                
                                Spacer()
                            }
                            .adaptiveVerticalPadding(top: 20)
                            .padding(.leading, 16)
                            
                            Spacer()
                            
                            // Error message in center
                            VStack(spacing: 16) {
                                Image(AmityIcon.videoNotAvailableIcon.getImageResource())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(size: CGSize(width: 60, height: 60))
                                
                                Text("This video is no longer available.")
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                    }
                }
            )
            
            Button(action: {
                showBottomSheet.toggle()
                pauseVideo()
            }) {
                Image(AmityIcon.meetballIcon.getImageResource())
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color.white)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 28)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .adaptiveVerticalPadding(top: 5)
            .padding(.trailing, 16)
            .ignoresSafeArea()
            .opacity(hasBottomSheetOptions && viewModel.showPostDetailButton ? 1 : 0)

        }
        .onAppear(perform: {
            self.isPlaying = autoPlay
        })
        .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(.systemBackground), sheetContent: {
            bottomSheetView
        })
        .onChange(of: showBottomSheet) { isShowing in
            if !isShowing && !hasNavigatedToPostDetail {
                playVideo()
            }
        }
    }
    
    // Bottom sheet view for additional options
    private var bottomSheetView: some View {
        VStack(spacing: 0) {
            if post != nil && showViewParentPost {
                BottomSheetItemView(icon: AmityIcon.viewPostIcon.getImageResource(), text: "View post")
                    .onTapGesture {
                        showBottomSheet.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            goToPostDetailPage()
                        }
                    }
            }
        }
        .padding(.bottom, 32)
    }
    
    // Navigation to post detail page
    func goToPostDetailPage() {
        guard let post = post else { return }
        
        // Mark that we're navigating to post detail
        hasNavigatedToPostDetail = true
        
        let postDetailPage = AmityPostDetailPage(post: post.object, context: nil)
        let controller = AmitySwiftUIHostingController(rootView: postDetailPage)
        host.controller?.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    // Function to pause the current video
    func pauseVideo() {
        NotificationCenter.default.post(
            name: .pauseVideo,
            object: nil,
            userInfo: ["url": url]
        )
    }
    
    // Function to play the current video
    func playVideo() {
        NotificationCenter.default.post(
            name: .playVideo,
            object: nil,
            userInfo: ["url": url]
        )
    }
    
}


extension Notification.Name {
    static let playVideo = Notification.Name("AmityUIKit.playVideo")
    static let pauseVideo = Notification.Name("AmityUIKit.pauseVideo")
}

class VideoPlayerViewModel: ObservableObject {
    @Published var isPostDeleted: Bool = false
    @Published var showPostDetailButton: Bool = false
    @Published var deletedFileIds: Set<String> = []
    
    private var post: AmityPostModel?
    
    func isVideoDeleted(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        let urlString = url.absoluteString
        
        return deletedFileIds.contains { fileId in
            return urlString.contains(fileId)
        }
    }
    
    init(post: AmityPostModel?) {
        setupNotificationObservers()
        self.post = post
    }
    
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .playerControlsVisibilityChanged,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let self = self else { return }
                if let info = notification.userInfo,
                   let isVisible = info["visible"] as? Bool {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.showPostDetailButton = isVisible
                    }
                }
            }
        
        NotificationCenter.default.addObserver(
            forName: .playerControlsWillFadeIn,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeIn(duration: 0.2)) {
                    self.showPostDetailButton = true
                }
            }
        
        NotificationCenter.default.addObserver(
            forName: .playerControlsWillFadeOut,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    self.showPostDetailButton = false
                }
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
        NotificationCenter.default.addObserver(
            forName: .didPostLocallyDeleted,
            object: nil,
            queue: .main) { [weak self] notification in
                self?.deletedFileIds = Set(self?.post?.medias.compactMap({$0.video?.fileId}) ?? [])
            }

    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .playerControlsVisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playerControlsWillFadeOut, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playerControlsWillFadeIn, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didPostImageUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
