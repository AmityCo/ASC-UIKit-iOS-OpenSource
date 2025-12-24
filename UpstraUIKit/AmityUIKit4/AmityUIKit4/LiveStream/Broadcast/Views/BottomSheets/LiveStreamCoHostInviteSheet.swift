//
//  LiveStreamCoHostInviteSheet.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/10/25.
//

import SwiftUI
import AmitySDK

struct LiveStreamCoHostInviteSheet: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @Environment(\.presentationMode) private var presentationMode
    
    @StateObject private var viewModel: LiveStreamCoHostInviteViewModel

    let viewers: [LiveStreamViewer] = []
    let onDismiss: () -> Void
    
    init(conferenceViewModel: LiveStreamConferenceViewModel,
         onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: LiveStreamCoHostInviteViewModel(conferenceViewModel: conferenceViewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColorShade3))
            
            headerView
            
            Rectangle()
                .fill(Color(viewConfig.defaultDarkTheme.baseColorShade4))
                .frame(height: 1)
            
            invitedCoHostSection
            
            if viewModel.viewers.isEmpty && viewModel.conferenceViewModel.invitedCoHost.user == nil {
                EmptyViewersState()
                    .padding(.top, 95)
                Spacer()
            } else if !viewModel.viewers.isEmpty {
                viewerListSection
            } else {
                Spacer()
            }
        }
        .background(Color(viewConfig.defaultDarkTheme.backgroundColor))
        .onAppear {
            viewModel.loadViewers()
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Spacer()
            
            Text(AmityLocalizedStringSet.Social.livestreamInviteCoHostTitle.localizedString)
                .applyTextStyle(.titleBold(.white))
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(AmityIcon.closeIcon.imageResource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var invitedCoHostSection: some View {
        let invitedCoHost = viewModel.conferenceViewModel.invitedCoHost
        
        if let user = invitedCoHost.user {
            let title = invitedCoHost.invitationAccepted ? AmityLocalizedStringSet.Social.livestreamCoHostingSectionTitle.localizedString : "Pending Invitation"
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .applyTextStyle(.titleBold(.white))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            let buttonTitle = invitedCoHost.invitationAccepted ? AmityLocalizedStringSet.Social.livestreamRemoveCoHostButton.localizedString : AmityLocalizedStringSet.Social.livestreamCancelInvitationButton.localizedString
            ViewerRow(viewer: user, buttonTitle: buttonTitle, enableButton: true, action: {
                Task.runOnMainActor {
                    if invitedCoHost.invitationAccepted {
                        // Remove co-host if already accepted invitation
                        do {
                            try await self.viewModel.removeCoHostFromStream(userId: user.userId)
                            Toast.showToast(style: .success, message: "Co-host removed from live.", bottomPadding: 60)
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to remove co-host.", bottomPadding: 60)
                        }
                    } else {
                        // Decline co-host invitation if not yet accepted
                        do {
                            try await self.viewModel.declineAsCoHost(user: user)
                            Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationCancelledToast.localizedString, bottomPadding: 60)
                        } catch {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationCancelFailedToast.localizedString, bottomPadding: 60)
                        }
                    }
                }
            })
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    @ViewBuilder
    private var viewerListSection: some View {
        // Header
        VStack(alignment: .leading, spacing: 16) {
            Text(AmityLocalizedStringSet.Social.livestreamWhosWatchingTitle.localizedString)
                .applyTextStyle(.titleBold(.white))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
        
        // List
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.viewers, id: \.userId) { viewer in
                    let userModel = AmityUserModel(user: viewer)
                    ViewerRow(
                        viewer: userModel,
                        buttonTitle: AmityLocalizedStringSet.Social.livestreamInviteButton.localizedString,
                        enableButton: viewModel.conferenceViewModel.invitedCoHost.user == nil,
                        action: {
                            showConfirmationAlert {
                                Task.runOnMainActor {
                                    do {
                                        try await self.viewModel.inviteAsCoHost(user: userModel)
                                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.livestreamInvitationSentToast.localizedString, bottomPadding: 60)
                                    } catch {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.livestreamInvitationSendFailedToast.localizedString, bottomPadding: 60)
                                    }
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private func showConfirmationAlert(onInvite: @escaping () -> Void) {
        presentationMode.wrappedValue.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let alert = UIAlertController(title: AmityLocalizedStringSet.Social.livestreamConfirmInviteCoHostTitle.localizedString, message: AmityLocalizedStringSet.Social.livestreamConfirmInviteCoHostMessage.localizedString, preferredStyle: .alert)

            let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: AmityLocalizedStringSet.Social.livestreamInviteButton.localizedString, style: .default) { _ in
                onInvite()
            }
            
            alert.addAction(cancelAction)
            alert.addAction(confirmAction)
            
            alert.preferredAction = confirmAction
            host.controller?.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - ViewerRow Component
private struct ViewerRow: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let viewer: AmityUserModel
    let buttonTitle: String
    let enableButton: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            AmityUserProfileImageView(
                displayName: viewer.displayName,
                avatarURL: URL(string: viewer.avatarURL)
            )
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(viewer.displayName)
                        .applyTextStyle(.bodyBold(.white))
                    
                    // Brand badge
                    if viewer.isBrand {
                        Image(AmityIcon.brandBadge.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(.leading, -4)
                    }
                }
            }
            
            Spacer()
            
            // Invite button
            Button {
                guard enableButton else { return }
                action()
            } label: {
                Text(buttonTitle)
                    .applyTextStyle(.captionBold(.white))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(viewConfig.theme.primaryColor))
                    .cornerRadius(6)
                    .overlay(Color.black.opacity(0.3).isHidden(enableButton))
            }

        }
    }
}

// MARK: - EmptyViewersState Component
private struct EmptyViewersState: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                
                Image(AmityIcon.inviteUserIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .frame(size: CGSize(width: 64, height: 48))
                    .foregroundColor(Color(viewConfig.defaultDarkTheme.baseColorShade3))
                    .padding(.bottom, 12)
                                
                Text(AmityLocalizedStringSet.Social.livestreamNoViewersTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                    .multilineTextAlignment(.center)

                Text(AmityLocalizedStringSet.Social.livestreamNoViewersMessage.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.defaultDarkTheme.baseColorShade2)))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Data model for a viewer who can be invited
struct LiveStreamViewer: Identifiable, Hashable {
    let id: String
    let displayName: String
    let avatarURL: URL?

    init(id: String, displayName: String, avatarURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}
