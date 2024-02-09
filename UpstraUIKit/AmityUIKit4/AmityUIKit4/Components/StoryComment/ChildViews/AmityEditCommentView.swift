//
//  AmityEditCommentView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI

public struct AmityEditCommentView: View {
    
    @State private var text: String = ""
    private let comment: AmityCommentModel
    private let cancelAction: () -> Void
    private let saveAction: (AmityCommentModel) -> Void
    
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
            
                ZStack {
                    TextEditor(text: $text)
                        .font(.system(size: 13.5))
                        .lineSpacing(5)
                        .foregroundColor(Color(red: 0.16, green: 0.17, blue: 0.20))
                        .frame(height: 120)
                        .colorMultiply(Color(UIColor(hex: "#EBECEF")))
                        .padding(12)
                }
                .background(Color(UIColor(hex: "#EBECEF")))
                .clipShape(RoundedCorner(radius: 12, corners: [.topRight, .bottomLeft, .bottomRight]))
                
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
                        saveAction(editedComment)
                    } label: {
                        Text(AmityLocalizedStringSet.General.save.localizedString)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                    .background(Color.blue)
                    .overlay(
                        text.isEmpty || text == comment.text ? Color.white.opacity(0.5) : nil
                    )
                    .clipShape(RoundedCorner(radius: 4))
                    .disabled(text.isEmpty || comment.text == text)
                    
                }
            }
            Spacer(minLength: 16)
        }
        .onAppear {
            text = comment.text
        }

    }
}
