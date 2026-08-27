//
//  AmityModeratorBadge.swift
//  AmityUIKit4
//
//  Single source of truth for the moderator badge (Social/legacy theme).
//  Both variants tint the shield glyph with the Dynamic UI primary color, so a
//  colour/style change only has to happen here.
//
//  - `AmityModeratorAvatarBadge`: the small shield-in-a-circle overlaid on the
//    bottom-trailing corner of a moderator's avatar.
//  - `AmityModeratorLabelBadge`: the shield + label pill shown next to a
//    moderator's name.
//
//  Note: `viewConfig` is passed explicitly (not via @EnvironmentObject) so these
//  views are safe to drop into any context, matching `DefaultCommunityPlaceholder`.
//

import SwiftUI

/// Shield badge overlaid on the bottom-trailing corner of a moderator's avatar.
struct AmityModeratorAvatarBadge: View {
    let viewConfig: AmityViewConfigController
    var size: CGFloat = 18
    var iconSize: CGFloat = 16

    var body: some View {
        Color(viewConfig.theme.primaryColor.blend(.shade3))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Image(AmityIcon.moderatorBadgeIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                    .frame(width: iconSize, height: iconSize)
            )
    }
}

/// Shield + label pill shown next to a moderator's name.
struct AmityModeratorLabelBadge: View {
    let viewConfig: AmityViewConfigController
    var icon: ImageResource
    var title: String
    var iconSize: CGFloat
    var height: CGFloat

    init(viewConfig: AmityViewConfigController,
         icon: ImageResource? = nil,
         title: String? = nil,
         iconSize: CGFloat = 12,
         height: CGFloat = 20) {
        self.viewConfig = viewConfig
        self.icon = icon ?? AmityIcon.moderatorBadgeIcon.getImageResource()
        self.title = title ?? AmityLocalizedStringSet.General.moderator.localizedString
        self.iconSize = iconSize
        self.height = height
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(Color(viewConfig.theme.primaryColor))
                .padding(.leading, 6)
            Text(title)
                .applyTextStyle(.captionSmall(Color(viewConfig.theme.primaryColor)))
                .padding(.trailing, 6)
        }
        .frame(height: height)
        .background(Color(viewConfig.theme.primaryColor.blend(.shade3)))
        .clipShape(RoundedCorner(radius: 10))
    }
}
