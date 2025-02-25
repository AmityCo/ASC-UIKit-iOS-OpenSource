//
//  AmityCommentCellView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/29/24.
//

import SwiftUI

public enum AmityCommentButtonActionType {
    case react(AmityCommentModel)
    case reply(AmityCommentModel)
    case meatball(AmityCommentModel)
    case userProfile(String)
}

public typealias AmityCommentButtonAction = (AmityCommentButtonActionType) -> Void


public struct AmityCommentView: View {
    private let reactionManager: ReactionManager = ReactionManager()
    private let commentManager: CommentManager = CommentManager()
    
    let comment: AmityCommentModel
    let hideReplyButton: Bool
    let hideButtonView: Bool
    let commentButtonAction: AmityCommentButtonAction
    @State var showSheet: Bool = false
    @State var showReactionSheet: Bool = false
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    public init(comment: AmityCommentModel, hideReplyButton: Bool = false, hideButtonView: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.comment = comment
        self.hideReplyButton = hideReplyButton
        self.hideButtonView = hideButtonView
        self.commentButtonAction = commentButtonAction
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
            
            VStack(alignment: .leading, spacing: 12) {
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
                        .lineLimit(8)
                        .moreButtonText("...See more")
                        .font(AmityTextStyle.body(.clear).getFont())
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .attributedColor(viewConfig.theme.primaryColor)
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
                            .isHidden(comment.syncState != .error)
                    }
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
                }
                
                HStack {
                    HStack(spacing: 12) {
                        Text(comment.isEdited ? "\(comment.createdAt.relativeTime) \(AmityLocalizedStringSet.Comment.editedText.localizedString)" : comment.createdAt.relativeTime)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.timestampTextView)
                        
                        Button(feedbackStyle: .light) {
                            // Reaction action cannot be decoupled since it is having rendering orchestration issue.
                            // It may be SwiftUI bug.
                            Task {
                                if comment.isLiked {
                                    try await reactionManager.removeReaction(.like, referenceId: comment.commentId, referenceType: .comment)
                                } else {
                                    try await reactionManager.addReaction(.like, referenceId: comment.commentId, referenceType: .comment)
                                }
                            }
                        } label: {
                            Text(comment.isLiked ? AmityLocalizedStringSet.Comment.reactedButtonText.localizedString : AmityLocalizedStringSet.Comment.reactButtonText.localizedString)
                                .applyTextStyle(.captionBold(comment.isLiked ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.baseColorShade2)))
                        }
                        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.reactionButton)

                        Button {
                            commentButtonAction(.reply(comment))
                        } label: {
                            Text(AmityLocalizedStringSet.Comment.replyButtonText.localizedString)
                                .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
                        }
                        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.replyButton)
                        .isHidden(hideReplyButton)
                        
                        Button {
                            commentButtonAction(.meatball(comment))
                        } label: {
                            Image(AmityIcon.meetballIcon.getImageResource())
                                .frame(width: 20, height: 16)
                        }
                        
                        Spacer()
                    }
                    .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.meatballsButton)
                    .isHidden(hideButtonView)

                    
                    HStack(spacing: 4) {
                        Text(comment.reactionsCount.formattedCountString)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.CommentBubble.reactionCountTextView)
                        
                        Image(AmityIcon.likeReactionIcon.getImageResource())
                            .resizable()
                            .frame(width: 17, height: 17)
                    }
                    .onTapGesture {
                        showReactionSheet.toggle()
                    }
                    .sheet(isPresented: $showReactionSheet, content: {
                        AmityReactionList(comment: comment.comment, pageId: self.viewConfig.pageId)
                    })
                    .isHidden(comment.reactionsCount == 0)
                }
                .isHidden(hideButtonView && comment.reactionsCount == 0)
            }
            Spacer(minLength: 16)
        }
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
}



