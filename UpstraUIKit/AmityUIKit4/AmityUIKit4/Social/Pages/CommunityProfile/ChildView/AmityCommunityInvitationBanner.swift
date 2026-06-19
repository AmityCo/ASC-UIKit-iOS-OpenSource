//
//  AmityCommunityInvitationBanner.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/19/25.
//

import AmitySDK
import SwiftUI

public struct AmityCommunityInvitationBanner: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCommunityInvitationBannerViewModel
    private var communityProifleViewModel: CommunityProfileViewModel?

    public var pageId: PageId?

    public var id: ComponentId {
        .communityInvitationBanner
    }

    private let community: AmityCommunity

    public init(community: AmityCommunity, pageId: PageId? = nil) {
        self.community = community
        self._viewModel = StateObject(
            wrappedValue: AmityCommunityInvitationBannerViewModel(community: community))
    }

    init(
        community: AmityCommunity, viewModel: CommunityProfileViewModel? = nil,
        pageId: PageId? = nil
    ) {
        self.community = community
        self.communityProifleViewModel = viewModel
        self._viewModel = StateObject(
            wrappedValue: AmityCommunityInvitationBannerViewModel(
                community: community, invitation: viewModel?.pendingCommunityInvitation))
    }

    @State private var isDeclineAlertShown = false

    public var body: some View {
        bannerView
    }

    private var bannerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                let inviter = viewModel.pendingInvitaion?.inviterUser
                AmityUserProfileImageView(
                    displayName: inviter?.displayName ?? "",
                    avatarURL: inviter?.resolvedAvatarURL(size: .medium)
                )
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                HStack(spacing: 12) {
                    Color.clear
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                    // "Hasan John mentioned you in a poll on their feed"
                    if #available(iOS 15, *) {
                        Text(getHightlightedText())
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            .lineLimit(3)
                            .truncationMode(.middle)
                    } else {
                        Text(getText())
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            .lineLimit(3)
                            .truncationMode(.middle)
                    }
                }
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
                            if let invitation = viewModel.pendingInvitaion,
                                case let .community(_, community) = invitation.target,
                                let community
                            {
                                do {
                                    try await invitation.accept()
                                    communityProifleViewModel?.refreshFeed()

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        Toast.showToast(
                                            style: .success,
                                            message: String(format: AmityLocalizedStringSet.Social.communityInvitationJoinedFormat.localizedString, community.displayName))
                                    }
                                } catch {
                                    if error.isAmityErrorCode(.business) {
                                        if community.isPublic == false {
                                            host.controller?.navigationController?
                                                .popViewController(animated: true)
                                        }
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
        }
        .padding(12)
        .background(Color(viewConfig.theme.backgroundShade1Color))
        .cornerRadius(8)
        .padding(.horizontal)
        .alert(isPresented: $isDeclineAlertShown) {
            Alert(
                title: Text(AmityLocalizedStringSet.Social.declineInvitationTitle.localizedString),
                message: Text(AmityLocalizedStringSet.Social.declineInvitationMessage.localizedString),
                primaryButton: .cancel(),
                secondaryButton: .destructive(
                    Text(AmityLocalizedStringSet.Social.declineButton.localizedString),
                    action: {

                        Task { @MainActor in
                            if let invitation = viewModel.pendingInvitaion,
                                case let .community(_, community) = invitation.target,
                                let community
                            {
                                do {
                                    try await invitation.reject()
                                    // Stay on the community profile page for both public and private communities.
                                    // Clear the invitation banner and reset join status so the [Join] button appears.
                                    communityProifleViewModel?.pendingCommunityInvitation = nil
                                    communityProifleViewModel?.joinStatus = .notJoined
                                    Toast.showToast(
                                        style: .success, message: AmityLocalizedStringSet.Social.communityInvitationDeclined.localizedString)
                                } catch {
                                    if error.isAmityErrorCode(.business) {
                                        // Invitation already expired — clear the banner and stay on the page
                                        communityProifleViewModel?.pendingCommunityInvitation = nil
                                        communityProifleViewModel?.joinStatus = .notJoined
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
                        }
                    }))
        }
    }

    private func getText() -> String {
        guard let invitation = viewModel.pendingInvitaion else {
            return ""
        }

        if case let .community(_, community) = invitation.target, let community {
            return
                "\(invitation.inviterUser?.displayName ?? AmityLocalizedStringSet.General.unknown.localizedString) invited you to join \(community.displayName)"
        }

        return ""
    }

    @available(iOS 15, *)
    private func getHightlightedText() -> AttributedString {
        guard let invitation = viewModel.pendingInvitaion else {
            return AttributedString()
        }

        if case let .community(_, community) = invitation.target, let community {
            let inviterName = invitation.inviterUser?.displayName ?? AmityLocalizedStringSet.General.unknown.localizedString
    
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 15),
                .foregroundColor: Color(viewConfig.theme.baseColor),
            ]

            // Create attributed string by building it in parts
            let attributedString = NSMutableAttributedString()

            // Add inviter name (bold)
            attributedString.append(
                NSAttributedString(string: "\(inviterName) invited you.", attributes: boldAttributes))

            return AttributedString(attributedString)
        }

        return AttributedString()
    }
}

class AmityCommunityInvitationBannerViewModel: ObservableObject {
    @Published var pendingInvitaion: AmityInvitation?
    private let community: AmityCommunity

    init(community: AmityCommunity, invitation: AmityInvitation? = nil) {
        self.community = community
        self.pendingInvitaion = invitation

        if invitation == nil {
            loadPendingInvitation()
        }
    }

    func loadPendingInvitation() {
        Task { @MainActor in pendingInvitaion = await community.getInvitation() }
    }
}
