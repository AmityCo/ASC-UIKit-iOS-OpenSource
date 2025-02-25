//
//  UserCellView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/7/24.
//

import SwiftUI
import AmitySDK

struct UserCellView: View {
    private let user: AmityUser
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private var menuButtonAction: ((AmityUser) -> Void)? = nil
    
    init(user: AmityUser, menuButtonAction: ((AmityUser) -> Void)? = nil) {
        self.user = user
        self.menuButtonAction = menuButtonAction
    }
    
    var body: some View {
        HStack(spacing: 0) {
            AmityUserProfileImageView(displayName: user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: user.getAvatarInfo()?.fileURL ?? ""))
                .frame(size: CGSize(width: 40, height: 40))
                .clipShape(Circle())
            
            Text(user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                .lineLimit(1)
                .padding(.leading, 8)
                        
            Image(AmityIcon.brandBadge.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.leading, 4)
                .opacity(user.isBrand ? 1 : 0)
            
            if let menuButtonAction {
                Spacer()
                Button {
                    menuButtonAction(user)
                } label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 18)
                }
            } else {
                Spacer()
            }
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
