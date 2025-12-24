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
    let item: NotificationItem
    
    var body: some View {
        HStack(spacing: 0) {
            
            switch item.trayItemCategory {
            case .eventReminder, .eventStarted:
                let eventUrl = item.event?.coverImage?.mediumFileURL ?? ""
                AsyncImage(placeholder: AmityIcon.eventImagePlaceholder.imageResource, url: URL(string: eventUrl), contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
        .background(
            Color(
                item.isSeen
                ? viewConfig.theme.backgroundColor
                : viewConfig.theme.primaryColor.blend(.shade3)))
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
                avatarURL: URL(string: inviter?.getAvatarInfo()?.mediumFileURL ?? "")
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
                            Text("Join")
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
                                            message: "You joined \(community.displayName)")
                                    }
                                } catch {
                                    if error.isAmityErrorCode(.business) {
                                        Toast.showToast(
                                            style: .warning,
                                            message: "This invitation is no longer available.")
                                    } else {
                                        Toast.showToast(
                                            style: .warning,
                                            message:
                                                "Failed to accept invitation. Please try again.")
                                    }
                                }
                            }
                        }
                    
                    Rectangle()
                        .fill(.clear)
                        .overlay(
                            Text("Decline")
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
                title: Text("Decline invitation?"),
                message: Text("If you change your mind, you’ll have to request to join again."),
                primaryButton: .cancel(),
                secondaryButton: .destructive(
                    Text("Decline"),
                    action: {
                        Task { @MainActor in
                            do {
                                try await invitation.reject()
                                Toast.showToast(style: .success, message: "Invitation declined.")
                            } catch {
                                if error.isAmityErrorCode(.business) {
                                    Toast.showToast(
                                        style: .warning,
                                        message: "This invitation is no longer available.")
                                } else {
                                    Toast.showToast(
                                        style: .warning,
                                        message: "Failed to decline invitation. Please try again.")
                                }
                            }
                        }
                    }))
        }
    }
    
    private func getText() -> String {
        if case let .community(_, community) = invitation.target, let community {
            return
            "\(invitation.inviterUser?.displayName ?? "Unknown") invited you to join \(community.displayName)"
        }
        
        return ""
    }
    
    @available(iOS 15, *)
    private func getHightlightedText() -> AttributedString {
        if case let .community(_, community) = invitation.target, let community {
            let inviterName = invitation.inviterUser?.displayName ?? "Unknown"
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
                NSAttributedString(string: " invited you to join ", attributes: regularAttributes))
            
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
