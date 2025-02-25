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
    }
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let post: AmityPostModel
    private let action: ((PostAction) -> Void)?
    
    @Binding private var isShown: Bool
    @State private var isAlertShown: Bool = false
    @State private var activeAlert: PostAction = .editPost
        
    @StateObject private var viewModel: PostBottomSheetViewModel = PostBottomSheetViewModel()
    
    init(isShown: Binding<Bool>, post: AmityPostModel, action: ((PostAction) -> Void)?) {
        self._isShown = isShown
        self.post = post
        self.action = action
    }
    
    var body: some View {
        ZStack {
            if post.hasModeratorPermission {
                moderatorView
            } else {
                memberView
            }
        }
        .onAppear {
            viewModel.updatePostFlaggedByMeState(id: post.postId)
        }
        .alert(isPresented: $isAlertShown, content: {
            
            switch activeAlert {
            case .editPost, .deletePost:
                Alert(title: Text(AmityLocalizedStringSet.Social.deletePostTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.deletePostMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                    Task { @MainActor in
                        isShown.toggle()
                        
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
                        } catch _ {                            
                            /// Delay showing toast as deleting post will effect post data source
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.postDeleteError.localizedString)
                            }
                        }
                    }
                }))
            case .closePoll:
                Alert(title: Text(AmityLocalizedStringSet.Social.pollCloseAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.pollCloseAlertDesc.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.Social.pollCloseButton.localizedString), action: {
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
    
    
    private var moderatorView: some View {
        VStack {
            editSheetButton
                .isHidden(!post.isOwner || post.dataTypeInternal == .poll) // We cannot edit poll post
            
            if let poll = post.poll, !poll.isClosed {
                closePollButton
                    .isHidden(!post.isOwner || post.dataTypeInternal != .poll)
            }
            
            flagSheetButton
                .isHidden(post.isOwner)
            
            deleteSheetButton
            
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    private var memberView: some View {
        VStack {
            editSheetButton
                .isHidden(!post.isOwner || post.dataTypeInternal == .poll)
            
            if let poll = post.poll, !poll.isClosed {
                closePollButton
                    .isHidden(!post.isOwner || post.dataTypeInternal != .poll)
            }
            
            flagSheetButton
                .isHidden(post.isOwner)
            
            deleteSheetButton
                .isHidden(!post.isOwner)
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    
    private var deleteSheetButton: some View {
        Button(action: {
            activeAlert = .deletePost
            isAlertShown.toggle()
        }, label: {
            HStack(spacing: 12) {
                Image(AmityIcon.trashBinIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.alertColor))
                
                Text(AmityLocalizedStringSet.Social.deletePostBottomSheetTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.alertColor)))
                
                Spacer()
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    private var flagSheetButton: some View {
        Button(action: {
            Task { @MainActor in
                do {
                    if viewModel.isPostFlaggedByMe {
                        try await viewModel.unflagPost(id: post.postId)
                    } else {
                        try await viewModel.flagPost(id: post.postId)
                    }
                    
                    isShown.toggle()
                    viewModel.updatePostFlaggedByMeState(id: post.postId)
                    
                    Toast.showToast(style: .success, message: viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.postUnReportedMessage.localizedString : AmityLocalizedStringSet.Social.postReportedMessage.localizedString)
                } catch {
                    isShown.toggle()
                    Toast.showToast(style: .warning, message: viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.postFailedUnReportedMessage.localizedString : AmityLocalizedStringSet.Social.postFailedReportedMessage.localizedString)
                }
            }
        }, label: {
            HStack(spacing: 12) {
                Image(viewModel.isPostFlaggedByMe ? AmityIcon.unflagIcon.getImageResource() : AmityIcon.flagIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.unreportPostBottomSheetTitle.localizedString : AmityLocalizedStringSet.Social.reportPostBottomSheetTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                Spacer()
            }
            .contentShape(Rectangle()) // Make whole row tappable
        })
        .buttonStyle(.plain)
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    private var closePollButton: some View {
        Button(action: {
            activeAlert = .closePoll
            isAlertShown.toggle()
        }, label: {
            HStack(spacing: 12) {
                Image(AmityIcon.createPollMenuIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(AmityLocalizedStringSet.Social.pollCloseButton.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                Spacer()
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier(AmityLocalizedStringSet.Social.pollCloseButton.localizedString)
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    private var editSheetButton: some View {
        Button(action: {
            action?(.editPost)
        }, label: {
            HStack(spacing: 12) {
                Image(AmityIcon.editCommentIcon.getImageResource())
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 24)
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                
                Text(AmityLocalizedStringSet.Social.editPostBottomSheetTitle.localizedString)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                Spacer()
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.editCommentButton)
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
}

class PostBottomSheetViewModel: ObservableObject {
    private let postManager = PostManager()
    private let pollManager = PollManager()
    
    @Published var isPostFlaggedByMe: Bool = false
    
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
}
