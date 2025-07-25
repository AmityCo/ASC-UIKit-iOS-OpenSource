//
//  ClipFeedItemOverlayView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import SwiftUI
import AmitySDK

public enum ClipFeedAction {
    case userProfile(userId: String)
    case postDetail(post: AmityPostModel)
    case commentTray(post: AmityPostModel)
    case exploreCommunity
    case createCommunity
    case watchNextClip
}

struct ClipFeedItemOverlayView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    
    let post: AmityPostModel
    let isInteractionEnabled: Bool
    @StateObject var playerController: AmityMediaPlayerController
    @StateObject var viewModel: ClipFeedOverlayViewModel
    let onTapAction: ((ClipFeedAction) -> Void)?
    
    init(post: AmityPostModel, playerController: AmityMediaPlayerController, isInteractionEnabled: Bool, onTapAction: ((ClipFeedAction) -> Void)?) {
        self.post = post
        self.isInteractionEnabled = isInteractionEnabled
        self._playerController = StateObject(wrappedValue: playerController)
        self._viewModel = StateObject(wrappedValue: ClipFeedOverlayViewModel(post: post))
        self.onTapAction = onTapAction
    }
    
    @State private var sliderValue: Double = 0
    @State private var showMoreOption: Bool = false
    
    var body: some View {
        ZStack {
            // Gradient overlay
            ClipFeedGradientLayer()
            
            // Action Area
            VStack(spacing: 0) {
                // Content Area
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        
                        Color.white.opacity(0.01)
                            .padding(.top, 44)
                            .onTapGesture {
                                if playerController.isPlaying {
                                    playerController.togglePlayPause()
                                }
                            }
                        
                        Spacer()
                        
                        // Left side - User info and caption
                        VStack(alignment: .leading, spacing: 10) {
                            // User info
                            HStack(spacing: 8) {
                                
                                AmityUserProfileImageView(displayName: post.postedUser?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: post.postedUser?.avatarURL ?? ""))
                                    .frame(size: CGSize(width: 32, height: 32))
                                    .clipShape(Circle())
                                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .onTapGesture {
                                        onTapAction?(.userProfile(userId: post.postedUserId))
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 0) {
                                        authorDisplayNameLabel
                                            .layoutPriority(1)
                                        
                                        Text("•")
                                            .applyTextStyle(.caption(Color.white))
                                            .padding(.horizontal, 4)
                                            .layoutPriority(2)
                                        
                                        Text("\(post.timestamp)\(post.isEdited ? " (edited)" : "")")
                                            .applyTextStyle(.caption(Color.white))
                                            .isHidden(viewConfig.isHidden(elementId: .timestamp))
                                            .accessibilityIdentifier(AccessibilityID.Social.PostContent.timestamp)
                                            .layoutPriority(2)
                                    }
                                    
                                    // Moderator Badge
                                    if post.isModerator {
                                        let elementConfig = viewConfig.forElement(.moderatorBadge, pageId: nil, componentId: .postContentComponent)
                                        HStack(spacing: 3) {
                                            Image(AmityIcon.getImageResource(named: elementConfig.icon ?? "moderatorBadgeIcon"))
                                                .resizable()
                                                .frame(width: 12, height: 12)
                                                .padding(.leading, 6)
                                            Text(elementConfig.text ?? "Moderator")
                                                .applyTextStyle(.captionSmall(Color(viewConfig.theme.primaryColor)))
                                                .padding(.trailing, 6)
                                        }
                                        .frame(height: 20)
                                        .background(Color(viewConfig.theme.primaryColor.blend(.shade3)))
                                        .clipShape(RoundedCorner(radius: 10))
                                        .accessibilityIdentifier(AccessibilityID.Social.PostContent.moderatorBadge)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Caption
                            postContentTextView()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Right side - Action buttons
                    VStack(spacing: 0) {
                        if isInteractionEnabled {
                            // Like button
                            VStack(spacing: 4) {
                                Button(action: {
                                    var canUpdateReaction = true
                                    
                                    if let targetCommunity = post.targetCommunity, !targetCommunity.isJoined {
                                        canUpdateReaction = false
                                    }
                                    
                                    if canUpdateReaction {
                                        Task { @MainActor in
                                            do {
                                                if viewModel.isPostLiked {
                                                    try await viewModel.removeReaction(id: post.postId)
                                                } else {
                                                    try await viewModel.addReaction(id: post.postId)
                                                }
                                            } catch let error {
                                                // Clip Deleted
                                                if error.isAmityErrorCode(.itemNotFound) {
                                                    // Stop playing
                                                    playerController.pause()
                                                    
                                                    viewModel.localIsClipDeleted = true
                                                    
                                                    // Forcefully update the cache
                                                    viewModel.updatePostCache(postId: post.postId)
                                                }
                                            }
                                        }
                                        
                                        /// Send didPostReacted event to update global feed data source
                                        /// This event is observed in PostFeedViewModel
                                        NotificationCenter.default.post(name: .didPostReacted, object: post.object)
                                    } else {
                                        Toast.showToast(style: .warning, message: "Join community to interact with this clip.")
                                    }
                                }) {
                                    Image(viewModel.isPostLiked ? AmityIcon.clipReactIconLike.imageResource : AmityIcon.clipReactionIcon.imageResource)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                }
                                Text(viewModel.reactionsCount.formattedCountString)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 24)
                            
                            // Comment button
                            VStack(spacing: 4) {
                                ActionButton(resource: AmityIcon.clipCommentIcon.imageResource) {
                                    // Pause the video
                                    playerController.pause()
                                    
                                    // Open comment tray
                                    onTapAction?(.commentTray(post: post))
                                }
                                
                                Text(post.allCommentCount.formattedCountString)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 24)
                        }
                        
                        // Mute/Unmute button
                        ActionButton(resource: playerController.isMuted ? AmityIcon.clipMuteIcon.imageResource : AmityIcon.clipUnmuteIcon.imageResource) {
                            
                            if case .clip(let data) =  post.content {
                                if data.isMuted {
                                    playerController.mute()
                                } else {
                                    playerController.toggleMute()
                                }
                            }
                        }
                        .padding(.bottom, 24)
                        
                        if isInteractionEnabled {
                            // More options
                            ActionButton(resource: AmityIcon.threeDotIcon.imageResource) {
                                playerController.pause()
                                
                                showMoreOption = true
                            }
                        }
                    }
                    .padding(.bottom, 56)
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
                .opacity(playerController.isSeeking ? 0 : 1)
                
                if playerController.isSeeking {
                    HStack {
                        Text(viewModel.formatDuration(duration: Int(playerController.currentTime)))
                            .applyTextStyle(.body(Color.white))
                        
                        Spacer()
                        
                        Text(viewModel.formatDuration(duration: Int(playerController.duration)))
                            .applyTextStyle(.body(Color.white))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                VideoSeekBar(
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
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // Play/Pause indicator (center)
            Button(action: {
                playerController.togglePlayPause()
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .opacity(playerController.isPlaying ? 0 : 1)
            
            ClipFeedDeletedStateView { action in
                onTapAction?(.watchNextClip)
            }
            .visibleWhen(post.isDeleted || viewModel.localIsClipDeleted)
        }
        .bottomSheet(isShowing: $showMoreOption, height: .contentSize, backgroundColor: Color(viewConfig.theme.backgroundColor)) {
            VStack(spacing: 0) {
                BottomSheetItemView(icon: AmityIcon.viewPostIcon.imageResource, text: "View post")
                    .onTapGesture {
                        playerController.pause()
                        
                        showMoreOption.toggle()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onTapAction?(.postDetail(post: post))
                        }
                    }
            }
            .padding(.bottom, 64)
        }
    }
}

extension ClipFeedItemOverlayView {
    
    @ViewBuilder
    var authorDisplayNameLabel: some View {
        HStack(spacing: 8) {
            Text(post.displayName)
                .applyTextStyle(.bodyBold(Color.white))
                .lineLimit(1)
                .onTapGesture {
                    onTapAction?(.postDetail(post: post))
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
    private func postContentTextView() -> some View {
        if !post.text.isEmpty {
            ExpandableText(post.text, defaultAction: {
                onTapAction?(.postDetail(post: post))
            }, metadata: post.metadata, mentionees: post.mentionees, onTapMentionee: { userId in
                // We do not support expanding text in this view, so we redirect to post detail page
                onTapAction?(.postDetail(post: post))
            })
            .lineLimit(3)
            .moreButtonText("...See more")
            .font(AmityTextStyle.body(.clear).getFont())
            .foregroundColor(Color.white)
            .attributedColor(UIColor.white)
            .moreButtonColor(Color.white)
            .moreButtonFont(AmityTextStyle.bodyBold(.white).getFont())
            .expandAnimation(.easeOut(duration: 0.25))
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                onTapAction?(.postDetail(post: post))
            }
        }
    }
}

extension ClipFeedItemOverlayView {
    
    struct ActionButton: View {
        
        let resource: ImageResource
        let action: DefaultTapAction
        
        var body: some View {
            Button {
                action()
            } label: {
                Image(resource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
}

class ClipFeedOverlayViewModel: ObservableObject {
    
    let reactionManager = ReactionManager()
    
    @Published var isPostLiked = false
    @Published var reactionsCount: Int = 0
    
    // In some cases, we do mapping between parent & child post while observing "child" post live collection. In those scenario,
    // this view will not update when reaction is added / removed as reactions are added to parent post live collection.
    // So we maintain local state to handle that scenario
    var localIsPostLiked: Bool?
    var localReactionCount: Int?
    @Published var localIsClipDeleted = false
    
    private let postManager = PostManager()
    private var token: AmityNotificationToken?
    
    init(post: AmityPostModel) {
        isPostLiked = post.isLiked
        reactionsCount = post.reactionsCount
        localIsClipDeleted = post.isDeleted
        
        if let localReactionCount, localReactionCount != reactionsCount {
            reactionsCount = localReactionCount
        }
    }
    
    @MainActor
    func addReaction(id: String) async throws {
        try await reactionManager.addReaction(.like, referenceId: id, referenceType: .post)
        
        isPostLiked = true
        localIsPostLiked = true
        
        localReactionCount = reactionsCount + 1
        reactionsCount = localReactionCount ?? 0
    }
    
    @MainActor
    func removeReaction(id: String) async throws {
        try await reactionManager.removeReaction(.like, referenceId: id, referenceType: .post)
        
        isPostLiked = false
        localIsPostLiked = false
        
        localReactionCount = max(0, reactionsCount - 1)
        reactionsCount = localReactionCount ?? 0
    }
    
    func formatDuration(duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // If your navigation stack / action is
    // Posts Feed - Clip Feed - Post Detail - Clip Feed - Delete Post
    // You may want to update the post cache when post is deleted so that previous stack can reflect the value and show deleted state.
    // So we forcefully update the cache.
    func updatePostCache(postId: String) {
        token = postManager.getPost(withId: postId).observe({ [weak self] liveObject, error in
            
            guard liveObject.dataStatus == .fresh || liveObject.dataStatus == .error else { return }
            
            self?.token?.invalidate()
        })
    }
}
