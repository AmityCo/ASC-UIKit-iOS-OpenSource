//
//  CommunityMemberView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/21/24.
//

import SwiftUI
import AmitySDK

struct CommunityMemberView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let communityMember: AmityCommunityMember
    private let isModerator: Bool
    private let onTapAction: (AmityCommunityMember) -> Void
    private let onMenuAction: (AmityCommunityMember) -> Void
    
    init(_ communityMember: AmityCommunityMember, isModerator: Bool, onTapAction: @escaping (AmityCommunityMember) -> Void, onMenuAction: @escaping (AmityCommunityMember) -> Void) {
        self.communityMember = communityMember
        self.isModerator = isModerator
        self.onTapAction = onTapAction
        self.onMenuAction = onMenuAction
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AmityUserProfileImageView(displayName: communityMember.user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: communityMember.user?.getAvatarInfo()?.largeFileURL ?? ""))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                if isModerator {
                    Color(viewConfig.theme.primaryColor.blend(.shade3))
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 16, height: 16)
                        )
                }
            }
            
            Text(communityMember.displayName)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
            if let isBrand = communityMember.user?.isBrand, isBrand {
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(.leading, -6)
            }
            
            Spacer()
            
            if(communityMember.userId != AmityUIKitManagerInternal.shared.currentUserId) {
                Button {
                    onMenuAction(communityMember)
                } label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .renderingMode(.template)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 18)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTapAction(communityMember)
        }
    }
}
