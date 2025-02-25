//
//  ReactionListContent.swift
//  AmityUIKit4
//
//  Created by Nishan on 16/5/2567 BE.
//

import SwiftUI
import AmitySDK

struct ReactionListContent: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @StateObject var viewModel: ReactionLoader
    
    @Environment(\.presentationMode) private var dismissScreen
    
    init(viewModel: ReactionLoader) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.reactedUsers.enumerated()), id: \.element.userId) { index, user in
                        Section {
                            ReactionListRowItem(user: user)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .onTapGesture {
                                    guard user.isLoggedInUser else {
                                        /// Dismiss the present viewcontroller twice for the case AmityReactionList is used from AmityCommentTrayComponent which is presented view controller itself. It does not have any effect if there is no another presented view controller in the normal case like using it from AmityPostContentComponent.
                                        /// iOS needs to dismiss presented view controller first before making navigation in underlying UINavigationController.
                                        host.controller?.navigationController?.presentedViewController?.dismiss(animated: false)
                                        host.controller?.navigationController?.presentedViewController?.dismiss(animated: false)
                                        goToUserProfilePage(user.userId)
                                        return
                                    }
                                    
                                    viewModel.removeReaction(reactionName: user.reactionName)
                                    
                                    // Dismiss Screen
                                    dismissScreen.wrappedValue.dismiss()
                                }
                            
                            if index != viewModel.reactedUsers.count - 1 {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 2)
                            }
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
            .opacity(viewModel.isEmptyStateVisible ? 0 : 1)
            
            // Shimmer loading state
            if viewModel.initialQueryState == .loading {
                loadingState
                    .zIndex(2)
            }
            
            AmityEmptyStateView(configuration: viewModel.emptyStateConfiguration)
                .zIndex(3)
                .opacity(viewModel.isEmptyStateVisible ? 1 : 0)
        }
        .onAppear(perform: {
            viewModel.getReactedUsers()
        })
    }
    
    var loadingState: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                ReactionListRowItem(user: ReactionUser.placeholder, isPlaceholder: true)
                
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

struct ReactionListRowItem: View {
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let user: ReactionUser
    let isPlaceholder: Bool
    
    init(user: ReactionUser, isPlaceholder: Bool = false) {
        self.user = user
        self.isPlaceholder = isPlaceholder
    }
    
    var body: some View {
        HStack(spacing: 0) {
            AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: URL(string: user.avatarURL))
                .frame(width: 32, height: 32)
                .redacted(reason: isPlaceholder ? .placeholder : [])
                .shimmering(active: isPlaceholder)
                .clipShape(Circle())
                .padding(.trailing, 12)
                .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.userAvatarView)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(user.displayName)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                    .textShimmerEffect(cornerRadius: 10, isActive: isPlaceholder, color: viewConfig.theme.baseInverseColor)
                    .accessibilityIdentifier(AccessibilityID.Chat.ReactionList.userDisplayName)
                
                Text(AmityLocalizedStringSet.Reaction.tapToRemove.localizedString)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .textShimmerEffect(cornerRadius: 10, isActive: isPlaceholder, color: viewConfig.theme.baseInverseColor)
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

class ReactionLoader: ObservableObject {
    
    enum QueryState {
        case loading
        case success
        case error
    }
    
    @Published var reactedUsers: [ReactionUser] = []
    @Published var isEmptyStateVisible = false

    private var reactionCollection: AmityCollection<AmityReaction>?
    private let reactionManger = ReactionManager()
    @Published var initialQueryState: QueryState = .loading

    let referenceId: String
    let referenceType: AmityReactionReferenceType
    let reactionType: String?

    var reactionCollectionToken: AmityNotificationToken?
    
    @Published var emptyStateConfiguration = AmityEmptyStateView.Configuration(image: AmityIcon.Chat.greyRetryIcon.rawValue, title: AmityLocalizedStringSet.Reaction.unableToLoadTitle.localizedString, subtitle: nil, tapAction: nil)
    
    init(referenceId: String, referenceType: AmityReactionReferenceType, reactionName: String?) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.reactionType = reactionName
    }
    
    func getReactedUsers() {
        reactedUsers = []
        resetState()
        
        reactionCollection = reactionManger.getReactions(reactionType, referenceId: referenceId, referenceType: referenceType)
        reactionCollectionToken = reactionCollection?.observe({ [weak self] liveCollection, _, error in
            guard let self else { return }
            
            if let error {
                Log.chat.warning("Error occurred when querying for reaction list \(error.localizedDescription)")
                
                // Same observer can get triggered in case of pagination.
                if initialQueryState == .loading {
                    initialQueryState = .error
                    
                    // Show unable to load reactions empty state with retry option
                    let configuration = AmityEmptyStateView.Configuration(image: AmityIcon.Chat.greyRetryIcon.rawValue, title: AmityLocalizedStringSet.Reaction.unableToLoadTitle.localizedString, subtitle: nil, tapAction: {
                        // Retry
                        self.getReactedUsers()
                    })
                    self.emptyStateConfiguration = configuration
                    self.isEmptyStateVisible = true
                }
                
                return
            }
            
            // Map reactions
            let reactions = liveCollection.allObjects()
            self.reactedUsers = reactions.map { ReactionUser(reaction: $0) }
            
            // Reacted Users
            if reactedUsers.isEmpty {
                displayNoReactionEmptyState()
            } else {
                self.isEmptyStateVisible = false
            }
            
            // Set query state so that screen can be shown.
            self.initialQueryState = .success
        })
    }
    
    func loadMore() {
        guard let collection = reactionCollection, collection.hasNext else { return }
        collection.nextPage()
    }

    func removeReaction(reactionName: String) {
        Task { @MainActor in
            do {
                try await reactionManger.removeReaction(reactionName, referenceId: referenceId, referenceType: referenceType)
            } catch let error {
                Log.reaction.warning("Error occurred while removing reaction \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        reactionCollectionToken?.invalidate()
        reactionCollectionToken = nil
    }
    
    func displayNoReactionEmptyState() {
        let configuration = AmityEmptyStateView.Configuration(image: AmityIcon.emptyReaction.rawValue, title: AmityLocalizedStringSet.Reaction.noReactionTitle.localizedString, subtitle: AmityLocalizedStringSet.Reaction.noReactionSubtitle.localizedString, iconSize: CGSize(width: 32, height: 32), tapAction: nil)
        self.emptyStateConfiguration = configuration
        self.isEmptyStateVisible = true
    }
    
    func resetState() {
        initialQueryState = .loading
        isEmptyStateVisible = false
    }
}

struct ReactionUser {
    let userId: String
    let displayName: String
    let avatarURL: String
    let reactionName: String
    let reactionImage: ImageResource
    
    init(reaction: AmityReaction) {
        self.userId = reaction.creator?.userId ?? ""
        self.displayName = reaction.creator?.displayName ?? ""
        self.avatarURL = reaction.creator?.getAvatarInfo()?.fileURL ?? ""
        self.reactionName = reaction.reactionName
        self.reactionImage = MessageReactionConfiguration.shared.getReaction(withName: reaction.reactionName).image
    }
    
    var isLoggedInUser: Bool {
        return !userId.isEmpty && userId == AmityUIKit4Manager.client.currentUserId ?? ""
    }
    
    internal init(userId: String, displayName: String, avatarURL: String, reactionName: String) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.reactionName = reactionName
        self.reactionImage = MessageReactionConfiguration.shared.getReaction(withName: reactionName).image
    }
    
    // Used for skeleton loading
    static let placeholder = ReactionUser(userId: UUID().uuidString, displayName: "Hi Unknown User sir", avatarURL: "", reactionName: "")
}
