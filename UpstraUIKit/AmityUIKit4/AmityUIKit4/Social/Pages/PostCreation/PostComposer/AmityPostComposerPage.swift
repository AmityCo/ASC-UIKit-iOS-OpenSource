//
//  AmityPostComposerPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/6/24.
//

import AmitySDK
import Combine
import SwiftUI
import SafariServices

public struct AmityClipDraft {
    let clipData: AmityClipData
    let displayMode: AmityClipDisplayMode
    let isMuted: Bool
}

public enum AmityPostComposerMode {
    case create
    case edit
    case createClip(url: URL?, draft: AmityClipDraft)
    case editClip
}

public enum AmityPostComposerOptions {
    case editOptions(mode: AmityPostComposerMode = .edit,
                     post: AmityPostModel)
    case createOptions(mode: AmityPostComposerMode = .create,
                       targetId: String?,
                       targetType: AmityPostTargetType,
                       community: AmityCommunityModel?,
                       event: AmityEvent? = nil)
}

public struct AmityPostComposerPage: AmityPageView {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        .postComposerPage
    }
    
    @State private var mediaAttatchmentComponentYOffset: CGFloat = 0.0
    @State private var showSmallComponent: Bool = false
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityPostComposerViewModel
    @StateObject private var textEditorViewModel: AmityTextEditorViewModel
    @StateObject private var mediaAttatchmentViewModel: AmityMediaAttachmentViewModel
    @State private var postCreationToastAlphaValue = 0.0
    @State private var failedToastAlphaValue = 0.0
    @State private var showDismissAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var areAttachmentsReady: Bool = true
    @State private var keyboardHeight: CGFloat = .zero
    private let options: AmityPostComposerOptions
    // Track original media file IDs for comparison when post is updated
    @State private var originalMediaFileIds: [String] = []
    
    @State private var postErrorMessage = AmityLocalizedStringSet.Social.postCreateError
        .localizedString
    
    private var loadingToastMessage: String {
        viewModel.isInCreateMode ? "Posting..." : "Updating..."
    }
    
    var clipURL: URL? {
        switch viewModel.mode {
        case .createClip(let url, _):
            return url
        case .editClip:
            let medias = mediaAttatchmentViewModel.medias
            if let clipURL = medias.first?.clip?.fileURL {
                return URL(string: clipURL)
            }
            return nil
        default:
            return nil
        }
    }
    
    var placeholderText: String {
        switch viewModel.mode {
        case .createClip:
            return "What's going on? (optional)"
        default:
            return "What's going on..."
        }
    }
    
    public init(options: AmityPostComposerOptions) {
        self.options = options
        switch options {
        case .editOptions(let mode, let post):
            self._viewModel = StateObject(
                wrappedValue: AmityPostComposerViewModel(
                    targetId: post.targetId, targetType: AmityPostTargetType.community, post: post, mode: mode))
            
            let textEditorVM = AmityTextEditorViewModel(
                mentionManager: MentionManager(withType: .post(communityId: post.targetId)))
            textEditorVM.productTagManager.productTags = post.textProductTags ?? []
            self._textEditorViewModel = StateObject(wrappedValue: textEditorVM)
            self._mediaAttatchmentViewModel = StateObject(
                wrappedValue: AmityMediaAttachmentViewModel(medias: post.medias, isPostEditing: true))
            self._viewConfig = StateObject(
                wrappedValue: AmityViewConfigController(pageId: .postComposerPage))
            
            // Store the original file IDs for later comparison (including all media types)
            self._originalMediaFileIds = State(initialValue: post.medias.compactMap { media in
                // Handle image files
                if let fileId = media.image?.fileId {
                    return fileId
                }
                // Handle video files
                else if let fileId = media.video?.fileId {
                    return fileId
                }
                return nil
            })
            
        case .createOptions(let mode, let targetId, let targetType, let community, let event):
            self._viewModel = StateObject(
                wrappedValue: AmityPostComposerViewModel(
                    targetId: targetId, targetType: targetType, community: community, mode: mode, event: event))
            self._textEditorViewModel = StateObject(
                wrappedValue: AmityTextEditorViewModel(
                    mentionManager: MentionManager(withType: .post(communityId: targetId))))
            self._mediaAttatchmentViewModel = StateObject(
                wrappedValue: AmityMediaAttachmentViewModel(medias: [], isPostEditing: false))
            self._viewConfig = StateObject(
                wrappedValue: AmityViewConfigController(pageId: .postComposerPage))
        }
    }
    
    @State private var playClipVideo: Bool = true
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                navigationBarView
                
                ScrollView {
                    
                    clipPreview
                    
                    ExpandableTextEditorView(isTextEditorFocused: .constant(false), input: $viewModel.postTitle)
                        .placeholder("Title (Optional)")
                        .font(AmityTextStyle.titleBold(.clear).getFont())
                        .placeholderColor(Color(viewConfig.theme.baseColorShade2))
                        .textColor(Color(viewConfig.theme.baseColor))
                        .lineLimit(10)
                        .maxCharCount(viewModel.postTitleMaxCount)
                        .disableNewlines(true)
                        .padding(.horizontal, 4)
                    
                    AmityMessageTextEditorView(
                        textEditorViewModel,
                        text: $viewModel.postText,
                        mentionData: $viewModel.mentionData,
                        mentionedUsers: $viewModel.mentionedUsers,
                        links: $viewModel.links,
                        textViewHeight: getTextEditorHeight(for: viewModel.postText)
                    )
                    .placeholder(viewModel.postText.isEmpty ? placeholderText : "")
                    .maxExpandableHeight(99999)
                    .enableHashtagHighlighting(true)
                    .enableLinkHighlight(true)
                    .scrollEnabled(false)
                    .maxHashtagCount(30)
                    .enableProductMention(viewModel.isProductCatalogueEnabled)
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .onChange(of: viewModel.postText) { _ in
                        guard textEditorViewModel.textView.isFirstResponder,
                              keyboardHeight > 0 else { return }
                        scrollToCursorIfNeeded(kbHeight: keyboardHeight)
                    }
                    .onReceive(keyboardPublisher) { keyboardEvent in
                        keyboardHeight = keyboardEvent.height
                        if keyboardEvent.isAppeared && textEditorViewModel.textView.isFirstResponder {
                            scrollToCursorIfNeeded(kbHeight: keyboardEvent.height)
                        }
                    }
                    .onChange(of: textEditorViewModel.reachProductTagLimit) { reached in
                        if reached {
                            let alert = UIAlertController(
                                title: AmityLocalizedStringSet.Social.productTagLimitTitle.localizedString,
                                message: AmityLocalizedStringSet.Social.productTagLimitMessage.localizedString,
                                preferredStyle: .alert
                            )
                            alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.okay.localizedString, style: .cancel))
                            host.controller?.present(alert, animated: true)
                            textEditorViewModel.reachProductTagLimit = false
                        }
                    }
                    .onChange(of: textEditorViewModel.reachHashtagLimit) { reached in
                        if reached {
                            let alert = UIAlertController(title: "Hashtag limit reached", message: "You can only add hashtag up to 30 hashtags per post.", preferredStyle: .alert)
                            let action = UIAlertAction(title: "OK", style: .cancel)
                            alert.addAction(action)
                            host.controller?.present(alert, animated: true)
                        }
                    }
                    
                    if let link = viewModel.previewedLink, !viewModel.didRemoveLinkPreview, mediaAttatchmentViewModel.medias.isEmpty {
                        PreviewLinkView(viewModel: self.viewModel.previewLinkViewModel)
                            .overlay(
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            viewModel.previewedLink = nil
                                            viewModel.didRemoveLinkPreview = true
                                        }) {
                                            Image(AmityIcon.closeIcon.imageResource)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                                .padding(4)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 10, y: -10)
                                    }
                                    
                                    Spacer()
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }

                    if !viewModel.isInClipComposerMode {
                        PostCreationMediaAttachmentPreviewView(postComposerViewModel: viewModel, viewModel: mediaAttatchmentViewModel)
                            .contentShape(Rectangle())
                            .padding(.bottom, 60)
                    }
                }
                .onChange(of: mediaAttatchmentViewModel.medias) { medias in
                    if !medias.isEmpty && !viewModel.didRemoveLinkPreview {
                        viewModel.didRemoveLinkPreview = true
                        viewModel.previewedLink = nil
                    }
                    viewModel.updateProductTags(medias: medias)
                }
                .onChange(of: textEditorViewModel.productTags) { productTags in
                    viewModel.textProductTags = productTags
                    viewModel.updateProductTags(medias: mediaAttatchmentViewModel.medias)
                }
                .onChange(of: viewModel.productTags) { productTags in
                    textEditorViewModel.suggestionViewModel.taggedProductIds = Set(productTags.map { $0.productId })
                }
                .onAppear {
                    // Set up product tag limit check closure
                    textEditorViewModel.canAddProductTag = { [weak viewModel] in
                        viewModel?.canAddMoreProductTags ?? false
                    }
                    // Initialize tagged product IDs for suggestion view
                    textEditorViewModel.suggestionViewModel.taggedProductIds = Set(viewModel.productTags.map { $0.productId })
                }

                Spacer()
            }
            
            VStack(spacing: 0) {
                
                ToastView(message: loadingToastMessage, style: .loading)
                    .padding(.bottom, 16)
                    .opacity(isLoading ? 1.0 : 0.0)
                    .isHidden(!isLoading)
                
                ToastView(message: postErrorMessage, style: .warning)
                    .padding(.bottom, 16)
                    .opacity(failedToastAlphaValue)
                    .isHidden(failedToastAlphaValue == 0)
                
                // Mention List View
//                AmityMentionUserListView(
//                    mentionedUsers: $viewModel.mentionedUsers,
//                    selection: { selectedMention in
//                        // Ask view model to handle this selection
//                        textEditorViewModel.selectMentionUser(user: selectedMention)
//                        
//                        // Update attributed Input
//                        viewModel.postText = textEditorViewModel.textView.text
//                        
//                        viewModel.mentionData.mentionee = textEditorViewModel.mentionManager
//                            .getMentionees()
//                        viewModel.mentionData.metadata = textEditorViewModel.mentionManager
//                            .getMetadata()
//                        
//                    },
//                    paginate: {
//                        textEditorViewModel.loadMoreMentions()
//                    }
//                )
//                .background(Color(viewConfig.theme.backgroundColor))
//                .isHidden(viewModel.mentionedUsers.count == 0, remove: true)
                
                // Product Tag Button
                HStack {
                    Spacer()
                    productTagButton
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
                .isHidden(viewModel.isInClipComposerMode)

                // Media Attatchment View
                VStack(spacing: 5) {
                    BottomSheetDragIndicator()
                        .foregroundColor(Color(viewConfig.theme.baseColorShade3))

                    if showSmallComponent {
                        AmityMediaAttachmentComponent(
                            viewModel: mediaAttatchmentViewModel, pageId: id)
                    } else {
                        AmityDetailedMediaAttachmentComponent(
                            viewModel: mediaAttatchmentViewModel, pageId: id)
                    }
                }
                .onReceive(keyboardPublisher) { keyboardEvent in
                    withAnimation(.bouncy(duration: 0.15)) {
                        if (keyboardEvent.isAppeared) {
                            showSmallComponent = true
                        }
                    }
                }
                .background(Color(viewConfig.theme.backgroundColor))
                .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.1), radius: 0.5, y: -2)
                .offset(y: mediaAttatchmentComponentYOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            withAnimation(.bouncy(duration: 0.15)) {
                                /// Detail Component is shown at first.
                                /// Drag down - change offset of detail component
                                /// Drag up - change small to detail component
                                if showSmallComponent {
                                    mediaAttatchmentComponentYOffset =
                                    gesture.translation.height < 0 ? -5 : 0
                                } else {
                                    mediaAttatchmentComponentYOffset =
                                    gesture.translation.height > 0
                                    ? gesture.translation.height : 0
                                }
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.bouncy(duration: 0.15)) {
                                if mediaAttatchmentComponentYOffset > 100
                                    || mediaAttatchmentComponentYOffset < 0
                                {
                                    showSmallComponent.toggle()
                                    mediaAttatchmentComponentYOffset = 0
                                } else {
                                    mediaAttatchmentComponentYOffset = 0
                                }
                                
                                hideKeyboard()
                            }
                        }
                )
                .isHidden(viewModel.isInClipComposerMode)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
    
    @ViewBuilder
    var clipPreview: some View {
        if viewModel.isInClipComposerMode, let clipURL {
            ZStack {
                VideoPlayer(url: clipURL, play: $playClipVideo)
                    .mute(true)
                    .contentMode(.scaleAspectFill)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            playClipVideo = false
                        }
                    }
                    .frame(width: 80, height: 142)
                    .background(Color(viewConfig.defaultLightTheme.secondaryColor))
                    .cornerRadius(4, corners: .allCorners)

                Image(AmityIcon.videoControlIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
        }
    }

    @ViewBuilder
    var productTagButton: some View {
        let productTagCount = viewModel.productTags.count
        if productTagCount > 0 {
            Button {
                let component = AmityProductTagListComponent(pageId: .postComposerPage,
                                                             productTags: viewModel.productTags,
                                                             sourceId: "", // No postId yet during composition
                                                             onClose: nil) { productTag in
                    if let url = URL(string: productTag.object.productUrl) {
                        let browserVC = SFSafariViewController(url: url)
                        browserVC.modalPresentationStyle = .pageSheet
                        UIApplication.topViewController()?.present(browserVC, animated: true)
                    }
                }

                let vc = AmitySwiftUIHostingController(rootView: component)
                host.controller?.present(vc, animated: true)
            } label: {
                ZStack(alignment: .topTrailing) {
                    // Tag icon button
                    Circle()
                        .fill(Color(viewConfig.theme.baseColorShade4))
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 4)
                        .overlay(
                            Image(AmityIcon.tagIcon.imageResource)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(viewConfig.theme.baseColor))
                        )

                    // Badge with count
                    Text("\(productTagCount)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .circularBackground(radius: 20, color: Color(viewConfig.theme.baseColor))
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
    
    @ViewBuilder
    private var navigationBarView: some View {
        let editPageTitle = viewConfig.forElement(.editPostTitle).text ?? "Edit Post"
        AmityNavigationBar(title: viewModel.isInCreateMode ? viewModel.displayName : editPageTitle) {
            if viewModel.isInClipComposerMode {
                AmityNavigationBar.BackButton {
                    dismissComposer()
                }
            } else {
                let closeIcon = viewConfig.forElement(.closeButtonElement).image ?? ""
                Image(AmityIcon.getImageResource(named: closeIcon))
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(width: 24, height: 24)
                    .onTapGesture {
                        dismissComposer()
                    }
            }
        } trailing: {
            let createPostButtonTitle = viewConfig.forElement(.createNewPostButton).text ?? "Post"
            let editPostButtonTitle = viewConfig.forElement(.editPostButton).text ?? "Save"
            
            let hasContent = !viewModel.postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaAttatchmentViewModel.medias.isEmpty || viewModel.isInClipComposerMode
            let canCreatePost = hasContent && !isLoading && mediaAttatchmentViewModel.areAttachmentsReady
            
            let hasChanges = viewModel.hasPostChanges(currentTitle: viewModel.postTitle, currentText: viewModel.postText, currentMedias: mediaAttatchmentViewModel.medias)
            let canEditPost = hasContent && hasChanges && !isLoading && mediaAttatchmentViewModel.areAttachmentsReady
            
            let createButtonColor = canCreatePost ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.primaryColor.blend(.shade2))
            let editButtonColor = canEditPost ? Color(viewConfig.theme.baseColor) : Color(viewConfig.theme.baseColor.blend(.shade2))
                        
            Button(viewModel.isInCreateMode ? createPostButtonTitle : editPostButtonTitle) {
                processPost()
            }
            .lineLimit(1)
            .frame(minWidth: 40)
            .foregroundColor(viewModel.isInCreateMode ? createButtonColor : editButtonColor)
            .disabled(viewModel.isInCreateMode ? !canCreatePost : !canEditPost)
            .accessibilityIdentifier(viewModel.isInCreateMode ? AccessibilityID.Social.PostComposer.createNewPostButton : AccessibilityID.Social.PostComposer.editPostButton)
        }
        .alert(isPresented: $showDismissAlert) {
            Alert(title: Text(AmityLocalizedStringSet.Social.postDiscardAlertTitle.localizedString), message: Text(AmityLocalizedStringSet.Social.postDiscardAlertMessage.localizedString), primaryButton: .cancel(Text(AmityLocalizedStringSet.Social.postDiscardAlertButtonKeepEditing.localizedString)), secondaryButton: .destructive(Text(AmityLocalizedStringSet.General.discard.localizedString), action: {
                
                switch viewModel.mode {
                case .createClip:
                    host.controller?.navigationController?.popViewController(animated: true)
                default:
                    host.controller?.navigationController?.dismiss(animated: true)
                }
            }))
        }
    }
    
    func dismissComposer() {
        switch viewModel.mode {
        case .create, .edit, .editClip:
            if isPostDraftEmpty() {
                host.controller?.navigationController?.dismiss(animated: true)
            } else {
                showDismissAlert = true
            }
        case .createClip:
            if isPostDraftEmpty() {
                host.controller?.navigationController?.popViewController(animated: true)
            } else {
                showDismissAlert = true
            }
        }
    }
    
    func isPostDraftEmpty() -> Bool {
        let isDraftEmpty =
        viewModel.postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && mediaAttatchmentViewModel.medias.isEmpty
        return isDraftEmpty
    }
    
    func getErrorMessage(error: Error) -> String {
        let maxCharLimit = 50_000
        
        var message =
        viewModel.isInCreateMode
        ? AmityLocalizedStringSet.Social.postCreateError.localizedString
        : AmityLocalizedStringSet.Social.postEditError.localizedString
        
        if viewModel.postText.utf16Count > maxCharLimit {
            message = "Your post wasn't posted because it exceeds the 50,000 characters limit."
        } else if error.isAmityErrorCode(.banWordFound) {
            message = "Your post wasn't posted because it contains a blocked word."
        } else if error.isAmityErrorCode(.linkNotAllowed) {
            message = "Your post wasn't posted because it contains a link that's not allowed."
        } else {
            message =
            viewModel.isInCreateMode
            ? AmityLocalizedStringSet.Social.postCreateError.localizedString
            : AmityLocalizedStringSet.Social.postEditError.localizedString
        }
        
        return message
    }
    
    // Function to check media upload status and update local state
    private func checkMediaUploadStatus() {
        // If there are no media attachments, they're considered "ready"
        if mediaAttatchmentViewModel.medias.isEmpty {
            areAttachmentsReady = true
            return
        }
        
        // Check if any media is still uploading or has failed
        for media in mediaAttatchmentViewModel.medias {
            switch media.state {
            case .uploading:
                // Media is still being uploaded
                areAttachmentsReady = false
                return
            case .error:
                // Media upload has failed
                areAttachmentsReady = false
                return
            default:
                // Continue checking other media
                continue
            }
        }
        
        // All media are in ready states
        areAttachmentsReady = true
    }
    
    private func getTextEditorHeight(for text: String) -> CGFloat {
        if viewModel.isInCreateMode {
            return 34
        } else {
            let font = UIFont.systemFont(ofSize: 16)
            let width: CGFloat = UIScreen.main.bounds.width - 32 // account for padding
            let boundingRect = text.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: [.font: font],
                context: nil
            )
            // A small buffer to avoid cutting off descenders
            return max(34, ceil(boundingRect.height) + 16)
        }
    }
    
    private func processPost() {
        if let links = viewModel.links, links.count >= 100 {
            showAlertForLinkLimit()
            return
        }

        // Check if there are product tags and if product catalogue is still enabled
        let hasProductTags = !viewModel.productTags.isEmpty || !textEditorViewModel.productTags.isEmpty
        if hasProductTags {
            Task { @MainActor in
                do {
                    let isEnabled = try await AmityUIKit4Manager.client.getProductCatalogueSetting().enabled
                    if !isEnabled {
                        viewModel.updateProductCatalogueEnabled(false)
                        showProductTagUnavailableAlert()
                        return
                    }
                    executePostCreation()
                } catch {
                    // If we can't check the setting, proceed with post creation
                    executePostCreation()
                }
            }
        } else {
            executePostCreation()
        }
    }

    private func showProductTagUnavailableAlert() {
        let alert = UIAlertController(
            title: AmityLocalizedStringSet.Social.productTagUnavailableTitle.localizedString,
            message: AmityLocalizedStringSet.Social.productTagUnavailableMessage.localizedString,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: AmityLocalizedStringSet.Social.productTagReviewPost.localizedString,
            style: .default
        ){ _ in
            // Clear product tags
            self.clearProductTagsAndPublish(publish: false)
        })

        alert.addAction(UIAlertAction(
            title: AmityLocalizedStringSet.Social.productTagPublish.localizedString,
            style: .default
        ) { _ in
            // Clear product tags and proceed with post creation
            self.clearProductTagsAndPublish(publish: true)
        })

        host.controller?.present(alert, animated: true)
    }

    private func clearProductTagsAndPublish(publish: Bool) {
        // Clear text product tags
        viewModel.textProductTags = []
        textEditorViewModel.productTagManager.reset()

        // Clear media product tags
        for media in mediaAttatchmentViewModel.medias {
            media.produtTags = []
        }
        viewModel.attachmentProductTags = AmityAttachmentProductTags()
        viewModel.updateProductTags(medias: mediaAttatchmentViewModel.medias)

        // Proceed with post creation
        if publish {
            executePostCreation()
        }
    }

    private func executePostCreation() {
        isLoading = true

        Task { @MainActor in

            let isInCreateMode = viewModel.isInCreateMode
            let sentProductTagCount = viewModel.productTags.count
            
            // Prepare product tags for text and attachments if catalogue is enabled
            var textProductTags: [AmityProductTagModel]? = nil
            var attachmentProductTags: AmityAttachmentProductTags? = nil
            if viewModel.isProductCatalogueEnabled {
                textProductTags = viewModel.textProductTags
                attachmentProductTags = viewModel.attachmentProductTags
            }

            do {
                // Create or edit post
                let post: AmityPost?
                if isInCreateMode {
                    post = try await viewModel.createPost(medias: mediaAttatchmentViewModel.medias,
                                                          files: [],
                                                          hashtags: textEditorViewModel.existingHashtags,
                                                          links: viewModel.getEmbeddedLinks(),
                                                          textProductTags: textProductTags,
                                                          attachmentProductTags: attachmentProductTags)
                } else {
                    post = try await viewModel.editPost(medias: mediaAttatchmentViewModel.medias,
                                                        files: [],
                                                        hashtags: textEditorViewModel.existingHashtags,
                                                        links: viewModel.getEmbeddedLinks(),
                                                        textProductTags: textProductTags,
                                                        attachmentProductTags: attachmentProductTags)
                    
                    // Determine which media files were deleted (including all media types)
                    let currentMediaFileIds = mediaAttatchmentViewModel.medias.compactMap { media -> String? in
                        if let fileId = media.image?.fileId {
                            return fileId
                        }
                        else if let fileId = media.video?.fileId {
                            return fileId
                        }
                        return nil
                    }
                    
                    let deletedMediaFileIds = originalMediaFileIds.filter { fileId in
                        !currentMediaFileIds.contains(fileId)
                    }
                    
                    // Notify that post images have been updated after successful edit
                    // Include the post and deleted file IDs as userInfo
                    print("DeletedFileIds \(deletedMediaFileIds)" )
                    NotificationCenter.default.post(
                        name: .didPostImageUpdated,
                        object: post,
                        userInfo: ["deletedFileIds": deletedMediaFileIds]
                    )
                }
                
                // Compare sent product tag count with response to detect deleted products,
                // or check if any product tag in the response has archived status
                let showProductTagWarning: Bool
                if let post, sentProductTagCount > 0 {
                    let responseModel = AmityPostModel(post: post)
                    let hasArchivedProduct = responseModel.allProductTags.contains { $0.object.status == .archived }
                    let hasDeletedProductIncluded = responseModel.allProductTags.count < sentProductTagCount
                    showProductTagWarning = hasDeletedProductIncluded || hasArchivedProduct
                } else {
                    showProductTagWarning = false
                }

                isLoading = false

                host.controller?.navigationController?.dismiss(animated: true, completion: {
                    if showProductTagWarning {
                        Toast.showToast(style: .warning, message: "Some products that you've tagged are no longer available.")
                    }
                    if post?.getFeedType() == .reviewing {
                        let title = isInCreateMode ? "Posts sent for review" : "Post updates sent for review"
                        let message = isInCreateMode ? "Your post has been submitted to the pending list. It will be published once approved by the community moderator" : "Your post update has been submitted to the pending list. It will be published once approved by the community moderator"
                        
                        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        
                        let okAction = UIAlertAction(title: AmityLocalizedStringSet.General.okay.localizedString, style: .cancel)
                        alertController.addAction(okAction)
                        
                        UIApplication.topViewController()?.present(alertController, animated: true)
                    }
                })
                
                /// Send didPostCreated event to mod global feed listing
                /// This event is observed in PostFeedViewModel
                if isInCreateMode {
                    NotificationCenter.default.post(name: .didPostCreated, object: post)
                } else {
                    NotificationCenter.default.post(name: .didPostEdited, object: post)
                }
            } catch {
                processError(error: error)
            }
        }
    }
    
    private func processError(error: Error) {
        Log.warn("Error while creating post: \(error)")
        postErrorMessage = getErrorMessage(error: error)
        
        isLoading = false
        failedToastAlphaValue = 1.0
        
        withAnimation(.easeInOut(duration: 0.5).delay(3.0)) {
            failedToastAlphaValue = 0.0
        }
    }
    
    private func showAlertForLinkLimit() {
        let alert = UIAlertController(title: "Link limit reached", message: "You can only add up to 100 links per post.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(action)
        
        UIApplication.topViewController()?.present(alert, animated: true)
    }
    
    private func scrollToCursorIfNeeded(kbHeight: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let textView = textEditorViewModel.textView
            guard let selectedRange = textView.selectedTextRange else { return }
            guard let scrollView = findParentScrollView(of: textView) else { return }
            
            // Cursor position on screen
            let caretRect = textView.caretRect(for: selectedRange.end)
            let caretInWindow = textView.convert(caretRect, to: nil)
            
            // Top of keyboard + overlay area on screen
            let screenHeight = UIScreen.main.bounds.height
            let overlayHeight: CGFloat = 100
            let keyboardTop = screenHeight - kbHeight - overlayHeight
            
            // Only scroll if cursor is behind the keyboard
            guard caretInWindow.maxY > keyboardTop else { return }
            
            // Scroll down by exactly the overlap amount
            let overlap = caretInWindow.maxY - keyboardTop
            var offset = scrollView.contentOffset
            offset.y += overlap
            scrollView.setContentOffset(offset, animated: true)
        }
    }
    
    private func findParentScrollView(of view: UIView) -> UIScrollView? {
        var current = view.superview
        
        while let sv = current {
            if let scrollView = sv as? UIScrollView {
                return scrollView
            }
            current = sv.superview
        }
        return nil
    }
}
