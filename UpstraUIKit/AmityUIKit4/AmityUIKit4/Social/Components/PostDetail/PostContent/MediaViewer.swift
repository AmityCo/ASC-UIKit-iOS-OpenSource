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
    @State private var offset = CGSize.zero
    @State private var backgroundOpacity: CGFloat = 1.0
    @State private var page: Page
    
    // use for showing image index at top
    @State private var pageIndex: Int
    
    @State private var showVideoPlayer: Bool = false
    @StateObject private var viewModel = MediaViewerViewModel()
    @State private var showScaleEffect: Bool = false
    
    private let medias: [AmityMedia]
    private let closeAction: (() -> Void)?
    private var url: URL? = nil
    
    init(medias: [AmityMedia], startIndex: Int, closeAction: (() -> Void)?) {
        self._page = State(initialValue: Page.withIndex(startIndex))
        self._pageIndex = State(initialValue: startIndex + 1)
        self.medias = medias
        self.closeAction = closeAction
    }
    
    
    init(url: URL?, closeAction: (() -> Void)?) {
        self._page = State(initialValue: Page.withIndex(0))
        self._pageIndex = State(initialValue: 1)
        let imageData = AmityImageData()
        imageData.fileURL = url?.absoluteString ?? ""
        self.medias = [AmityMedia(state: .downloadableImage(imageData: imageData, placeholder: UIImage()), type: .image)]
        self.closeAction = closeAction
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(backgroundOpacity)
                    .transition(.opacity)
                    .isHidden(!showScaleEffect)
                
                Pager(page: page, data: medias, id: \.id) { media in
                    ZStack {
                        let emptyView = Color(hex: "#EBECEF").padding(.vertical, 100)
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
                        }
                        
                        if media.type == .video {
                            Image(AmityIcon.videoControlIcon.getImageResource())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .onTapGesture {
                        if media.type == .video {
                            let url: URL?
                            if let urlStr = media.video?.getVideo(resolution: .original) {
                                url = URL(string: urlStr)
                            } else {
                                url = URL(string: media.video?.fileURL ?? "")
                            }
                            
                            viewModel.videoURL = media.localUrl ?? url
                            showVideoPlayer.toggle()
                        }
                    }
                    
                }
                .allowsDragging(backgroundOpacity == 1.0)
                .sensitivity(.high)
                .onPageChanged({ index in
                    pageIndex = index + 1
                })
                .background(Color.clear)
                .scaleEffect(showScaleEffect ? 1.0 : 0.0)
                .onAppear {
                    withAnimation(.bouncy(duration: 0.3)) {
                        showScaleEffect.toggle()
                    }
                }
                .offset(offset)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { gesture in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if gesture.translation.height > 50 || gesture.translation.height < -50 {
                                    self.offset = gesture.translation
                                    self.updateOpacity(for: gesture.translation.height, maxHeight: geometry.size.height)
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeInOut(duration: 0.15)) {
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
                    }
                    .padding(.leading, 16)
                    
                    Text("\(pageIndex) / \(page.totalPages)")
                        .applyTextStyle(.title(.white))
                        .isHidden(page.totalPages == 1)
                }
                .adaptiveVerticalPadding(top: 20)
                .padding(.bottom, 15)
                .background(Color.black.opacity(0.5))
                .opacity(backgroundOpacity == 1.0 ? 1.0 : 0)
                .transition(.opacity.combined(with: .scale))
                .isHidden(!showScaleEffect)
            }
        }
        .background(ClearBackgroundView())
        .ignoresSafeArea(.all)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoURL = viewModel.videoURL {
                AVPlayerView(url: videoURL)
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    private func updateOpacity(for yOffset: CGFloat, maxHeight: CGFloat) {
        let maximumDragDistance: CGFloat = 400
        let normalizedOffset = max(0, min(abs(yOffset) / maximumDragDistance, 1.0))
        self.backgroundOpacity = Double(1.0 - normalizedOffset)
    }
}

class MediaViewerViewModel: ObservableObject {
    var videoURL: URL?
}
