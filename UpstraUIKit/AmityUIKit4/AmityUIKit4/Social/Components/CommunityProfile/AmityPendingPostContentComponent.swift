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
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityPendingPostContentComponenttViewModel
    @State private var showBottomSheet: Bool = false
    
    public var pageId: PageId?
    private let post: AmityPostModel
    
    public var id: ComponentId {
        .commentTrayComponent
    }
    
    public init(pageId: PageId? = nil, post: AmityPost) {
        self.pageId = pageId
        self.post = AmityPostModel(post: post)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .commentTrayComponent))
        self._viewModel = StateObject(wrappedValue: AmityPendingPostContentComponenttViewModel(post))
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
            AsyncImage(placeholder: AmityIcon.Chat.chatAvatarPlaceholder.imageResource, url: URL(string: post.postedUser?.avatarURL ?? ""))
                .frame(size: CGSize(width: 32.0, height: 32.0))
                .clipShape(Circle())
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(post.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(Color(viewConfig.theme.baseColor))
//                        .onTapGesture {
//                            let context = AmityPostContentComponentBehavior.Context(component: self)
//                            AmityUIKit4Manager.behaviour.postContentComponentBehavior?.goToUserProfilePage(context: context)
//                        }
                }
                
                
                Text("\(post.timestamp)\(post.isEdited ? " (edited)" : "")")
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
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
                    .onAppear {
                        Task { @MainActor in
                            await viewModel.getPreviewlinkData()
                        }
                    }
                
                postPreviewLinkView()
                
            case .image, .video:
                postContentTextView()
                
                PostContentMediaView(post: post)
                .frame(height: 328)
                .clipShape(RoundedCorner(radius: 8))
                
            case .file:
                EmptyView()
           
            case .poll:
                EmptyView()
                
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
            ExpandableText(post.text, metadata: post.metadata, mentionees: post.mentionees)
                .lineLimit(8)
                .moreButtonText("...See more")
                .font(.system(size: 15))
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
                    Text("Accept")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                )
                .cornerRadius(8)
                .onTapGesture {
                    Task { @MainActor in
                        try await viewModel.approvePost()
                        Toast.showToast(style: .success, message: "Post accepted.")
                    }
                }
                
            
            Rectangle()
                .fill(.clear)
                .overlay (
                    Text("Decline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(viewConfig.theme.baseColor))
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
        }
        .frame(height: 40)
    }
    
    
    @ViewBuilder
    private func postPreviewLinkView() -> some View {
        if let url = viewModel.previewLinkData.url {
            VStack(alignment: .leading, spacing: 0) {
                let fallbackImage = viewModel.previewLinkData.metadata == nil ? AmityIcon.previewLinkErrorIcon : AmityIcon.previewLinkDefaultIcon
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 240)
                    .overlay(
                        previewLinkImageView(viewModel.previewLinkData.image, fallback: fallbackImage.getImage() ?? UIImage())
                            .isHidden(!viewModel.previewLinkData.loaded)
                    )
                    .clipped()
                    .shimmering(active: !viewModel.previewLinkData.loaded)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !viewModel.previewLinkData.loaded {
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 180, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                        
                        Rectangle()
                            .fill(Color(viewConfig.theme.baseColorShade4))
                            .frame(width: 160, height: 10)
                            .clipShape(RoundedCorner())
                            .shimmering()
                    } else {
                        let urlText = viewModel.previewLinkData.metadata?.url?.host ?? "Preview not available"
                        let titleText = viewModel.previewLinkData.metadata?.title ?? "Please make sure the URL is correct and try again."
                        let urlFont = viewModel.previewLinkData.metadata?.url?.host == nil ? Font.system(size: 15.0, weight: .semibold) : Font.system(size: 14.0)
                        let titleFont = viewModel.previewLinkData.metadata?.url?.host == nil ? Font.system(size: 15.0) : Font.system(size: 16.0, weight: .semibold)
                        let urlTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColorShade1)
                        let titleTextColor = viewModel.previewLinkData.metadata?.url?.host == nil ? Color(viewConfig.theme.baseColorShade1) : Color(viewConfig.theme.baseColor)
                        
                        Text(urlText)
                            .font(urlFont)
                            .lineLimit(1)
                            .foregroundColor(urlTextColor)
                        
                        Text(titleText)
                            .font(titleFont)
                            .lineLimit(2)
                            .foregroundColor(titleTextColor)
                    }
                }
                .padding([.leading, .trailing], 12)
                .padding([.bottom, .top], 14)
            }
            .cornerRadius(8.0)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.open(url)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(viewConfig.theme.baseColorShade3), lineWidth: 0.4)
            )
        }
    }
    
    
    @ViewBuilder
    private func previewLinkImageView(_ image: UIImage?, fallback: UIImage) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(uiImage: fallback)
                .frame(width: 50, height: 50)
                .scaledToFit()
        }
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isDestructive ? Color(viewConfig.theme.alertColor): Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }
}

class AmityPendingPostContentComponenttViewModel: ObservableObject {
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
