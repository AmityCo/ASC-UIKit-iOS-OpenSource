//
//  BadgeViews.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/13/25.
//

import SwiftUI

struct HostBadgeView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 2) {
            Image(AmityIcon.LiveStream.hostIcon.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 9)

            Text(AmityLocalizedStringSet.Social.livestreamHostBadge.localizedString)
                .applyTextStyle(.captionSmall(.white))
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(Color(UIColor(hex: "#FF305A")))
        .cornerRadius(4.0, corners: .allCorners)
    }
}

struct CoHostBadgeView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 2) {
            Image(AmityIcon.Chat.membersCount.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 9)

            Text(AmityLocalizedStringSet.Social.livestreamCoHostBadge.localizedString)
                .applyTextStyle(.captionSmall(.white))
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(Color(UIColor(hex: "#FF305A")))
        .cornerRadius(4.0, corners: .allCorners)
    }
}

struct ModeratorBadgeView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    var body: some View {
        HStack(spacing: 2) {
            Image(AmityIcon.moderatorBadgeIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .foregroundColor(.white)
                .frame(width: 10, height: 12)
                .offset(y: -1)
            
            Text(AmityLocalizedStringSet.Social.livestreamModeratorBadge.localizedString)
                .applyTextStyle(.captionSmall(.white))
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(Color(viewConfig.defaultDarkTheme.backgroundShade1Color))
        .cornerRadius(4.0, corners: .allCorners)
    }
}
