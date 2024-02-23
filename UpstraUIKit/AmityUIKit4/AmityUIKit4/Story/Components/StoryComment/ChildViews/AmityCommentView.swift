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
}

public typealias AmityCommentButtonAction = (AmityCommentButtonActionType) -> Void


public struct AmityCommentView: View {
    private let reactionManager: ReactionManager = ReactionManager()
    
    let comment: AmityCommentModel
    let hideReplyButton: Bool
    let hideButtonView: Bool
    let commentButtonAction: AmityCommentButtonAction
    
    public init(comment: AmityCommentModel, hideReplyButton: Bool = false, hideButtonView: Bool = false, commentButtonAction: @escaping AmityCommentButtonAction) {
        self.comment = comment
        self.hideReplyButton = hideReplyButton
        self.hideButtonView = hideButtonView
        self.commentButtonAction = commentButtonAction
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: URL(string: comment.fileURL))
                .frame(width: 32, height: 32)
                .clipShape(.circle)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .padding([.top, .leading, .trailing], 12)
                    
                    getModeratorBadgeView()
                        .padding([.leading, .trailing], 12)
                        .isHidden(!comment.isModerator)
                    
                    ExpandableText(comment.text, metadata: comment.metadata, mentionees: comment.mentionees)
                        .lineLimit(8)
                        .moreButtonText("...more")
                        .font(.system(size: 13.5))
                        .expandAnimation(.easeOut(duration: 0.25))
                        .lineSpacing(5)
                        .foregroundColor(Color(red: 0.16, green: 0.17, blue: 0.20))
                        .padding([.leading, .bottom, .trailing], 12)
                
                }
                .background(Color(UIColor(hex: "#EBECEF")))
                .clipShape(RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight]))
                
                HStack {
                    HStack(spacing: 12) {
                        Text(comment.isEdited ? "\(comment.createdAt.timeAgoString) \(AmityLocalizedStringSet.Comment.editedText.localizedString)" : comment.createdAt.timeAgoString)
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor(hex: "#898E9E")))
                        
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
                                .font(.system(size: 13))
                                .foregroundColor(comment.isLiked ? .accentColor : Color(UIColor(hex: "#898E9E")))
                        }

                        Button {
                            commentButtonAction(.reply(comment))
                        } label: {
                            Text(AmityLocalizedStringSet.Comment.replyButtonText.localizedString)
                                .font(.system(size: 13))
                                .foregroundColor(Color(UIColor(hex: "#898E9E")))
                        }
                        .isHidden(hideReplyButton)
                        
                        Button {
                            commentButtonAction(.meatball(comment))
                        } label: {
                            Image(AmityIcon.meetballIcon.getImageResource())
                                .frame(width: 20, height: 16)
                        }
                        
                        Spacer()
                    }.isHidden(hideButtonView)

                    
                    HStack(spacing: 4) {
                        Text(comment.reactionsCount.formattedCountString)
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor(hex: "#898E9E")))
                        Image(AmityIcon.likeReactionIcon.getImageResource())
                            .resizable()
                            .frame(width: 17, height: 17)
                    }
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
                .font(.system(size: 10))
                .foregroundColor(.blue)
                .padding(.trailing, 6)
        }
        .frame(height: 20)
        .background(Color(UIColor(hex: "#D9E5FC")))
        .clipShape(RoundedCorner(radius: 10))
    }
}



