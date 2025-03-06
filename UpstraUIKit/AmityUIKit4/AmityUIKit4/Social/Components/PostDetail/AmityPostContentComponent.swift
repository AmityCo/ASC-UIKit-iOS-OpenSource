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
    // Note: Announcement & global featured post is similar. `announcement` is used in case of community feed whereas `global` is used for global feed.
    case announcement
    case global
    case pin
    case pinAndAnnouncement
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
    @State private var showEditAlert: Bool = false
    
    private let style: AmityPostContentComponentStyle
    private let category: AmityPostCategory
    private let hideMenuButton: Bool
    private let hideTarget: Bool
    private var onTapAction: ((AmityPostContentComponent.Context?) -> Void)?
    private let context: AmityPostContentComponent.Context?
    
    public init(post: AmityPost, style: AmityPostContentComponentStyle = .feed, category: AmityPostCategory = .general, hideTarget: Bool = false, hideMenuButton: Bool = false, onTapAction: ((AmityPostContentComponent.Context?) -> Void)? = nil, pageId: PageId? = nil) {
        self.post = AmityPostModel(post: post)
        self.style = style
        self.hideMenuButton = hideMenuButton
        self.hideTarget = hideTarget
        self.onTapAction = onTapAction
        self.pageId = pageId
        self.category = category
        self.context = nil
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .postContentComponent))
    }
    
    // Convenience Initializer. You can pass context to this component so that it can render the correct state. One usage of context is to show poll results when user taps on
    // see results button from Feed and we open post detail page with poll post results.
    public init(post: AmityPost, style: AmityPostContentComponentStyle = .feed, context: AmityPostContentComponent.Context, onTapAction: ((AmityPostContentComponent.Context?) -> Void)? = nil, pageId: PageId? = nil) {
        self.post = AmityPostModel(post: post)
        self.style = style
        self.hideMenuButton = context.hideMenuButton
        self.hideTarget = context.hidePostTarget
        self.onTapAction = onTapAction
        self.pageId = pageId
        self.category = context.category
        self.context = context
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
            let context = AmityPostContentComponent.Context(category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton)
            onTapAction?(context)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private func postHeaderView(_ post: AmityPostModel) -> some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            let isBadgeVisible = category == .announcement || category == .global || category == .pinAndAnnouncement
            HStack {
                Text(AmityLocalizedStringSet.Social.featuredPostBadge.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.defaultLightTheme.baseColor)))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                
            }
            .background(Color(viewConfig.theme.secondaryColor.blend(.shade4)))
            .cornerRadius(5, corners: [.topRight, .bottomRight])
            .padding(.top, 8)
            .padding(.bottom, 2)
            .isHidden(!isBadgeVisible || viewConfig.isHidden(elementId: .announcementBadge))
            .accessibilityIdentifier(AccessibilityID.Social.PostContent.announcementBadge)
            
            HStack(spacing: 8) {
                AmityUserProfileImageView(displayName: post.postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: post.postedUser?.avatarURL ?? ""))
                    .frame(size: CGSize(width: 32.0, height: 32.0))
                    .clipShape(Circle())
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .onTapGesture {
                        goToUserProfilePage(post.postedUserId)
                    }
                
                VStack(alignment: .leading, spacing: 3) {
                    // Title
                    HStack(spacing: 8) {
                        authorDisplayNameLabel
                            .layoutPriority(1)
                        
                        if let _ = post.targetCommunity, !hideTarget {
                            Image(AmityIcon.arrowIcon.getImageResource())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(size: CGSize(width: 10, height: 10))
                            
                            communityNameLabel
                                .layoutPriority(1)
                        }
                        
                        // If user posts to his own feed, we hide this part
                        if post.postTargetType == .user && post.postedUserId != post.targetId {
                            Image(AmityIcon.arrowIcon.getImageResource())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(size: CGSize(width: 10, height: 10))
                            
                            targetUserNameLabel
                                .layoutPriority(1)
                        }
                    }
                    
                    // Moderator Badge
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
                                    .applyTextStyle(.captionSmall(Color(viewConfig.theme.primaryColor)))
                                    .padding(.trailing, 6)
                            }
                            .frame(height: 20)
                            .background(Color(viewConfig.theme.primaryColor.blend(.shade3)))
                            .clipShape(RoundedCorner(radius: 10))
                            .accessibilityIdentifier(AccessibilityID.Social.PostContent.moderatorBadge)
                            
                            Text("•")
                                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                        }
                        
                        Text("\(post.timestamp)\(post.isEdited ? " (edited)" : "")")
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                            .isHidden(viewConfig.isHidden(elementId: .timestamp))
                            .accessibilityIdentifier(AccessibilityID.Social.PostContent.timestamp)
                        
                    }
                    
                }
                
                Spacer()
                
                let pinBadge = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .pinBadge, key: "image", of: String.self) ?? "")
                Image(pinBadge)
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                    .frame(width: 20, height: 20)
                    .isHidden(!(category == .pin || category == .pinAndAnnouncement) || viewConfig.isHidden(elementId: .pinBadge))
                    .accessibilityIdentifier(AccessibilityID.Social.PostContent.pinBadge)
                
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
                    .buttonStyle(PlainButtonStyle())
                    .isHidden(viewConfig.isHidden(elementId: .menuButton))
                    .bottomSheet(isShowing: $showBottomSheet, height: .fixed(bottomSheetHeight), backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                        PostBottomSheetView(isShown: $showBottomSheet, post: post) { postAction in
                            
                            switch postAction {
                            case .editPost:
                                showBottomSheet.toggle()
                                
                                // Dismiss bottomsheet
                                host.controller?.dismiss(animated: false)
                                
                                if category == .global {
                                    showEditAlert.toggle()
                                } else {
                                    showPostEditScreen()
                                }
                            case .closePoll, .deletePost:
                                break
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12))
        }
        .alert(isPresented: $showEditAlert, content: {
            Alert(title: Text(AmityLocalizedStringSet.Social.featuredPostEditConfirmationTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.featuredPostEditConfirmation.localizedString), primaryButton: .default(Text(AmityLocalizedStringSet.General.edit.localizedString), action: {
                self.showPostEditScreen()
            }), secondaryButton: .cancel(Text(AmityLocalizedStringSet.General.cancel.localizedString)))
        })
    }
    
    private func showPostEditScreen() {
        let editOption = AmityPostComposerOptions.editOptions(post: post)
        let view = AmityPostComposerPage(options: editOption)
        let controller = AmitySwiftUIHostingController(rootView: view)
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.isHidden = true
        host.controller?.present(navigationController, animated: true)
    }
    
    @ViewBuilder
    private func postContentView(_ post: AmityPostModel) -> some View {
        VStack(spacing: 16) {
            switch post.dataTypeInternal {
            case .text:
                postContentTextView()
                
                PreviewLinkView(post: post)
                
            case .image, .video:
                postContentTextView()
                
                PostContentMediaView(post: post)
                    .frame(height: 328)
                    .clipShape(RoundedCorner(radius: 8))
                
            case .file:
                EmptyView()
                
            case .poll:
                postContentTextView()
                
                PostContentPollView(style: style, post: post, showPollResults: context?.showPollResults ?? false, isInPendingFeed: false) { actionType in
                    let context = Context(shouldShowPollResults: actionType == PollAction.viewDetailWithResults, category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton)
                    onTapAction?(context)
                }
                
            case .liveStream:
                livestreamPostContentTextView()
                
                PostContentLiveStreamView(post: post)
                    .padding([.leading, .trailing, .top], -16)
            case .unknown:
                EmptyView()
            }
        }
        .padding([.leading, .trailing], 16)
        
    }
    
    
    @ViewBuilder
    private func postContentTextView() -> some View {
        if !post.text.isEmpty {
            ExpandableText(post.text, metadata: post.metadata, mentionees: post.mentionees, onTapMentionee: { userId in
                goToUserProfilePage(userId)
            })
            .lineLimit(style == .detail ? 1000 : 8)
            .moreButtonText("...See more")
            .font(AmityTextStyle.body(.clear).getFont())
            .foregroundColor(Color(viewConfig.theme.baseColor))
            .attributedColor(viewConfig.theme.primaryColor)
            .moreButtonColor(Color(viewConfig.theme.primaryColor))
            .expandAnimation(.easeOut(duration: 0.25))
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    @ViewBuilder
    private func livestreamPostContentTextView() -> some View {
        if let livestream = post.liveStream {
            
            VStack(spacing: 0) {
                let title = livestream.title ?? ""
                let description = livestream.streamDescription ?? ""
                
                if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("\(title)")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, description.isEmpty ? 16 : 20)
                }
                
                if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ExpandableText(description)
                        .lineLimit(8)
                        .moreButtonText("...See more")
                        .font(AmityTextStyle.body(.clear).getFont())
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .attributedColor(viewConfig.theme.primaryColor)
                        .moreButtonColor(Color(viewConfig.theme.primaryColor))
                        .expandAnimation(.easeOut(duration: 0.25))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                }
            }
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
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    }
                    .onTapGesture {
                        showReactionList.toggle()
                    }
                    
                    Spacer()
                    
                    Text("\(post.allCommentCount.formattedCountString) \(post.allCommentCount == 1 ? "comment" : "comments")")
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                }
                .frame(height: 20)
            }
            .padding([.leading, .trailing], 16)
            .sheet(isPresented: $showReactionList) {
                AmityReactionList(post: post.object, pageId: pageId)
                    .environmentObject(host)
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
                .applyTextStyle(.body(Color(viewConfig.defaultLightTheme.baseColorShade2)))
                .isHidden(self.post.targetCommunity?.isJoined ?? true || viewConfig.isHidden(elementId: .nonMemberSection))
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.nonMemberSection)
            
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
                                .applyTextStyle(.bodyBold(Color(post.isLiked ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade2)))
                        } else if style == .detail {
                            Text(reactionTitle)
                                .applyTextStyle(.bodyBold(Color(post.isLiked ? viewConfig.theme.primaryColor : viewConfig.theme.baseColorShade2)))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .isHidden(viewConfig.isHidden(elementId: .reactionButton), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.reactionButton)
                
                Button(feedbackStyle: .light, action: {
                    let context = AmityPostContentComponent.Context(category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton)
                    onTapAction?(context)
                }) {
                    let commentIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .commentButton, key: "icon", of: String.self) ?? "")
                    let commentTitle = viewConfig.getConfig(elementId: .commentButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(commentIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        
                        if style == .feed {
                            Text(post.allCommentCount == 0 ? "0" : "\(post.allCommentCount)")
                                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade2)))
                        } else if style == .detail {
                            Text(commentTitle)
                                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade2)))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
                .isHidden(viewConfig.isHidden(elementId: .commentButton), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.commentButton)
                
                Spacer()
                
                Button(feedbackStyle: .light, action: {}) {
                    let shareIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .shareButton, key: "icon", of: String.self) ?? "")
                    let shareTitle = viewConfig.getConfig(elementId: .shareButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(shareIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        Text(shareTitle)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade2)))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .isHidden(viewConfig.isHidden(elementId: .shareButton), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.shareButton)
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
    var authorDisplayNameLabel: some View {
        HStack(spacing: 8) {
            Text(post.displayName)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .onTapGesture {
                    self.goToUserProfilePage(post.postedUserId)
                }
            
            if post.isFromBrand {
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(.leading, -4)
                    .opacity(post.isFromBrand ? 1 : 0)
            }
        }
    }
    
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
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
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
    var targetUserNameLabel: some View {
        HStack(spacing: 8) {
            
            Text(post.targetUser?.displayName ?? "Unknown")
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .onTapGesture {
                    let context = AmityPostContentComponentBehavior.Context(component: self)
                    AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToCommunityProfilePage(context: context)
                }
        }
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityPostContentComponentBehavior.Context(component: self, userId: userId)
        AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToUserProfilePage(context: context)
    }
}


class AmityPostContentComponentViewModel: ObservableObject {
    private let reactionManager = ReactionManager()
    
    init() {}
    
    func addReaction(id: String) async throws {
        try await reactionManager.addReaction(.like, referenceId: id, referenceType: .post)
    }
    
    func removeReaction(id: String) async throws {
        try await reactionManager.removeReaction(.like, referenceId: id, referenceType: .post)
    }
}

extension AmityPostContentComponent {
    
    // Context used to render the post
    public class Context {
        var showPollResults: Bool
        var category: AmityPostCategory
        var hidePostTarget: Bool
        var hideMenuButton: Bool
        
        public init(shouldShowPollResults: Bool = false,
                    category: AmityPostCategory = .general,
                    shouldHideTarget: Bool = false,
                    shouldHideMenuButton: Bool = false) {
            self.showPollResults = shouldShowPollResults
            self.category = category
            self.hidePostTarget = shouldHideTarget
            self.hideMenuButton = shouldHideMenuButton
        }
    }
}
