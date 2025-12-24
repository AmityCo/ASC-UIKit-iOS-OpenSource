//
//  PostBottomSheetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/28/24.
//

import SwiftUI

struct PostBottomSheetView: View {
    
    enum PostAction {
        case editPost
        case deletePost
        case closePoll
        case reportPost
        case sharePost
    }
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let post: AmityPostModel
    private let action: ((PostAction) -> Void)?
    
    @Binding private var isShown: Bool
    @State private var showConfirmationAlert: Bool = false
    @State private var activeAlert: PostAction = .editPost
    
    @StateObject private var viewModel: PostBottomSheetViewModel = PostBottomSheetViewModel()
    
    init(isShown: Binding<Bool>, post: AmityPostModel, action: ((PostAction) -> Void)?) {
        self._isShown = isShown
        self.post = post
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if post.hasModeratorPermission {
                moderatorView
            } else {
                memberView
            }
        }
        .padding(.bottom, 64)
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .onAppear {
            viewModel.updatePostFlaggedByMeState(id: post.postId)
            viewModel.checkDeletePermission(post: post)
        }
        .alert(isPresented: $showConfirmationAlert, content: {
            
            switch activeAlert {
                // We do not need alert for report post
            case .editPost, .deletePost, .reportPost, .sharePost:
                return Alert(title: Text(AmityLocalizedStringSet.Social.deletePostTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.deletePostMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                    Task { @MainActor in
                        isShown.toggle()
                        NotificationCenter.default.post(name: .didPostLocallyDeleted, object: nil, userInfo: ["postId" : post.postId])

                        action?(.deletePost)
                        
                        do {
                            try await viewModel.deletePost(id: post.postId)
                            
                            /// Send didPostDeleted event to remove created post added in global feed data source
                            /// that is not from live collection
                            /// This event is observed in PostFeedViewModel
                            NotificationCenter.default.post(name: .didPostDeleted, object: nil, userInfo: ["postId" : post.postId])
                            
                            /// Delay showing toast as deleting post will effect post data source
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.postDeletedToastMessage.localizedString)
                            }
                        } catch let error {
                            Log.add(event: .info, "Error deleting post \(error)")
                            /// Delay showing toast as deleting post will effect post data source
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.postDeleteError.localizedString)
                            }
                        }
                    }
                }))
            case .closePoll:
                return Alert(title: Text(AmityLocalizedStringSet.Social.pollCloseAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.pollCloseAlertDesc.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.Social.pollCloseButton.localizedString), action: {
                    Task { @MainActor in
                        isShown.toggle()
                        
                        action?(.closePoll)
                        
                        if let pollId = post.poll?.id {
                            do {
                                let _ = try await viewModel.closePoll(id: pollId)
                            } catch let error {
                                /// Delay showing toast as deleting post will effect post data source
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.pollCloseToastError.localizedString)
                                }
                            }
                        }
                    }
                }))
            }
        })
    }
    
    
    @ViewBuilder
    private var moderatorView: some View {
        editSheetButton
            .isHidden(!post.isOwner || post.dataTypeInternal == .poll || post.dataTypeInternal == .liveStream || post.dataTypeInternal == .room) // We cannot edit poll post & live stream post
        
        if let poll = post.poll, !poll.isClosed {
            closePollButton
                .isHidden(!post.isOwner || post.dataTypeInternal != .poll)
        }
        
        flagSheetButton
            .isHidden(post.isOwner)
        
        shareableLinkItemView
            .isHidden(!canUserSharePost())
        
        deleteSheetButton
    }
    
    @ViewBuilder
    private var memberView: some View {
        editSheetButton
            .isHidden(!post.isOwner || post.dataTypeInternal == .poll || post.dataTypeInternal == .liveStream || post.dataTypeInternal == .room)
        
        if let poll = post.poll, !poll.isClosed {
            closePollButton
                .isHidden(!post.isOwner || post.dataTypeInternal != .poll)
        }
        
        flagSheetButton
            .isHidden(post.isOwner)
        
        shareableLinkItemView
            .isHidden(!canUserSharePost())
        
        deleteSheetButton
            .isHidden(!(post.isOwner || viewModel.hasDeletePermission))
    }
    
    func canUserSharePost() -> Bool {
        let isShareableLinkConfigured = AmityUIKitManagerInternal.shared.canShareLink(for: .post)
        
        // Shareable link should be configured
        guard isShareableLinkConfigured else { return false }
        
        // In user feed, we do not want to show share option when tapping on 3 dots
        let isTargetUserFeed: Bool = post.postTargetType == .user
        guard !isTargetUserFeed else { return false }
        
        // Post should have target community at this point.
        guard let community = post.targetCommunity else { return false }
        
        // In community feed, we want to show share option when "tapping on 3 dots" only when
        // - User hasn't joined the community
        // - And the community is public
        // If the community is public, an explicit share button will appear in posts anyway
        return !community.isJoined && community.isPublic
    }
    
    private var deleteSheetButton: some View {
        BottomSheetItemView(icon: AmityIcon.trashBinIcon.getImageResource(), text: AmityLocalizedStringSet.Social.deletePostBottomSheetTitle.localizedString, isDestructive: true)
            .onTapGesture {
                activeAlert = .deletePost
                showConfirmationAlert.toggle()
            }
    }
    
    private var flagSheetButton: some View {
        BottomSheetItemView(icon: viewModel.isPostFlaggedByMe ? AmityIcon.unflagIcon.imageResource : AmityIcon.flagIcon.imageResource, text: viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.unreportPostBottomSheetTitle.localizedString : AmityLocalizedStringSet.Social.reportPostBottomSheetTitle.localizedString)
            .onTapGesture {
                if viewModel.isPostFlaggedByMe {
                    Task { @MainActor in
                        do {
                            try await viewModel.unflagPost(id: post.postId)
                            
                            isShown.toggle()
                            viewModel.updatePostFlaggedByMeState(id: post.postId)
                            
                            Toast.showToast(style: .success, message: viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.postUnReportedMessage.localizedString : AmityLocalizedStringSet.Social.postReportedMessage.localizedString)
                        } catch {
                            isShown.toggle()
                            Toast.showToast(style: .warning, message: viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.postFailedUnReportedMessage.localizedString : AmityLocalizedStringSet.Social.postFailedReportedMessage.localizedString)
                        }
                    }
                } else {
                    action?(.reportPost)
                }
            }
    }
    
    private var closePollButton: some View {
        BottomSheetItemView(icon: AmityIcon.createPollMenuIcon.imageResource, text: AmityLocalizedStringSet.Social.pollCloseButton.localizedString)
            .onTapGesture {
                activeAlert = .closePoll
                showConfirmationAlert.toggle()
            }
    }
    
    private var editSheetButton: some View {
        BottomSheetItemView(icon: AmityIcon.editCommentIcon.imageResource, text: AmityLocalizedStringSet.Social.editPostBottomSheetTitle.localizedString)
            .onTapGesture {
                action?(.editPost)
            }
    }
    
    @ViewBuilder
    var shareableLinkItemView: some View {
        let copyLinkConfig = viewConfig.forElement(.copyLink)
        let shareLinkConfig = viewConfig.forElement(.shareLink)
        
        BottomSheetItemView(icon: AmityIcon.copyLinkIcon.imageResource, text: copyLinkConfig.text ?? "")
            .onTapGesture {
                isShown.toggle()
                
                let shareLink = AmityUIKitManagerInternal.shared.generateShareableLink(for: .post, id: post.postId)
                UIPasteboard.general.string = shareLink
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.eventInfoLinkCopied.localizedString)
                }
            }
        
        BottomSheetItemView(icon: AmityIcon.shareToIcon.imageResource, text: shareLinkConfig.text ?? "")
            .onTapGesture {
                isShown.toggle()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    action?(.sharePost)
                }
            }
    }
}

class PostBottomSheetViewModel: ObservableObject {
    private let postManager = PostManager()
    private let pollManager = PollManager()
    
    @Published var isPostFlaggedByMe: Bool = false
    @Published var hasDeletePermission: Bool = false
    
    @MainActor
    func deletePost(id: String) async throws {
        try await postManager.deletePost(withId: id)
    }
    
    @MainActor
    func flagPost(id: String) async throws {
        try await postManager.flagPost(withId: id)
    }
    
    @MainActor
    func unflagPost(id: String) async throws {
        try await postManager.unflagPost(withId: id)
    }
    
    @MainActor
    func closePoll(id: String) async throws -> Bool {
        return try await pollManager.closePoll(pollId: id)
    }
    
    func updatePostFlaggedByMeState(id: String) {
        Task { @MainActor in
            isPostFlaggedByMe = try await postManager.isFlagByMe(withId: id)
        }
    }
    
    func checkDeletePermission(post: AmityPostModel) {
        if post.isOwner {
            hasDeletePermission = true
            return
        }
        
        if let communityId = post.targetCommunity?.communityId {
            Task { @MainActor in
                hasDeletePermission = await CommunityPermissionChecker.hasDeleteCommunityPostPermission(communityId: communityId)
            }
        }
    }
}
