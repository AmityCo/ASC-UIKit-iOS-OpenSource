//
//  AmityPendingPostContentComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/29/24.
//

import SwiftUI
import LinkPresentation
import AmitySDK

public struct AmityPendingPostContentComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityPendingPostContentComponentViewModel
    @State private var showBottomSheet: Bool = false
    
    public var pageId: PageId?
    private let post: AmityPostModel
    
    public var id: ComponentId {
        .pendingPostContentComponent
    }
    
    public init(pageId: PageId? = nil, post: AmityPost) {
        self.pageId = pageId
        self.post = AmityPostModel(post: post)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .pendingPostContentComponent))
        self._viewModel = StateObject(wrappedValue: AmityPendingPostContentComponentViewModel(post))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            postHeaderView(post)
            
            VStack(spacing: 12) {
                postContentView(post)
                
                if viewModel.hasModeratorRole() {
                    VStack(spacing: 16) {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(height: 1)
                        
                        postReviewActionView(post)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
        .background(Color(viewConfig.theme.backgroundColor))
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    private func postHeaderView(_ post: AmityPostModel) -> some View {
        HStack(spacing: 8) {
            AmityUserProfileImageView(displayName: post.postedUser?.displayName ?? "", avatarURL: URL(string: post.postedUser?.avatarURL ?? ""))
                .frame(size: CGSize(width: 32.0, height: 32.0))
                .clipShape(Circle())
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .onTapGesture {
                    goToUserProfilePage(post.postedUserId)
                }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(post.displayName)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        .lineLimit(1)
                        .onTapGesture {
                            goToUserProfilePage(post.postedUserId)
                        }
                }
                
                Text("\(post.timestamp)\(post.isEdited ? " (edited)" : "")")
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .isHidden(viewConfig.isHidden(elementId: .timestamp))
                
            }
            
            Spacer()
            
            if post.isOwner {
                Button(action: {
                    showBottomSheet.toggle()
                }, label: {
                    Image(AmityIcon.threeDotIcon.getImageResource())
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .frame(width: 24, height: 24)
                })
                .buttonStyle(BorderlessButtonStyle())
                .bottomSheet(isShowing: $showBottomSheet, height: .contentSize) {
                    getItemView(AmityIcon.trashBinIcon.getImageResource(), text: "Delete post", isDestructive: true)
                        .padding(.bottom, 32)
                        .onTapGesture {
                            Task { @MainActor in
                                do {
                                    showBottomSheet.toggle()
                                    try await viewModel.deletePost()
                                    Toast.showToast(style: .success, message: "Post deleted.")
                                } catch {
                                    Toast.showToast(style: .warning, message: "Failed to delete post.")
                                }
                            }
                        }
                }
            }
        }
    }
    
    
    @ViewBuilder
    private func postContentView(_ post: AmityPostModel) -> some View {
        VStack(spacing: 16) {
            switch post.dataTypeInternal {
            case .text:
                postContentTextView()
                    
                PreviewLinkView(post: post)
            case .image, .video:
                postContentTextView()
                
                PostContentMediaView(post: post)
                .frame(height: 328)
                .clipShape(RoundedCorner(radius: 8))
                
            case .file:
                EmptyView()
           
            case .poll:
                postContentTextView()
                
                PostContentPollView(style: .feed, post: post, isInPendingFeed: true) { actionType in
                    // Empty Implementation
                }
                
            case .liveStream:
                EmptyView()
                
            case .unknown:
                EmptyView()
            }
        }
    }
    
    
    @ViewBuilder
    private func postContentTextView() -> some View {
        if !post.text.isEmpty {
            ExpandableText(post.text, metadata: post.metadata, mentionees: post.mentionees, onTapMentionee: { userId in
                goToUserProfilePage(userId)
            })
            .lineLimit(8)
            .moreButtonText("...See more")
            .font(AmityTextStyle.body(.clear).getFont())
            .foregroundColor(Color(viewConfig.theme.baseColor))
            .attributedColor(viewConfig.theme.primaryColor)
            .moreButtonColor(Color(viewConfig.theme.primaryColor))
            .expandAnimation(.easeOut(duration: 0.25))
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    
    @ViewBuilder
    private func postReviewActionView(_ post: AmityPostModel) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(viewConfig.theme.primaryColor))
                .overlay (
                    Text(viewConfig.getText(elementId: .postAcceptButton) ?? "Accept")
                        .applyTextStyle(.bodyBold(.white))
                )
                .cornerRadius(8)
                .onTapGesture {
                    Task { @MainActor in
                        try await viewModel.approvePost()
                        Toast.showToast(style: .success, message: "Post accepted.")
                    }
                }
                .isHidden(viewConfig.isHidden(elementId: .postAcceptButton))
                .accessibilityIdentifier(AccessibilityID.Social.PendingPost.postAcceptButton)
                
            
            Rectangle()
                .fill(.clear)
                .overlay (
                    Text(viewConfig.getText(elementId: .postDeclineButton) ?? "Decline")
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 1)
                )
                .onTapGesture {
                    Task { @MainActor in
                        do {
                            try await viewModel.declinePost()
                            Toast.showToast(style: .success, message: "Post declined.")
                        } catch {
                            Toast.showToast(style: .warning, message: "Failed to review post. Please try again.")
                        }
                    }
                }
                .isHidden(viewConfig.isHidden(elementId: .postDeclineButton))
                .accessibilityIdentifier(AccessibilityID.Social.PendingPost.postDeclineButton)
        }
        .frame(height: 40)
    }
    
    
    private func getItemView(_ icon: ImageResource, text: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 24)
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Text(text)
                .applyTextStyle(.bodyBold(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor)))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
    
    private func goToUserProfilePage(_ userId: String) {
        let context = AmityPendingPostContentComponentBehavior.Context(component: self, userId: userId)
        AmityUIKitManagerInternal.shared.behavior.pendingPostContentComponentBehavior?.goToUserProfilePage(context: context)
    }
}

class AmityPendingPostContentComponentViewModel: ObservableObject {
    @Published var previewLinkData: (url: URL?, metadata: LPLinkMetadata?, image: UIImage?, loaded: Bool) = (nil, nil, nil, false)
    private let postManager = PostManager()
    private let post: AmityPostModel
    
    init(_ post: AmityPost) {
        self.post = AmityPostModel(post: post)
    }
    
    @MainActor
    func getPreviewlinkData() async {
        let urls = AmityPreviewLinkWizard.shared.detectLinks(input: post.text)
        
        guard urls.count > 0 else {
            previewLinkData.url = nil
            return
        }
        
        previewLinkData.loaded = false
        previewLinkData.url = urls[0]
        previewLinkData.metadata = await AmityPreviewLinkWizard.shared.getMetadata(url: urls[0])
        previewLinkData.loaded = true
        
        previewLinkData.metadata?.imageProvider?.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] image, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                if let image = image as? UIImage {
                    self.previewLinkData.image = image
                }
            }
        })
    }
    
    @discardableResult
    func approvePost() async throws -> Bool {
        try await postManager.approvePost(postId: post.postId)
    }
    
    @discardableResult
    func declinePost() async throws -> Bool {
        try await postManager.declinePost(postId: post.postId)
    }
    
    @discardableResult
    func deletePost() async throws -> Bool {
        try await postManager.deletePost(withId: post.postId)
    }
    
    func hasModeratorRole() -> Bool {
        if let communityMember = post.targetCommunity?.membership.getMember(withId: AmityUIKitManagerInternal.shared.currentUserId) {
            return communityMember.hasModeratorRole
        }
        return false
    }
}
