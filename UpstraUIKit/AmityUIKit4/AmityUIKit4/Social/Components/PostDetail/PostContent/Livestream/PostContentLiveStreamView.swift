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
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Spacer()
                            
                            // "RECORDED" badge moved to top-right
                            Text(post.livestreamState.badgeTitle)
                                .applyTextStyle(.captionBold(.white))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(post.livestreamState == .live ? Color(UIColor(hex: "FF305A")) : Color.black.opacity(0.5))
                                .blurBackground(style: .regular)
                                .cornerRadius(4, corners: .allCorners)
                                .padding(12)
                        }
                        
                        Spacer()
                        
                        // Tag badge on bottom-right - tappable to open product tag list
                        let childPost = post.childrenPosts.first
                        let productCount = childPost?.getMediaProductTags().count ?? 0
                        
                        if productCount > 0 {
                            HStack {
                                Spacer()
                                
                                AmityProductTagBadgeView(count: productCount)
                                    .padding(12)
                                    .onTapGesture {
                                        showProductTagSheet = true
                                    }
                            }
                        }
                    }
                    
                    Image(AmityIcon.videoControlIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .isHidden(post.livestreamState == .idle)
                    
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
        .onTapGesture {
            guard !isStreamBanned else { return }
            
            switch post.livestreamState {
            case .live, .recorded:
                let livestreamPlayerPage = AmityLivestreamPlayerPage(post: post.object)
                let hostController = AmitySwiftUIHostingNavigationController(rootView: livestreamPlayerPage)
                hostController.isNavigationBarHidden = true
                hostController.modalPresentationStyle = .overFullScreen
                self.host.controller?.present(hostController, animated: true)
            default:
                break
            }
        }
        .sheet(isPresented: $showProductTagSheet) {
            productTagListSheet
        }
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
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension View {
    func blurBackground(style: UIBlurEffect.Style) -> some View {
        background(BlurView(style: style))
    }
}
