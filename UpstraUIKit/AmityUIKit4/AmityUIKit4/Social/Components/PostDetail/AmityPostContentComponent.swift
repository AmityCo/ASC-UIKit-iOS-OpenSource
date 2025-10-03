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
    @StateObject private var commentCoreViewModel: CommentCoreViewModel
    @State private var showReactionList: Bool = false
    @State private var showBottomSheet: Bool = false
    @State private var showEditAlert: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showShareBottomSheet: Bool = false
    
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
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: post.postId, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: post.targetCommunity?.communityId))
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
        self._commentCoreViewModel = StateObject(wrappedValue: CommentCoreViewModel(referenceId: post.postId, referenceType: .post, hideEmptyText: true, hideCommentButtons: false, communityId: post.targetCommunity?.communityId))
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
            postInlineCommentView(post)
        }
        .contentShape(Rectangle())
        .padding(.bottom, 12)
        .onTapGesture {
            let context = AmityPostContentComponent.Context(category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton)
            onTapAction?(context)
        }
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
        .onAppear {
            viewModel.checkPermissions(post: post)
        }
    }
    
    @ViewBuilder
    private func postHeaderView(_ post: AmityPostModel) -> some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            let isBadgeVisible = category == .announcement || category == .global || category == .pinAndAnnouncement
            HStack {
                Text(AmityLocalizedStringSet.Social.featuredPostBadge.localizedString)
                    .applyTextStyle(.captionBold(Color(viewConfig.defaultLightTheme.baseColor)))
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
                    .bottomSheet(isShowing: $showBottomSheet, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
                        PostBottomSheetView(isShown: $showBottomSheet, post: post) { postAction in
                            
                            switch postAction {
                            case .editPost:
                                showBottomSheet.toggle()
                                
                                // Dismiss bottomsheet
                                host.controller?.dismiss(animated: false)
                                
                                // Determine if we should show edit alert or go directly to edit screen
                                if category == .global
                                    && post.targetCommunity != nil
                                    && post.targetCommunity?.postSettings == .adminReviewPostRequired
                                    && !post.hasModeratorPermission {
                                    showEditAlert.toggle()
                                } else {
                                    showPostEditScreen()
                                }
                            case .closePoll, .deletePost:
                                break
                            case .reportPost:
                                // Dismiss toggle
                                showBottomSheet.toggle()
                                
                                AmityUserAction.perform {
                                    // Dismiss bottom sheet
                                    host.controller?.dismiss(animated: false)
                                    
                                    let postId = post.postId
                                    
                                    let page = AmityContentReportPage(type: .post(id: postId))
                                        .updateTheme(with: viewConfig)
                                    let vc = AmitySwiftUIHostingNavigationController(rootView: page)
                                    vc.isNavigationBarHidden = true
                                    self.host.controller?.present(vc, animated: true)
                                }
                            case .sharePost:
                                showShareSheet = true
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
        .sheet(isPresented: $showShareSheet) {
            let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .post, id: post.postId)
            ShareActivitySheetView(link: shareLink)
        }
    }
    
    private func showPostEditScreen() {
        let editOption = AmityPostComposerOptions.editOptions(mode: post.dataTypeInternal == .clip ? .editClip : .edit, post: post)
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
                
                PostContentMediaView(post: post, viewConfig: viewConfig)
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
                
            case .clip:
                postContentTextView()
                
                PostContentClipView(post: post)
                    .onTapGesture {
                        let context = Context(category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton, isClipPost: true)
                        onTapAction?(context)
                    }
                
            case .unknown:
                EmptyView()
            }
        }
        .padding([.leading, .trailing], 16)
        
    }
    
    
    @ViewBuilder
    private func postContentTextView() -> some View {
        if !post.title.isEmpty || !post.text.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Post title
                if !post.title.isEmpty {
                    Text(post.title)
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Post text content
                if !post.text.isEmpty {
                    ExpandableText(post.text, metadata: post.metadata, mentionees: post.mentionees, highlightedText: context?.searchKeyword, onTapMentionee: { userId in
                        goToUserProfilePage(userId)
                    }, onTapHashtag: { hashtag in
                        // \u{200E} make the hashtag text left to right in all languages
                        goToSearchPage("#\(hashtag)")
                    })
                    .lineLimit(style == .detail ? 1000 : 8)
                    .moreButtonText("...See more")
                    .font(AmityTextStyle.body(.clear).getFont())
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .attributedColor(viewConfig.theme.primaryColor)
                    .hashtagColor(viewConfig.theme.primaryColor)
                    .moreButtonColor(Color(viewConfig.theme.primaryColor))
                    .expandAnimation(.easeOut(duration: 0.25))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func livestreamPostContentTextView() -> some View {
        if let livestream = post.liveStream {
            
            VStack(spacing: 0) {
                let title = livestream.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let description = livestream.streamDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if !title.isEmpty {
                    
                    if #available(iOS 15, *) {
                        let highlightedTitle = title.highlight(mentions: nil, highlightLink: true, highlightAttributes: [.foregroundColor: viewConfig.theme.primaryColor, .font: UIFont.systemFont(ofSize: AmityTextStyle.bodyBold(.white).getStyle().fontSize, weight: .semibold)])
                        Text(highlightedTitle)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, description.isEmpty ? 16 : 20)
                        
                    } else {
                        Text(title)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, description.isEmpty ? 16 : 20)
                    }
                }
                
                if !description.isEmpty {
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
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    HStack(spacing: -8) {
                        ForEach(Array(post.allReactions.prefix(SocialReactionConfiguration.shared.renderReactionCount).enumerated()), id: \.element) { index, reaction in
                            let reactionType = SocialReactionConfiguration.shared.getReaction(withName: reaction)
                            Circle()
                                .fill(Color(viewConfig.theme.backgroundColor))
                                .frame(width: 22.0, height: 22.0)
                                .overlay(
                                    Image(reactionType.image)
                                        .resizable()
                                        .frame(width: 20.0, height: 20.0)
                                        .clipShape(Circle())
                                )
                                .zIndex(Double(post.allReactions.count - index))
                        }
                    }
                    
                    Text("\(post.reactionsCount.formattedCountString)")
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    
                    Spacer(minLength: 0)
                }
                .onTapGesture {
                    AmityUserAction.perform {
                        showReactionList.toggle()
                    }
                }
                .isHidden(post.allReactions.count == 0)
                
                Text("\(post.allCommentCount.formattedCountString) \(post.allCommentCount == 1 ? "comment" : "comments")")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    .isHidden(post.allCommentCount == 0)
                
                Spacer()
                    .isHidden(post.allReactions.count != 0)
            }
            .frame(height: 20)
        }
        .padding([.leading, .trailing], 16)
        .sheet(isPresented: $showReactionList) {
            reactionListSheet
        }
        .isHidden(post.allCommentCount == 0 && post.allReactions.count == 0)
    }
    
    @ViewBuilder
    private func postEngagementActionView(_ post: AmityPostModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            
            // We do not show "Join community to interact" view anymore
            HStack(spacing: 4) {
                let reactionIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .reactionButton, key: "icon", of: String.self) ?? "")
                let reactionTitle = viewConfig.getConfig(elementId: .reactionButton, key: "text", of: String.self) ?? ""
                HStack(spacing: 3) {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .captureViewFrameInWindow(onFrame: { rect in
                            viewModel.reactionBarFrame = rect
                        })
                    
                    Image(post.myReaction != nil ? post.myReaction!.image : reactionIcon)
                        .resizable()
                        .frame(width: 20.0, height: 20.0)

                    Text(post.myReaction != nil ? post.myReaction!.name.capitalizeFirstLetter() : reactionTitle)
                        .applyTextStyle(.bodyBold(Color(post.myReaction != nil ? viewConfig.theme.baseColor : viewConfig.theme.baseColorShade2)))
                        .lineLimit(1)
                }
                .tapAndDragSimutaneousGesture(longPressSensitivity: 150, tapAction: {
                    ImpactFeedbackGenerator.impactFeedback(style: .light)
                    
                    AmityUserAction.perform(host: host) {
                        let shouldAllowInteraction = self.post.targetCommunity?.isJoined ?? true
                        
                        if !shouldAllowInteraction {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.nonMemberReactPostMessage.localizedString)
                            return
                        }
                        
                        Task { @MainActor in
                            if let myReaction = post.myReaction {
                                try await viewModel.removeReaction(id: post.postId, name: myReaction.name)
                            } else {
                                try await viewModel.addReaction(id: post.postId)
                            }
                            
                            /// Send didPostReacted event to update global feed data source
                            /// This event is observed in PostFeedViewModel
                            NotificationCenter.default.post(name: .didPostReacted, object: post.object)
                        }
                    }
                }, longPressAction: {
                    ImpactFeedbackGenerator.impactFeedback(style: .heavy)
                    
                    AmityUserAction.perform(host: host) {
                        let shouldAllowInteraction = self.post.targetCommunity?.isJoined ?? true
                        
                        if !shouldAllowInteraction {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.nonMemberReactPostMessage.localizedString)
                            return
                        }
                        
                        let reactionPickerViewModel = AmitySocialReactionPickerViewModel(referenceType: .post, referenceId: post.postId, currentReaction: post.myReaction?.name)
                        AmitySocialReactionPickerOverlay.shared.show(frame: viewModel.reactionBarFrame, viewModel: reactionPickerViewModel)
                    }
                }, dragChangedAction: { point in
                    AmitySocialReactionPickerOverlay.shared.checkHoveredReactionOnDrag(at: point)
                }, dragEndedAction: { point in
                    AmitySocialReactionPickerOverlay.shared.addHoveredReactionDragEnded(at: point)
                })
                .isHidden(viewConfig.isHidden(elementId: .reactionButton), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.reactionButton)
                
                Button(feedbackStyle: .light, action: {
                    AmityUserAction.perform(host: host) {
                        let shouldAllowInteraction = self.post.targetCommunity?.isJoined ?? true
                        
                        if !shouldAllowInteraction {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.nonMemberReactPostMessage.localizedString)
                            return
                        }
                        
                        let context = AmityPostContentComponent.Context(category: category, shouldHideTarget: hideTarget, shouldHideMenuButton: hideMenuButton)
                        onTapAction?(context)
                    }
                }) {
                    let commentIcon = AmityIcon.getImageResource(named: viewConfig.getConfig(elementId: .commentButton, key: "icon", of: String.self) ?? "")
                    let commentTitle = viewConfig.getConfig(elementId: .commentButton, key: "text", of: String.self) ?? ""
                    HStack(spacing: 3) {
                        Image(commentIcon)
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                        
                        Text(commentTitle)
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColorShade2)))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
                .isHidden(viewConfig.isHidden(elementId: .commentButton), remove: true)
                .accessibilityIdentifier(AccessibilityID.Social.PostContent.commentButton)
                
                Spacer()
                
                shareLinkButton
            }
        }
        .padding(.trailing, 16)
        .padding(.leading, 14)
    }
    
    @ViewBuilder
    private func postInlineCommentView(_ post: AmityPostModel) -> some View {
        if style == .feed, let comment = post.inlineComment {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                                
                AmityCommentView(
                    comment: comment,
                    hideMeatballButton: true,
                    hideButtonView: false,
                    seeMoreLineLimit: 3
                ) { actionType in
                    handleCommentAction(actionType, post: post)
                }
                .onTapGesture {
                    goToComment(comment.commentId)
                }
                .environmentObject(viewConfig)
                .padding(.top, 10)
                
                if comment.childrenNumber > 0 {
                    Button {
                        goToComment(comment.id, showReplies: true)
                    } label: {
                        HStack {
                            HStack(spacing: 4) {
                                Image(AmityIcon.replyArrowIcon.getImageResource())
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .padding(.leading, 8)
                                
                                let repliesCount = comment.childrenNumber
                                let word = WordsGrammar(count: repliesCount, set: .reply)
                                let finalText = "View \(repliesCount) \(word.value)"
                                Text(finalText)
                                    .applyTextStyle(.captionBold(Color(viewConfig.theme.secondaryColorShade1)))
                                    .padding(.trailing, 8)
                            }
                            .frame(height: 28, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 0.4)
                            )
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 52)
                    .padding(.top, !(post.targetCommunity?.isJoined ?? true) && comment.reactionsCount == 0 ? 8 : 4)
                }
            }
            .environmentObject(commentCoreViewModel)
        }
    }
    
    private func handleCommentAction(_ actionType: AmityCommentButtonActionType, post: AmityPostModel) {
        switch actionType {
        case .react(_):
            break
        case .reply(let comment):
            goToComment(comment.id, showReplyToComment: true)
        case .meatball(_):
            break
        case .userProfile(let userId):
            goToUserProfilePage(userId)
        }
    }
    
    
    func canUserSharePost() -> Bool {
        let canSharePostLink = AmityUIKitManagerInternal.shared.canShareLink(for: .post)
        var isPrivateCommunity = false
        if let community = post.targetCommunity, !community.isPublic {
            isPrivateCommunity = true
        }
        
        return canSharePostLink && !isPrivateCommunity
    }
    
    @ViewBuilder
    var shareLinkButton: some View {
        let canSharePostLink = canUserSharePost()
        
        Button(feedbackStyle: .light, action: {
            showShareBottomSheet = true
        }) {
            let shareIcon = AmityIcon.shareToIcon.imageResource
            HStack(spacing: 3) {
                Image(shareIcon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                    .frame(width: 20.0, height: 20.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(AccessibilityID.Social.PostContent.shareButton)
        .bottomSheet(isShowing: $showShareBottomSheet, height: .contentSize) {
            VStack(spacing: 0) {
                shareableLinkItemView
            }
            .padding(.bottom, 32)
        }
        .visibleWhen(canSharePostLink)
    }
        
    @ViewBuilder
    var shareableLinkItemView: some View {
        let copyLinkConfig = viewConfig.forElement(.copyLink)
        let shareLinkConfig = viewConfig.forElement(.shareLink)

        BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? "")
            .onTapGesture {
                showShareBottomSheet.toggle()
                
                let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .post, id: post.postId)
                UIPasteboard.general.string = shareLink
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    Toast.showToast(style: .success, message: "Link copied")
                }
            }
        
        BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? "")
            .onTapGesture {
                showShareBottomSheet.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showShareSheet = true
                }
            }
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
                    goToCommunityProfilePage()
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
                    goToCommunityProfilePage()
                }
        }
    }
    
    @ViewBuilder
    private var reactionListSheet: some View {
        if #available(iOS 16.0, *) {
            AmityReactionList(post: post.object, pageId: pageId)
                            .environmentObject(host)
                            .presentationDetents([.fraction(0.5)])
        } else {
            AmityReactionList(post: post.object, pageId: pageId)
                            .environmentObject(host)
        }
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityPostContentComponentBehavior.Context(component: self, userId: userId)
        AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToUserProfilePage(context: context)
    }
    
    private func goToComment(_ commentId: String, showReplyToComment: Bool = false, showReplies: Bool = false) {
        let page = AmityPostDetailPage(id: post.postId, commentId: commentId, showReplyToComment: showReplyToComment, preloadRepliesOfComment: showReplies)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func goToSearchPage(_ keyword: String) {
        let context = AmityPostContentComponentBehavior.Context(component: self, searchKeyword: keyword)
        AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToSocialGlobalSearchPage(context: context)
    }
    
    private func goToCommunityProfilePage() {
        let context = AmityPostContentComponentBehavior.Context(component: self)
        AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToCommunityProfilePage(context: context)
    }
}


class AmityPostContentComponentViewModel: ObservableObject {
    private let reactionManager = ReactionManager()
    private let permissionChecker = CommunityPermissionChecker()
    
    @Published var hasDeletePermission: Bool = false
    
    var reactionBarFrame: CGRect = .zero
    
    init() {}
    
    func checkPermissions(post: AmityPostModel) {
        if post.isOwner {
            hasDeletePermission = true
            return
        }
        
        if let communityId = post.targetCommunity?.communityId {
            Task { @MainActor in
                hasDeletePermission = await CommunityPermissionChecker.hasDeleteCommunityPostPermission(communityId: communityId)
            }
        }
    }
    
    func addReaction(id: String) async throws {
        try await reactionManager.addReaction(.like, referenceId: id, referenceType: .post)
    }
    
    func removeReaction(id: String, name: String) async throws {
        try await reactionManager.removeReaction(name, referenceId: id, referenceType: .post)
    }
}

extension AmityPostContentComponent {
    
    // Context used to render the post
    public class Context {
        var showPollResults: Bool
        var category: AmityPostCategory
        var hidePostTarget: Bool
        var hideMenuButton: Bool
        var isClipPost: Bool
        var searchKeyword: String
        
        
        public init(shouldShowPollResults: Bool = false,
                    category: AmityPostCategory = .general,
                    shouldHideTarget: Bool = false,
                    shouldHideMenuButton: Bool = false,
                    isClipPost: Bool = false,
                    searchKeyword: String = ""
        ) {
            self.showPollResults = shouldShowPollResults
            self.category = category
            self.hidePostTarget = shouldHideTarget
            self.hideMenuButton = shouldHideMenuButton
            self.isClipPost = isClipPost
            self.searchKeyword = searchKeyword
        }
    }
}
