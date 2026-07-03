//
//  NotificationTrayItemView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/25.
//

import AmitySDK
import SwiftUI

struct NotificationTraySectionTitle: View {
    
    let title: String
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    var body: some View {
        Text(title)
            .applyTextStyle(.captionBold(Color(viewConfig.theme.baseColorShade2)))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
    }
}

struct NotificationTrayItemView: View {

    @EnvironmentObject var viewConfig: AmityViewConfigController
    @Environment(\.colorScheme) private var colorScheme
    let item: NotificationItem
    
    var body: some View {
        HStack(spacing: 0) {
            
            switch item.trayItemCategory {
            case .eventReminder, .eventStarted:
                let eventUrl = item.event?.coverImage?.mediumFileURL ?? ""
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: eventUrl), contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            case .userProfileReset:
                ZStack {
                    Circle()
                        .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                        .frame(width: 32, height: 32)
                    Image(AmityIcon.avatarPlaceholder.imageResource)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                }
            default:
                AmityUserProfileImageView(
                    displayName: item.users.first?.displayName ?? "",
                    avatarURL: URL(string: item.users.first?.avatarURL ?? "")
                )
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            // "Hasan John mentioned you in a poll on their feed"
            if #available(iOS 15, *) {
                // Work with attributed text here
                Text(item.getHighlightedText())
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.leading, 12)
            } else {
                Text(item.text)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                    .padding(.leading, 12)
            }
            
            Spacer(minLength: 12)
            
            Text(item.timestamp.relativeTime)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
        }
        .padding(16)
        .background(unreadRowBackground)
    }

    @ViewBuilder
    private var unreadRowBackground: some View {
        if item.isSeen {
            Color(viewConfig.theme.backgroundColor)
        } else {
            Color(colorScheme == .dark
                  //Figma display 0.3 but QA, designer would like set this on ios 0.2
                  ? viewConfig.theme.primaryColor.withAlphaComponent(0.2)
                  : viewConfig.theme.primaryColor.blend(.shade3).withAlphaComponent(0.3))
                
        }
    }
}

struct NotificationTrayInvitationItemView: View {
    @EnvironmentObject var host: AmitySwiftUIHostWrapper
    @EnvironmentObject var viewConfig: AmityViewConfigController
    let invitation: AmityInvitation
    
    @State private var isDeclineAlertShown = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            let inviter = invitation.inviterUser
            AmityUserProfileImageView(
                displayName: inviter?.displayName ?? "",
                avatarURL: inviter?.resolvedAvatarURL(size: .medium)
            )
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    // "Hasan John mentioned you in a poll on their feed"
                    if #available(iOS 15, *) {
                        Text(getHightlightedText())
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            .padding(.leading, 12)
                    } else {
                        Text(getText())
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            .padding(.leading, 12)
                    }
                    
                    Spacer(minLength: 12)
                    
                    Text(invitation.createdAt.relativeTime)
                        .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                }
                
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(viewConfig.theme.primaryColor))
                        .overlay(
                            Text(AmityLocalizedStringSet.General.join.localizedString)
                                .applyTextStyle(.bodyBold(.white))
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            Task { @MainActor in
                                do {
                                    try await invitation.accept()
                                    goToCommunityProfilePage()
                                    if case let .community(_, community) = invitation.target,
                                       let community
                                    {
                                        Toast.showToast(
                                            style: .success,
                                            message: String(format: AmityLocalizedStringSet.Social.communityInvitationJoinedFormat.localizedString, community.displayName))
                                    }
                                } catch {
                                    if error.isAmityErrorCode(.business) {
                                        Toast.showToast(
                                            style: .warning,
                                            message: AmityLocalizedStringSet.Social.communityInvitationExpired.localizedString)
                                    } else {
                                        Toast.showToast(
                                            style: .warning,
                                            message: AmityLocalizedStringSet.Social.notificationTrayAcceptInvitationFailed.localizedString)
                                    }
                                }
                            }
                        }
                    
                    Rectangle()
                        .fill(.clear)
                        .overlay(
Text(AmityLocalizedStringSet.Social.declineButton.localizedString)
                                .applyTextStyle(.bodyBold(Color(viewConfig.theme.secondaryColor)))
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 1)
                        )
                        .onTapGesture {
                            isDeclineAlertShown.toggle()
                        }
                }
                .frame(height: 40)
                .padding(.leading, 12)
            }
        }
        .padding(16)
        .alert(isPresented: $isDeclineAlertShown) {
            Alert(
                title: Text(AmityLocalizedStringSet.Social.declineInvitationTitle.localizedString),
                message: Text(AmityLocalizedStringSet.Social.declineInvitationMessage.localizedString),
                primaryButton: .cancel(),
                secondaryButton: .destructive(
                    Text(AmityLocalizedStringSet.Social.declineButton.localizedString),
                    action: {
                        Task { @MainActor in
                            do {
                                try await invitation.reject()
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.notificationTrayInvitationDeclinedToast.localizedString)
                            } catch {
                                if error.isAmityErrorCode(.business) {
                                    Toast.showToast(
                                        style: .warning,
                                        message: AmityLocalizedStringSet.Social.communityInvitationExpired.localizedString)
                                } else {
                                    Toast.showToast(
                                        style: .warning,
                                        message: AmityLocalizedStringSet.Social.notificationTrayDeclineFailed.localizedString)
                                }
                            }
                        }
                    }))
        }
    }
    
    private func getText() -> String {
        if case let .community(_, community) = invitation.target, let community {
            let inviterName = invitation.inviterUser?.displayName ?? AmityLocalizedStringSet.General.unknown.localizedString
            return String(format: AmityLocalizedStringSet.Social.notificationTrayInvitedToJoinFormat.localizedString, inviterName, community.displayName)
        }
        
        return ""
    }
    
    @available(iOS 15, *)
    private func getHightlightedText() -> AttributedString {
        if case let .community(_, community) = invitation.target, let community {
            let inviterName = invitation.inviterUser?.displayName ?? AmityLocalizedStringSet.General.unknown.localizedString
            let communityName = community.displayName
            
            // Define attributes
            let regularAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: Color(viewConfig.theme.baseColor),
            ]
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 15),
                .foregroundColor: Color(viewConfig.theme.baseColor),
            ]
            
            // Create attributed string by building it in parts
            let attributedString = NSMutableAttributedString()
            
            // Add inviter name (bold)
            attributedString.append(
                NSAttributedString(string: inviterName, attributes: boldAttributes))
            
            // Add middle text (regular)
            attributedString.append(
                NSAttributedString(string: AmityLocalizedStringSet.Social.notificationTrayInvitedToJoinSeparator.localizedString, attributes: regularAttributes))
            
            // Add community name (bold)
            attributedString.append(
                NSAttributedString(string: communityName, attributes: boldAttributes))
            
            return AttributedString(attributedString)
        }
        
        return AttributedString()
    }
    
    private func goToCommunityProfilePage() {
        let page = AmityCommunityProfilePage(communityId: invitation.targetId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}
