//
//  AmityCommentCellView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/29/24.
//

import SwiftUI

enum PostTargetMembershipStatus {
    /// Member of a community where post is created
    case member
    /// Not a member of a community where post is created
    case nonMember
    /// Post target may not require membership. i.e post.targetCommunity might be nil
    case unknown
    
    // Helper
    static func determineStatus(isJoined: Bool?) -> PostTargetMembershipStatus {
        guard let isJoined else { return .unknown }
        
        return isJoined ? .member : .nonMember
    }
}

public enum AmityCommentButtonActionType {
    case react(AmityCommentModel)
    case reply(AmityCommentModel)
    case meatball(AmityCommentModel)
    case userProfile(String)
}

public typealias AmityCommentButtonAction = (AmityCommentButtonActionType) -> Void

public struct AmityCommentView: View {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    private let commentManager: CommentManager = CommentManager()
    
    let comment: AmityCommentModel
    let hideReplyButton: Bool
    let hideMeatballButton: Bool
    let hideButtonView: Bool
    let seeMoreLineLimit: Int
    let commentButtonAction: AmityCommentButtonAction
    @State var showSheet: Bool = false
    @State var showReactionSheet: Bool = false
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @EnvironmentObject var commentCoreViewModel: CommentCoreViewModel
    @StateObject private var viewModel = CommentViewModel()
    
    public init(comment: AmityCommentModel,
                hideReplyButton: Bool = false,
                hideMeatballButton: Bool = false,
                hideButtonView: Bool = false,
                seeMoreLineLimit: Int = 8,
                commentButtonAction: @escaping AmityCommentButtonAction) {
        self.comment = comment
        self.hideReplyButton = hideReplyButton
        self.hideMeatballButton = hideMeatballButton
        self.hideButtonView = hideButtonView
        self.commentButtonAction = commentButtonAction
        self.seeMoreLineLimit = seeMoreLineLimit
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            AmityUserProfileImageView(displayName: comment.displayName, avatarURL: URL(string: comment.avatarURL))
                .frame(width: 32, height: 32)
                .clipShape(.circle)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                .onTapGesture {
                    commentButtonAction(.userProfile(comment.userId))
                }
                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.avatarImageView)
            
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            
                            HStack(spacing: 4) {
                                Text(comment.displayName)
                                    .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                                    .onTapGesture {
                                        commentButtonAction(.userProfile(comment.userId))
                                    }
                                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.nameTextView)
                                    .lineLimit(1)
                                
                                Image(AmityIcon.brandBadge.imageResource)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .opacity(comment.isAuthorBrand ? 1 : 0)
                            }
                            .padding([.top, .leading, .trailing], 12)
                            
                            getModeratorBadgeView()
                                .padding([.leading, .trailing], 12)
                                .isHidden(!comment.isModerator)
                                .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.badgeImageView)
                            
                            ExpandableText(comment.text, metadata: comment.metadata, mentionees: comment.mentionees, onTapMentionee: { userId in
                                commentButtonAction(.userProfile(userId))
                            })
                            .lineLimit(seeMoreLineLimit)
                            .moreButtonText("...See more")
                            .font(AmityTextStyle.body(.clear).getFont())
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                            .attributedColor(viewConfig.theme.primaryColor)
                            .hashtagColor(viewConfig.theme.primaryColor)
                            .moreButtonColor(Color(viewConfig.theme.primaryColor))
                            .expandAnimation(.easeOut(duration: 0.25))
                            .lineSpacing(5)
                            .foregroundColor(Color(red: 0.16, green: 0.17, blue: 0.20))
                            .padding([.leading, .bottom, .trailing], 12)
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.commentTextView)
                        
                        }
                        .background(Color(viewConfig.theme.baseColorShade4))
                        .clipShape(RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight]))
                        
                        Button {
                            showSheet.toggle()
                        } label: {
                            Image(AmityIcon.commentFailedIcon.getImageResource())
                                .resizable()
                                .frame(width: 15, height: 15)
                                .padding(.bottom, 5)
                        }
                        .isHidden(comment.syncState != .error)
                        .actionSheet(isPresented: $showSheet) {
                            ActionSheet(title: Text(AmityLocalizedStringSet.Comment.deleteCommentTitle.localizedString), buttons: [
                                .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                                    Task {
                                        try await commentManager.deleteComment(withId: comment.id)
                                    }
                                }),
                                .cancel()
                            ])
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    
                    HStack(spacing: 4) {
                        HStack(spacing: -8) {
                            ForEach(Array(comment.allReactions.prefix(SocialReactionConfiguration.shared.renderReactionCount).enumerated()), id: \.element) { index, reaction in
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
                                    .zIndex(Double(comment.allReactions.count - index))
                            }
                        }
                        
                        Text(comment.reactionsCount.formattedCountString)
                            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColor)))
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.reactionCountTextView)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(viewConfig.theme.backgroundColor))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .inset(by: 0.5)
                            .stroke(Color(viewConfig.theme.baseColorShade4), lineWidth: 1)
                    )
                    .offset(y: 20)
                    .onTapGesture {
                        showReactionSheet.toggle()
                    }
                    .sheet(isPresented: $showReactionSheet, content: {
                        reactionListSheet
                    })
                    .isHidden(comment.reactionsCount == 0)
                }
                .padding(.bottom, comment.reactionsCount == 0 ? 0 : 16)
    
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .captureViewFrameInWindow(onFrame: { frame in
                            viewModel.reactionBarFrame = frame
                        })
                    
                    HStack(spacing: 12) {
                        Text(comment.isEdited ? "\(comment.createdAt.relativeTime) \(AmityLocalizedStringSet.Comment.editedText.localizedString)" : comment.createdAt.relativeTime)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.timestampTextView)
                        
                        Text(comment.myReaction != nil ? comment.myReaction!.name.capitalizeFirstLetter() : AmityLocalizedStringSet.Comment.reactButtonText.localizedString)
                            .applyTextStyle(.captionBold(comment.myReaction != nil ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade2)))
                            .lineLimit(1)
                            .tapAndDragSimutaneousGesture(longPressSensitivity: 150, tapAction: {
                                ImpactFeedbackGenerator.impactFeedback(style: .light)
                                
                                AmityUserAction.perform(host: host) {
                                    
                                    let targetMembershipStatus = commentCoreViewModel.targetMembershipStatus
                                    if targetMembershipStatus == .nonMember {
                                        AmityUIKit4Manager.behaviour.globalBehavior?.handleNonMemberAction(context: .init(host: host))
                                        return
                                    }
                                    
                                    // Reaction action cannot be decoupled since it is having rendering orchestration issue.
                                    // It may be SwiftUI bug.
                                    Task { @MainActor in
                                        
                                        do {
                                            if let myReaction = comment.myReaction {
                                                try await viewModel.removeReaction(id: comment.commentId, name: myReaction.name)
                                            } else {
                                                try await viewModel.addReaction(id: comment.commentId)
                                            }
                                        } catch let error {
                                            if error.isAmityErrorCode(.itemNotFound) {
                                                let message: String
                                                if let post = commentCoreViewModel.post, post.dataTypeInternal == .clip {
                                                    message = "This clip is no longer available."
                                                } else {
                                                    message = "This post is no longer available."
                                                }
                                                
                                                Toast.showToast(style: .warning, message: message)
                                            }
                                        }
                                    }
                                }
                            }, longPressAction: {
                                ImpactFeedbackGenerator.impactFeedback(style: .medium)
                                
                                AmityUserAction.perform(host: host) {
                                    let targetMembershipStatus = commentCoreViewModel.targetMembershipStatus
                                    if targetMembershipStatus == .nonMember {
                                        AmityUIKit4Manager.behaviour.globalBehavior?.handleNonMemberAction(context: .init(host: host))
                                        return
                                    }
                                    
                                    let reactionPickerViewModel = AmitySocialReactionPickerViewModel(referenceType: .comment, referenceId: comment.commentId, currentReaction: comment.myReaction?.name)
                                    AmitySocialReactionPickerOverlay.shared.show(frame: viewModel.reactionBarFrame, viewModel: reactionPickerViewModel)
                                }
                            }, dragChangedAction: { point in
                                AmitySocialReactionPickerOverlay.shared.checkHoveredReactionOnDrag(at: point)
                            }, dragEndedAction: { point in
                                AmitySocialReactionPickerOverlay.shared.addHoveredReactionDragEnded(at: point)
                            })
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.reactionButton)
                        
                        Button {
                            AmityUserAction.perform(host: host) {
                                
                                let targetMembershipStatus = commentCoreViewModel.targetMembershipStatus
                                if targetMembershipStatus == .nonMember {
                                    AmityUIKit4Manager.behaviour.globalBehavior?.handleNonMemberAction(context: .init(host: host))
                                    return
                                }
                                
                                commentButtonAction(.reply(comment))
                            }
                        } label: {
                            Text(AmityLocalizedStringSet.Comment.replyButtonText.localizedString)
                                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.replyButton)
                        .isHidden(hideReplyButton)
                        
                        Button {
                            commentButtonAction(.meatball(comment))
                        } label: {
                            Image(AmityIcon.meetballIcon.getImageResource())
                                .frame(width: 20, height: 16)
                        }
                        .buttonStyle(.plain)
                        .isHidden(hideMeatballButton)
                        
                        Spacer()
                    }
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.meatballsButton)
                    .isHidden(hideButtonView)
                }
                .padding(.top, hideButtonView ? 0 : 16)
                .padding(.bottom, 8)
                .isHidden(hideButtonView && comment.reactionsCount == 0)
            }
            
            Spacer(minLength: 16)
        }
        .padding(.vertical, 4)
    }
    
    
    @ViewBuilder
    func getModeratorBadgeView() -> some View {
        HStack(spacing: 3) {
            Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                .resizable()
                .frame(width: 12, height: 12)
                .padding(.leading, 6)
            Text("Moderator")
                .applyTextStyle(.captionSmall(Color(viewConfig.theme.primaryColor)))
                .padding(.trailing, 6)
        }
        .frame(height: 20)
        .background(Color(viewConfig.theme.primaryColor.blend(.shade3)))
        .clipShape(RoundedCorner(radius: 10))
    }
    
    @ViewBuilder
    private var reactionListSheet: some View {
        if #available(iOS 16.0, *) {
            AmityReactionList(comment: comment.comment, pageId: self.viewConfig.pageId)
                .presentationDetents([.fraction(0.5)])
        } else {
            AmityReactionList(comment: comment.comment, pageId: self.viewConfig.pageId)
        }
    }
}

class CommentViewModel: ObservableObject {
    var reactionBarFrame: CGRect = .zero
    private let reactionManager: ReactionManager = ReactionManager()
    
    func addReaction(id: String) async throws {
        try await reactionManager.addReaction(.like, referenceId: id, referenceType: .comment)
    }
    
    func removeReaction(id: String, name: String) async throws {
        try await reactionManager.removeReaction(name, referenceId: id, referenceType: .comment)
    }
}


