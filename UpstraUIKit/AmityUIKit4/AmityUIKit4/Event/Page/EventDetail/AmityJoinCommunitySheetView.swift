//
//  AmityJoinCommunitySheetView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 13/11/25.
//

import SwiftUI
import AmitySDK

struct AmityJoinCommunitySheetView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    let community: AmityCommunity?
    let user: AmityUser?
    let canRSVPEvent: Bool
    
    let joinAction: DefaultTapAction?
    let cancelAction: DefaultTapAction?
    
    var body: some View {
        VStack(spacing: 0) {
            avatar
                .padding(.top, 32)

            Text(AmityLocalizedStringSet.Social.joinCommunitySheetTitle.localizedString)
                .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                .padding(.bottom, 8)
                .padding(.top, 32)

            let displayName = community?.displayName ?? ""
            Text(String(format: AmityLocalizedStringSet.Social.joinCommunitySheetDescription.localizedString, displayName))
                .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
                .padding(.top, 16)

            VStack(spacing: 12) {
                let buttonTitle = canRSVPEvent ? AmityLocalizedStringSet.Social.joinCommunitySheetJoinAndRsvp.localizedString : AmityLocalizedStringSet.Social.joinCommunitySheetJoin.localizedString
                Button {
                    joinAction?()
                } label: {
                    Text(buttonTitle)
                }
                .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))

                Button {
                    cancelAction?()
                } label: {
                    Text(AmityLocalizedStringSet.Social.joinCommunitySheetCancel.localizedString)
                }
                .buttonStyle(AmityLineButtonStyle(viewConfig: viewConfig))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
    }
    
    var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            commAvatarPlaceholder
            
            userAvatarPlaceholder
        }
    }
    
    var commAvatarPlaceholder: some View {
        AsyncImage(placeholderView: {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(AmityIcon.communityPeopleIcon.imageResource)
                        .resizable()
                        .frame(width: 72, height: 42)
                        .padding(.bottom, 8)
                )
        }, url: URL(string: community?.avatar?.fileURL ?? ""))
        .frame(width: 120, height: 120)
        .cornerRadius(24, corners: .allCorners)
    }
    
    var userAvatarPlaceholder: some View {
        AmityUserProfileImageView(displayName: user?.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString, avatarURL: URL(string: user?.getAvatarInfo()?.fileURL ?? ""))
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .border(radius: 40, borderColor: Color(viewConfig.theme.backgroundColor), borderWidth: 4)
            .offset(x: 20, y: 8)
    }
    
}
