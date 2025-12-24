//
//  LiveStreamCoHostJoinSheet.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/5/25.
//

import SwiftUI
import AmitySDK

struct LiveStreamCoHostJoinSheet: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    @ObservedObject private var viewModel: AmityLiveStreamPlayerPageViewModel
    private let onAccept: () -> Void
    private let onDecline: () -> Void
    
    init(viewModel: AmityLiveStreamPlayerPageViewModel,
         onAccept: @escaping () -> Void,
         onDecline: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onAccept = onAccept
        self.onDecline = onDecline
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile images section
            HStack(spacing: -5) {
                // Host profile image
                AmityUserProfileImageView(displayName: viewModel.coHostInvitation?.inviterUser?.displayName ?? "Host", avatarURL: URL(string: viewModel.coHostInvitation?.inviterUser?.getAvatarInfo()?.fileURL ?? ""))
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(viewConfig.defaultDarkTheme.backgroundColor), lineWidth: 3)
                    )
                    .overlay(
                        HostBadgeView()
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(viewConfig.defaultDarkTheme.backgroundColor), lineWidth: 1)
                            ), alignment: .bottom)

                // Co-host profile image
                AmityUserProfileImageView(displayName: viewModel.coHostInvitation?.invitedUser?.displayName ?? AmityUIKitManagerInternal.shared.client.user?.snapshot?.displayName ?? "CoHost", avatarURL: URL(string: viewModel.coHostInvitation?.invitedUser?.getAvatarInfo()?.fileURL ?? ""))
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(viewConfig.defaultDarkTheme.backgroundColor), lineWidth: 3)
                    )
            }
            .padding(.top, 32)

            VStack(spacing: 16) {
                // Title
                Text(AmityLocalizedStringSet.Social.livestreamJoinAsCoHostTitle.localizedString)
                    .applyTextStyle(.headline(.white))

                // Description
                Text(String(format: AmityLocalizedStringSet.Social.livestreamJoinAsCoHostMessage.localizedString, viewModel.coHostInvitation?.inviterUser?.displayName ?? "Host"))
                    .applyTextStyle(.body(Color(viewConfig.defaultDarkTheme.baseColorShade1)))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 12) {
                // Accept button
                Button(action: onAccept) {
                    Text(AmityLocalizedStringSet.Social.livestreamAcceptButton.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                // Decline button
                Button(action: onDecline) {
                    Text(AmityLocalizedStringSet.Social.livestreamDeclineButton.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.defaultDarkTheme.baseColor)))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(viewConfig.defaultDarkTheme.baseColorShade3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
    }
}
