//
//  LiveStreamChatBylineView.swift
//  AmityUIKit4
//
//  The author byline row shared by the live chat bubble and the pinned-message banner:
//  display name + brand badge + host/co-host/moderator badge + muted icon. Presentational —
//  the parent resolves every flag and (for the bubble) supplies the name tap handler.
//

import SwiftUI

struct LiveStreamChatBylineView: View {

    let displayName: String
    let isBrand: Bool
    let isHost: Bool
    let isCoHost: Bool
    let isModerator: Bool
    /// Whether to show the muted icon. The parent owns the visibility rule (viewer role + owner).
    let showMutedIcon: Bool
    /// Tap handler for the name (moderation options). `nil` = name is not tappable (banner).
    var onNameTap: (() -> Void)? = nil

    @EnvironmentObject var viewConfig: AmityViewConfigController

    var body: some View {
        HStack(spacing: 6) {
            Text(displayName)
                .applyTextStyle(.captionSmall(Color(viewConfig.theme.baseColorShade1)))
                .lineLimit(1)
                .applyIf(onNameTap != nil) { view in
                    view.onTapGesture { onNameTap?() }
                }

            if isBrand {
                Image(AmityIcon.brandBadge.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }

            if isHost {
                HostBadgeView()
            } else if isCoHost {
                CoHostBadgeView()
            } else if isModerator {
                ModeratorBadgeView()
            }

            if showMutedIcon {
                Image(AmityIcon.clipMuteIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .frame(width: 16, height: 14)
            }
        }
    }
}
