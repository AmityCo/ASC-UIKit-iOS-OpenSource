//
//  AmityEditCommentView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI

public struct AmityEditCommentView: View {
    
    @State private var text: String = ""
    @State private var mentionData: MentionData = MentionData()
    private let comment: AmityCommentModel
    private let cancelAction: () -> Void
    private let saveAction: (AmityCommentModel) -> Void
    @State private var bottomPadding: CGFloat = 0.0
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    public init(comment: AmityCommentModel, cancelAction: @escaping () -> Void, saveAction: @escaping (AmityCommentModel) -> Void) {
        self.comment = comment
        self.cancelAction = cancelAction
        self.saveAction = saveAction
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Image(AmityIcon.defaultCommunityAvatar.getImageResource())
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(.circle)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 8))
                .overlay(
                    VStack {
                        if let avatarURL = URL(string: comment.fileURL) {
                            URLImage(avatarURL) { progress in
                                
                            } content: { image in
                                image
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .clipShape(.circle)
                            }
                        }
                    }
                )

            
            VStack(alignment: .trailing, spacing: 10) {
            
                AmityTextEditorView(.comment(communityId: comment.communityId), text: $text, mentionData: $mentionData, textViewHeight: 120.0)
                    .maxExpandableHeight(120)
                    .mentionListPosition(.bottom(20.0))
                    .autoFocus(true)
                    .textColor(viewConfig.theme.baseColor)
                    .backgroundColor(viewConfig.theme.backgroundColor)
                    .hightlightColor(viewConfig.theme.primaryColor)
                    .willShowMentionList { listHeight in
                        bottomPadding = listHeight
                    }
                    .padding(12)
                    .background(
                        RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight])
                            .fill(Color(viewConfig.theme.baseColorShade4))
                    )
                
                HStack(spacing: 8) {
                    Button {
                        cancelAction()
                    } label: {
                        Text(AmityLocalizedStringSet.General.cancel.localizedString)
                            .font(.system(size: 13))
                            .foregroundColor(Color(UIColor(hex: "#636878")))
                            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.gray, lineWidth: 0.4)
                    )

                    Button {
                        var editedComment = comment
                        editedComment.text = text
                        editedComment.metadata = mentionData.metadata
                        editedComment.mentioneeBuilder = mentionData.mentionee
                        
                        saveAction(editedComment)
                    } label: {
                        Text(AmityLocalizedStringSet.General.save.localizedString)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                    .background(Color(viewConfig.theme.highlightColor))
                    .overlay(
                        text.isEmpty || text == comment.text ? Color.white.opacity(0.5) : nil
                    )
                    .clipShape(RoundedCorner(radius: 4))
                    .disabled(text.isEmpty || comment.text == text)
                }
                .padding(.top, bottomPadding)
            }
            Spacer(minLength: 16)
        }
        .onAppear {
            text = comment.text
            mentionData.metadata = comment.metadata
        }

    }
}
