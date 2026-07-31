//
//  ChatReactionListContent.swift
//  AmityUIKit4
//
//  Design-system clone of ReactionListContent / ReactionListRowItem for the Chat
//  (.message) reaction list. Figma [UIKit 4.0] Chat (xt0KYneEXrCO37HBIFgYT9)
//  10848:54968 (populated) / 10848:54974 (empty). Reuses the shared ReactionLoader,
//  ReactionUser and AmityReactionListViewModel.
//

import SwiftUI
import AmitySDK

struct ChatReactionListContent: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @StateObject var viewModel: ReactionLoader
    @ObservedObject var parentViewModel: AmityReactionListViewModel

    @Environment(\.presentationMode) private var dismissScreen

    init(viewModel: ReactionLoader, parentViewModel: AmityReactionListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.parentViewModel = parentViewModel
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.reactedUsers.enumerated()), id: \.element.uniqueId) { index, user in
                        ChatReactionListRowItem(user: user)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard user.isLoggedInUser else {
                                    /// Dismiss the presented view controller(s) before navigating in the
                                    /// underlying UINavigationController (mirrors ReactionListContent).
                                    host.controller?.navigationController?.presentedViewController?.dismiss(animated: false)
                                    host.controller?.navigationController?.presentedViewController?.dismiss(animated: false)
                                    goToUserProfilePage(user.userId)
                                    return
                                }

                                guard !parentViewModel.isParentDeleted else { return }

                                viewModel.removeReaction(reactionName: user.reactionName)
                                dismissScreen.wrappedValue.dismiss()
                            }
                            .onAppear {
                                if index == viewModel.reactedUsers.count - 1 {
                                    viewModel.loadMore()
                                }
                            }
                    }
                }
            }
            .zIndex(1)
            .opacity(showsEmptyState ? 0 : 1)

            // Shimmer loading state
            if viewModel.initialQueryState == .loading && !parentViewModel.isParentDeleted {
                loadingState
                    .zIndex(2)
            }

            Group {
                if emptyStateImage == AmityIcon.emptyReaction.rawValue {
                    reactionEmptyState
                } else {
                    // Error / unable-to-load state (with retry) — not covered by the Figma;
                    // reuse the shared empty-state view to preserve behavior.
                    AmityEmptyStateView(configuration: viewModel.emptyStateConfiguration)
                }
            }
            .zIndex(3)
            .opacity(showsEmptyState ? 1 : 0)
        }
        .onAppear(perform: {
            viewModel.getReactedUsers()
        })
        .onChange(of: parentViewModel.isParentDeleted) { isDeleted in
            if isDeleted {
                viewModel.clearForParentDeletion()
            }
        }
    }

    // MARK: - Empty-state derivation

    private var showsEmptyState: Bool {
        parentViewModel.isParentDeleted || viewModel.isEmptyStateVisible
    }

    private var emptyStateImage: String? {
        parentViewModel.isParentDeleted
            ? AmityIcon.emptyReaction.rawValue
            : viewModel.emptyStateConfiguration.image
    }

    private var reactionEmptyState: some View {
        VStack(spacing: 0) {
            Image(AmityIcon.DesignSystem.smilePlusR.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(Color(viewConfig.color(.iconEmptyStateIconDefault)))
                .padding(.bottom, 16)

            Text(AmityLocalizedStringSet.Reaction.noReactionTitle.localizedString)
                .applyTextStyle(.titleBold(Color(viewConfig.color(.textEmptyStateTitleDefault))))

            Text(AmityLocalizedStringSet.Reaction.noReactionSubtitle.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.color(.textEmptyStateDescriptionDefault))))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 16)
    }

    var loadingState: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<11, id: \.self) { _ in
                    ChatReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }

    private func goToUserProfilePage(_ userId: String) {
        let page = AmityUserProfilePage(userId: userId)
        let vc = AmitySwiftUIHostingController(rootView: page)
        host.controller?.navigationController?.pushViewController(vc, animated: true)
    }
}

struct ChatReactionListRowItem: View {

    @EnvironmentObject private var viewConfig: AmityViewConfigController

    let user: ReactionUser
    let isPlaceholder: Bool

    init(user: ReactionUser, isPlaceholder: Bool = false) {
        self.user = user
        self.isPlaceholder = isPlaceholder
    }

    var body: some View {
        HStack(spacing: 0) {
            let displayName = user.displayName
            AmityChatUserProfileImageView(displayName: displayName, avatarURL: URL(string: user.avatarURL))
                .frame(width: 32, height: 32)
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .shimmering(active: isPlaceholder)
                .clipShape(Circle())
                .padding(.trailing, 12)
                .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.userAvatarView)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(user.displayName)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(.textListHeaderDefaultDefault))))
                        .textShimmerEffect(cornerRadius: 10, isActive: isPlaceholder, color: viewConfig.color(.surfaceSkeletonEffectDefault))
                        .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.userDisplayName)
                        .lineLimit(1)

                    Image(AmityIcon.brandBadge.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding(.leading, 4)
                        .opacity(user.isBrand ? 1 : 0)
                }

                Text(AmityLocalizedStringSet.Reaction.tapToRemove.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textListTextDescriptionDefaultDefault))))
                    .textShimmerEffect(cornerRadius: 10, isActive: isPlaceholder, color: viewConfig.color(.surfaceSkeletonEffectDefault))
                    .padding(.top, 4)
                    .isHidden(!user.isLoggedInUser)
                    .accessibilityIdentifier(AmityLocalizedStringSet.Reaction.tapToRemove.localizedString)
            }

            Spacer()

            Image(user.reactionImage)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .shimmering(active: isPlaceholder)
                .clipShape(Circle())
                .padding(.trailing, 8)
                .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.reactionImageView)
        }
        .compositingGroup()
    }
}
