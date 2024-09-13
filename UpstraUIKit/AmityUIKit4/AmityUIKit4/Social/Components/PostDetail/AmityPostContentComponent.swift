//
//  AmityPostContentComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/3/24.
//

import SwiftUI
import AmitySDK
import LinkPresentation

public enum AmityPostContentComponentStyle {
    case feed
    case detail

}

public enum AmityPostCategory {
    case general
    case announcement
    case pin
}

public struct AmityPostContentComponent: AmityComponentView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    
    public var id: ComponentId {
        .postContentComponent
    }
    
    public let post: AmityPostModel
    @StateObject private var viewConfig: AmityViewConfigController
   
    @StateObject private var viewModel = AmityPostContentComponentViewModel()
    @State private var showReactionList: Bool = false
    @State private var showBottomSheet: Bool = false
    
    private let style: AmityPostContentComponentStyle
    private let category: AmityPostCategory
    private let hideMenuButton: Bool
    private let hideTarget: Bool
    private var onTapAction: (() -> Void)?

    public init(post: AmityPost, style: AmityPostContentComponentStyle = .feed, category: AmityPostCategory = .general, hideTarget: Bool = false, hideMenuButton: Bool = false, onTapAction: (() -> Void)? = nil, pageId: PageId? = nil) {
        self.post = AmityPostModel(post: post)
        self.style = style
        self.hideMenuButton = hideMenuButton
        self.hideTarget = hideTarget
        self.onTapAction = onTapAction
        self.pageId = pageId
        self.category = category
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .postContentComponent))
    }
    
    
    public var body: some View {
        VStack(spacing: 16) {
            postHeaderView(post)
            postContentView(post)
                .isHidden(viewConfig.isHidden(elementId: .postContent), remove: true)
            postEngagementView(post)
            postEngagementActionView(post)
                .contentShape(Rectangle())
                .padding(.top, -4)
        }
        .contentShape(Rectangle())
        .padding(.bottom, 12)
        .onTapGesture {
            onTapAction?()
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private func postHeaderView(_ post: AmityPostModel) -> some View {
        
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Featured")
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                
            }
            .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
            .cornerRadius(4, corners: [.topRight, .bottomRight])
            .padding(.vertical, 8)
            .isHidden(category != .announcement || viewConfig.isHidden(elementId: .announcementBadge))

            HStack(spacing: 8) {
                AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: URL(string: post.postedUser?.avatarURL ?? ""))
                    .frame(size: CGSize(width: 32.0, height: 32.0))
                    .clipShape(Circle())
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(post.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .layoutPriority(1)
                            .onTapGesture {
                                let context = AmityPostContentComponentBehavior.Context(component: self)
                                AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToUserProfilePage(context: context)
                            }
                        
                        if post.isFromBrand {
                            Image(AmityIcon.brandBadge.imageResource)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .padding(.leading, -4)
                                .opacity(post.isFromBrand ? 1 : 0)
                        }
                        
                        if let _ = post.targetCommunity, !hideTarget {
                            HStack(spacing: 8) {
                                Image(AmityIcon.arrowIcon.getImageResource())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(size: CGSize(width: 10, height: 10))
                                
                                communityNameLabel
                            }
                        }
                        
                        // If user posts to his own feed, we hide this part
                        if post.postTargetType == .user && post.postedUserId != post.targetId {
                            HStack(spacing: 8) {
                                Image(AmityIcon.arrowIcon.getImageResource())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(size: CGSize(width: 10, height: 10))
                                
                                userNameLabel
                            }
                        }
                    }
                    
                    HStack(spacing: 4) {
                        if post.isModerator && !viewConfig.isHidden(elementId: .moderatorBadge) {
                            let moderatorIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .moderatorBadge, key: "icon", of: String.self) ?? "")
                            let moderatorTitle = viewConfig.getConfig(elementId: .moderatorBadge, key: "text", of: String.self) ?? ""
                            HStack(spacing: 3) {
                                Image(moderatorIcon)
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .padding(.leading, 6)
                                Text(moderatorTitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                                    .padding(.trailing, 6)
                            }
                            .frame(height: 20)
                            .background(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                            .clipShape(RoundedCorner(radius: 10))
                            
                            Text("•")
                                .font(.system(size: 13))
                                .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                        }
                        
                        Text("\(post.timestamp)\(post.isEdited ? " (edited)" : "")")
                            .font(.system(size: 13))
                            .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                            .isHidden(viewConfig.isHidden(elementId: .timestamp))
                        
                    }
                    
                }
                
                Spacer()
                
                let pinBadge = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .pinBadge, key: "image", of: String.self) ?? "")
                Image(pinBadge)
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                    .frame(width: 20, height: 20)
                    .isHidden(category != .pin || viewConfig.isHidden(elementId: .pinBadge))
                
                if !hideMenuButton {
                    let bottomSheetHeight = calculateBottomSheetHeight(post: post)
                    Button(action: {
                        showBottomSheet.toggle()
                    }, label: {
                        let menuIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .menuButton, key: "icon", of: String.self) ?? "")
                        Image(menuIcon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .frame(width: 24, height: 24)
                    })
                    .buttonStyle(BorderlessButtonStyle())
                    .isHidden(viewConfig.isHidden(elementId: .menuButton))
                    .bottomSheet(isShowing: $showBottomSheet, height: .fixed(bottomSheetHeight), backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                        PostBottomSheetView(isShown: $showBottomSheet, post: post, editPostActionCompletion: {
                            showBottomSheet.toggle()
                            
                            // Dismiss bottomsheet
                            host.controller?.dismiss(animated: false)
                            
                            let editOption = AmityPostComposerOptions.editOptions(post: post)
                            let view = AmityPostComposerPage(options: editOption)
                            let controller = AmitySwiftUIHostingController(rootView: view)
                            
                            let navigationController = UINavigationController(rootViewController: controller)
                            navigationController.modalPresentationStyle = .fullScreen
                            navigationController.navigationBar.isHidden = true
                            host.controller?.present(navigationController, animated: true)
                        })
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12))
        }
    }
    
    
    @ViewBuilder
    private func postContentView(_ post: AmityPostModel) -> some View {
        VStack(spacing: 16) {
            switch post.dataTypeInternal {
            case .text:
                postContentTextView()
                    .onAppear {
                        Task { @MainActor in
                            await viewModel.getPreviewlinkData(post: post)
                        }
                    }
                
                postPreviewLinkView()
                
            case .image, .video:
                postContentTextView()
                
                PostContentMediaView(post: post)
                .frame(height: 328)
                .clipShape(RoundedCorner(radius: 8))
                
            case .file:
                EmptyView()
           
            case .poll:
                EmptyView()
                
            case .liveStream:
                postContentTextView()
                
                PostContentLiveStreamView(post: post)
                    .frame(height: 328)
                    .clipShape(RoundedCorner(radius: 8))
                
            case .unknown:
                EmptyView()
            }
        }
        .padding([.leading, .trailing], 16)
    }
    
    
    @ViewBuilder
    private func postContentTextView() -> some View {
        if !post.text.isEmpty {
            ExpandableText(post.text, metadata: post.metadata, mentionees: post.mentionees)
                .lineLimit(8)
                .moreButtonText("...See more")
                .font(.system(size: 15))
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .attributedColor(viewConfig.theme.primaryColor)
                .moreButtonColor(Color(viewConfig.theme.primaryColor))
                .expandAnimation(.easeOut(duration: 0.25))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    @ViewBuilder
    private func postPreviewLinkView() -> some View {
        if let url = viewModel.previewLinkData.url {
            VStack(alignment: .leading, spacing: 0) {
                let fallbackImage = viewModel.previewLinkData.metadata == nil ? AmityIcon.previewLinkErrorIcon : AmityIcon.previewLinkDefaultIcon
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 240)
                    .overlay(
                        previewLinkImageView(viewModel.previewLinkData.image, fallback: fallbackImage.getImage() ?? UIImage())
                            .isHidden(!viewModel.previewLinkData.loaded)
                    )
                    .clipped()
                    .shimmering(active: !viewModel.previewLinkData.loaded)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !viewModel.previewLinkData.loaded {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 180, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 160, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                    } else {
                        let urlText = viewModel.previewLinkData.metadata?.url?.host ?? "Preview not available"
                        let titleText = viewModel.previewLinkData.metadata?.title ?? "Please make sure the URL is correct and try again."
                        let urlFont = viewModel.previewLinkData.metadata?.url?.host == nil ? Font.system(size: 15.0, weight: .semibold) : Font.system(size: 14.0)
                        let titleFont = viewModel.previewLinkData.metadata?.url?.host == nil ? Font.system(size: 15.0) : Font.system(size: 16.0, weight: .semibold)
                        let urlTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade1)
                        let titleTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColorShade1) : Color(viewConfig.theme.baseColor)
                        
                        Text(urlText)
                            .font(urlFont)
                            .lineLimit(1)
                            .foregroundColor(urlTextColor)
                        
                        Text(titleText)
                            .font(titleFont)
                            .lineLimit(2)
                            .foregroundColor(titleTextColor)
                    }
                }
                .padding([.leading, .trailing], 12)
                .padding([.bottom, .top], 14)
            }
            .cornerRadius(8.0)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.open(url)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 0.4)
            )
        }
    }
    
    
    @ViewBuilder
    private func previewLinkImageView(_ image: UIImage?, fallback: UIImage) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(uiImage: fallback)
                .frame(width: 50, height: 50)
                .scaledToFit()
        }
    }
    
    
    @ViewBuilder
    private func postEngagementView(_ post: AmityPostModel) -> some View {
        if style == .detail {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Group {
                        Image(AmityIcon.likeReactionIcon.getImageResource())
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                            .isHidden(post.reactionsCount == 0, remove: true)
                        
                        Text("\(post.reactionsCount.formattedCountString) \(post.reactionsCount == 1 ? "like" : "likes")")
                            .font(.system(size: 13))
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    }
                    .onTapGesture {
                        showReactionList.toggle()
                    }
                    
                    Spacer()
                    
                    Text("\(post.allCommentCount.formattedCountString) \(post.allCommentCount == 1 ? "comment" : "comments")")
                        .font(.system(size: 13))
                        .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                }
                .frame(height: 20)
            }
            .padding([.leading, .trailing], 16)
            .sheet(isPresented: $showReactionList) {
                AmityReactionList(post: post.object, pageId: pageId)
            }
        }
    }
    
    
    @ViewBuilder
    private func postEngagementActionView(_ post: AmityPostModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            Text(AmityLocalizedStringSet.Social.nonMemberReactPostMessage.localizedString)
                .font(.system(size: 15))
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade2))
                .isHidden(self.post.targetCommunity?.isJoined ?? true || viewConfig.isHidden(elementId: .nonMemberSection))
            
            HStack(spacing: 4) {
                Button(feedbackStyle: .light, action: {
                    Task { @MainActor in
                        if post.isLiked {
                            try await viewModel.removeReaction(id: post.postId)
                        } else {
                            try await viewModel.addReaction(id: post.postId)
                        }
                        
                        /// Send didPostReacted event to update global feed data source
                        /// This event is observed in PostFeedViewModel
                        NotificationCenter.default.post(name: .didPostReacted, object: post.object)
                    }
                }) {
                    let reactionIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .reactionButton, key: "icon", of: String.self) ?? "")
                    let reactionTitle = viewConfig.getConfig(elementId: .reactionButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(post.isLiked ? AmityIcon.likeReactionIcon.getImageResource() : reactionIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        if style == .feed {
                            Text(post.reactionsCount == 0 ? "0" : "\(post.reactionsCount.formattedCountString)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(post.isLiked ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade2))
                        } else if style == .detail {
                            Text(reactionTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(post.isLiked ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade2))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .isHidden(viewConfig.isHidden(elementId: .reactionButton), remove: true)
                
                Button(feedbackStyle: .light, action: {
                    onTapAction?()
                }) {
                    let commentIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .commentButton, key: "icon", of: String.self) ?? "")
                    let commentTitle = viewConfig.getConfig(elementId: .commentButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(commentIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        
                            if style == .feed {
                            Text(post.allCommentCount == 0 ? "0" : "\(post.allCommentCount)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        } else if style == .detail {
                            Text(commentTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
                .isHidden(viewConfig.isHidden(elementId: .commentButton), remove: true)
                
                Spacer()
                
                Button(feedbackStyle: .light, action: {}) {
                    let shareIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .shareButton, key: "icon", of: String.self) ?? "")
                    let shareTitle = viewConfig.getConfig(elementId: .shareButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(shareIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        Text(shareTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .isHidden(viewConfig.isHidden(elementId: .shareButton), remove: true)
            }
            .isHidden(!(self.post.targetCommunity?.isJoined ?? true))
        }
        .padding([.leading, .trailing], 16)
    }
    
    
    func calculateBottomSheetHeight(post: AmityPostModel) -> CGFloat {
                
        let baseBottomSheetHeight: CGFloat = 68
        let itemHeight: CGFloat = 48
        let additionalItems = [
            true,  // Always add one item
            post.hasModeratorPermission || post.isOwner,
        ].filter { $0 }
        
        let additionalHeight = CGFloat(additionalItems.count) * itemHeight
        
        return baseBottomSheetHeight + additionalHeight
    }
}

extension AmityPostContentComponent {
    
    @ViewBuilder
    var communityNameLabel: some View {
        HStack(spacing: 8) {
            if !post.isTargetPublicCommunity {
                Image(AmityIcon.getImageResource(named: "lockBlackIcon"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            
            Text(post.targetCommunity?.displayName ?? "Unknown")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .layoutPriority(1)
                .onTapGesture {
                    let context = AmityPostContentComponentBehavior.Context(component: self)
                    AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToCommunityProfilePage(context: context)
                }
            
            if post.isTargetOfficialCommunity {
                let verifiedBadgeIcon = AmityIcon.getImageResource(named: "verifiedBadge")
                Image(verifiedBadgeIcon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 16, height: 16)
                    .isHidden(viewConfig.isHidden(elementId: .communityOfficialBadge))
            }
        }
    }
    
    @ViewBuilder
    var userNameLabel: some View {
        HStack(spacing: 8) {
            
            Text(post.targetUser?.displayName ?? "Unknown")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .layoutPriority(1)
                .onTapGesture {
                    let context = AmityPostContentComponentBehavior.Context(component: self)
                    AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToCommunityProfilePage(context: context)
                }
        }
    }

}


class AmityPostContentComponentViewModel: ObservableObject {
    private let reactionManager = ReactionManager()
    @Published var previewLinkData: (url: URL?, metadata: LPLinkMetadata?, image: UIImage?, loaded: Bool) = (nil, nil, nil, false)
    
    init() {}
    
    func addReaction(id: String) async throws {
        try await reactionManager.addReaction(.like, referenceId: id, referenceType: .post)
    }
    
    func removeReaction(id: String) async throws {
        try await reactionManager.removeReaction(.like, referenceId: id, referenceType: .post)
    }
    
    @MainActor
    func getPreviewlinkData(post: AmityPostModel) async {
        let urls = AmityPreviewLinkWizard.shared.detectLinks(input: post.text)
        
        guard urls.count > 0 else {
            previewLinkData.url = nil
            return
        }
        
        previewLinkData.loaded = false
        previewLinkData.url = urls[0]
        previewLinkData.metadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urls[0])
        previewLinkData.loaded = true
        
        previewLinkData.metadata?.imageProvider?.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] image, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    self.previewLinkData.image = image
                }
            }
        })
    }
}
