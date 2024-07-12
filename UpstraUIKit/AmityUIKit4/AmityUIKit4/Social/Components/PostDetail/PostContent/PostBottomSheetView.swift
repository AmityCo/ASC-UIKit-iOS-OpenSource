//
//  PostBottomSheetView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/28/24.
//

import SwiftUI

struct PostBottomSheetView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let post: AmityPostModel
    private let postDeleteCompletion: (() -> Void)?
    private let editPostActionCompletion: (() -> Void)?
    @Binding private var isShown: Bool
    @State private var isDeleteAlertShown: Bool = false
    @StateObject private var viewModel: PostBottomSheetViewModel = PostBottomSheetViewModel()
    
    init(isShown: Binding<Bool>, post: AmityPostModel, postDeleteCompletion: (() -> Void)? = nil, editPostActionCompletion: (() -> Void)?) {
        self._isShown = isShown
        self.post = post
        self.postDeleteCompletion = postDeleteCompletion
        self.editPostActionCompletion = editPostActionCompletion
    }
    
    var body: some View {
        ZStack {
            if post.isModerator {
                moderatorView
            } else {
                memberView
            }
        }
        .onAppear {
            viewModel.updatePostFlaggedByMeState(id: post.postId)
        }
        .alert(isPresented: $isDeleteAlertShown, content: {
            Alert(title: Text(AmityLocalizedStringSet.Social.deletePostTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.deletePostMessage.localizedString), primaryButton: .cancel(), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.delete.localizedString), action: {
                Task { @MainActor in
                    isShown.toggle()
                    postDeleteCompletion?()
                    try await viewModel.deletePost(id: post.postId)
                    
                    /// Send didPostDeleted event to remove created post added in global feed data source
                    /// that is not from live collection
                    /// This event is observed in PostFeedViewModel
                    NotificationCenter.default.post(name: .didPostDeleted, object: nil, userInfo: ["postId" : post.postId])
                    
                    /// Delay showing toast as deleting post will effect post data source
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        Toast.showToast(style: .success, message: AmityLocalizedStringSet.Social.postDeletedToastMessage.localizedString)
                    }
                }
            }))
        })
    }
    
    
    private var moderatorView: some View {
        VStack {
            editSheetButton.isHidden(!post.isOwner)
            flagSheetButton.isHidden(post.isOwner)
            deleteSheetButton
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    

    private var memberView: some View {
        VStack {
            editSheetButton.isHidden(!post.isOwner)
            flagSheetButton.isHidden(post.isOwner)
            deleteSheetButton.isHidden(!post.isOwner)
            Spacer()
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
    }
    
    
    private var deleteSheetButton: some View {
        HStack(spacing: 12) {
            Image(AmityIcon.trashBinIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 24)
                .foregroundColor(Color(viewConfig.theme.alertColor))
            
            Button {
                isDeleteAlertShown.toggle()
            } label: {
                Text(AmityLocalizedStringSet.Social.deletePostBottomSheetTitle.localizedString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.alertColor))
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    
    private var flagSheetButton: some View {
        HStack(spacing: 12) {
            Image(AmityIcon.flagIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 24)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Button {
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
                        Toast.showToast(style: .warning, message: error.localizedDescription)
                    }
                }
            } label: {
                Text(viewModel.isPostFlaggedByMe ? AmityLocalizedStringSet.Social.unreportPostBottomSheetTitle.localizedString : AmityLocalizedStringSet.Social.reportPostBottomSheetTitle.localizedString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
    
    private var editSheetButton: some View {
        HStack(spacing: 12) {
            Image(AmityIcon.editCommentIcon.getImageResource())
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 20, height: 24)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Button {
                // action here
                editPostActionCompletion?()
            } label: {
                Text(AmityLocalizedStringSet.Social.editPostBottomSheetTitle.localizedString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.AmityCommentTrayComponent.BottomSheet.editCommentButton)
            
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }
    
}


class PostBottomSheetViewModel: ObservableObject {
    private let postManager = PostManager()
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
    
    func updatePostFlaggedByMeState(id: String) {
        Task { @MainActor in
            isPostFlaggedByMe = try await postManager.isFlagByMe(withId: id)
        }
    }
}
