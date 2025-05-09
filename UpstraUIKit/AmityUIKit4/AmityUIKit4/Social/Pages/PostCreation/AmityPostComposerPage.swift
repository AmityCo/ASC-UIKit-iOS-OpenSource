//
//  AmityPostComposerPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/6/24.
//

import AmitySDK
import Combine
import SwiftUI

public enum AmityPostComposerMode {
    case create
    case edit
}

public enum AmityPostComposerOptions {
    case editOptions(mode: AmityPostComposerMode = .edit, post: AmityPostModel)
    case createOptions(
        mode: AmityPostComposerMode = .create, targetId: String?, targetType: AmityPostTargetType,
        community: AmityCommunityModel?)
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
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var areAttachmentsReady: Bool = true
    private let options: AmityPostComposerOptions

    @State private var postErrorMessage = AmityLocalizedStringSet.Social.postCreateError
        .localizedString
    
    private var loadingToastMessage: String {
        viewModel.mode == .create ? "Posting..." : "Updating..."
    }

    public init(options: AmityPostComposerOptions) {
        self.options = options
        switch options {
        case .editOptions(_, let post):
            self._viewModel = StateObject(
                wrappedValue: AmityPostComposerViewModel(
                    targetId: post.targetId, targetType: AmityPostTargetType.community, post: post))

            self._textEditorViewModel = StateObject(
                wrappedValue: AmityTextEditorViewModel(
                    mentionManager: MentionManager(withType: .post(communityId: post.targetId))))
            self._mediaAttatchmentViewModel = StateObject(
                wrappedValue: AmityMediaAttachmentViewModel(medias: post.medias, isPostEditing: true))
            self._viewConfig = StateObject(
                wrappedValue: AmityViewConfigController(pageId: .postComposerPage))

        case .createOptions(_, let targetId, let targetType, let community):
            self._viewModel = StateObject(
                wrappedValue: AmityPostComposerViewModel(
                    targetId: targetId, targetType: targetType, community: community))
            self._textEditorViewModel = StateObject(
                wrappedValue: AmityTextEditorViewModel(
                    mentionManager: MentionManager(withType: .post(communityId: targetId))))
            self._mediaAttatchmentViewModel = StateObject(
                wrappedValue: AmityMediaAttachmentViewModel(medias: [], isPostEditing: false))
            self._viewConfig = StateObject(
                wrappedValue: AmityViewConfigController(pageId: .postComposerPage))
        }

    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                navigationBarView
                    .frame(height: 58)

                ScrollView {
                    AmityMessageTextEditorView(
                        textEditorViewModel,
                        text: $viewModel.postText,
                        mentionData: $viewModel.mentionData,
                        mentionedUsers: $viewModel.mentionedUsers,
                        textViewHeight: getTextEditorHeight(for: viewModel.postText)
                    )
                    .placeholder(viewModel.postText.isEmpty ? "What's going on..." : "")
                    .maxExpandableHeight(99999)
                    .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    PostCreationMediaAttachmentPreviewView(viewModel: mediaAttatchmentViewModel)
                        .contentShape(Rectangle())
                        .padding(.bottom, 60)
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
                AmityMentionUserListView(
                    mentionedUsers: $viewModel.mentionedUsers,
                    selection: { selectedMention in
                        // Ask view model to handle this selection
                        textEditorViewModel.selectMentionUser(user: selectedMention)

                        // Update attributed Input
                        viewModel.postText = textEditorViewModel.textView.text

                        viewModel.mentionData.mentionee = textEditorViewModel.mentionManager
                            .getMentionees()
                        viewModel.mentionData.metadata = textEditorViewModel.mentionManager
                            .getMetadata()

                    },
                    paginate: {
                        textEditorViewModel.loadMoreMentions()
                    }
                )
                .background(Color(viewConfig.theme.backgroundColor))
                .isHidden(viewModel.mentionedUsers.count == 0, remove: true)

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
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }

    @ViewBuilder
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            let closeIcon =
                viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self)
                ?? ""
            Image(AmityIcon.getImageResource(named: closeIcon))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 24)
                .onTapGesture {
                    if isPostDraftEmpty() {
                        host.controller?.navigationController?.dismiss(animated: true)
                    } else {
                        showAlert.toggle()
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Discard this post?"),
                        message: Text("The post will be permanently deleted. It cannot be undone."),
                        primaryButton: .cancel(Text("Keep editing")),
                        secondaryButton: .destructive(
                            Text("Discard"),
                            action: {
                                host.controller?.navigationController?.dismiss(animated: true)
                            }))
                }

            Spacer()

            let displayName = viewModel.displayName
            let editPostTitle =
                viewConfig.getConfig(elementId: .editPostTitle, key: "text", of: String.self)
                ?? "Edit Post"
            Text(viewModel.mode == .create ? displayName : editPostTitle)
                .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                .isHidden(viewConfig.isHidden(elementId: .editPostTitle))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(AccessibilityID.Social.PostComposer.editPostTitle)
            Spacer()

            let postButtonTitle =
                viewConfig.getConfig(elementId: .createNewPostButton, key: "text", of: String.self)
                ?? "Post"
            let hasContent = !viewModel.postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaAttatchmentViewModel.medias.isEmpty
            let canPost = hasContent && !isLoading && mediaAttatchmentViewModel.areAttachmentsReady

            Button(
                postButtonTitle,
                action: {
                    Task {
                        isLoading = true
                        do {
                            let post = try await viewModel.createPost(
                                medias: mediaAttatchmentViewModel.medias, files: [])
                            isLoading = false

                            host.controller?.navigationController?.dismiss(
                                animated: true,
                                completion: {
                                    if post.getFeedType() == .reviewing {
                                        let alertController = UIAlertController(title: "Posts sent for review", message: "Your post has been submitted to the pending list. It will be published once approved by the community moderator", preferredStyle: .alert)

                                        let okAction = UIAlertAction(
                                            title: AmityLocalizedStringSet.General.okay
                                                .localizedString, style: .cancel)
                                        alertController.addAction(okAction)

                                        UIApplication.topViewController()?.present(
                                            alertController, animated: true)
                                    }
                                })

                            /// Send didPostCreated event to mod global feed listing
                            /// This event is observed in PostFeedViewModel
                            NotificationCenter.default.post(name: .didPostCreated, object: post)
                        } catch {
                            postErrorMessage = getErrorMessage(error: error)
                            
                            isLoading = false
                            failedToastAlphaValue = 1.0

                            withAnimation(.easeInOut(duration: 0.5).delay(3.0)) {
                                failedToastAlphaValue = 0.0
                            }
                        }
                    }
                }
            )
            .foregroundColor(canPost ? Color(viewConfig.theme.primaryColor) : Color(viewConfig.theme.primaryColor.blend(.shade2)))
            .disabled(!canPost)
            .isHidden(viewModel.mode == .edit)
            .accessibilityIdentifier(AccessibilityID.Social.PostComposer.createNewPostButton)

            let editPostButtonTitle =
                viewConfig.getConfig(elementId: .editPostButton, key: "text", of: String.self)
                ?? "Save"
            let hasValidContent = !viewModel.postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaAttatchmentViewModel.medias.isEmpty
            let hasChanges = viewModel.hasPostChanges(currentText: viewModel.postText, currentMedias: mediaAttatchmentViewModel.medias)
            let canSave = hasValidContent && hasChanges && !isLoading && mediaAttatchmentViewModel.areAttachmentsReady

            Button(
                editPostButtonTitle,
                action: {
                    Task { @MainActor in
                        isLoading = true

                        do {
                            let updatedPost = try await viewModel.editPost(
                                medias: mediaAttatchmentViewModel.medias, files: [])
                            isLoading = false

                            host.controller?.navigationController?.dismiss(
                                animated: true,
                                completion: {
                                    if updatedPost?.getFeedType() == .reviewing {
                                        let alertController = UIAlertController(
                                            title: "Post updates sent for review", 
                                            message: "Your post update has been submitted to the pending list. It will be published once approved by the community moderator", 
                                            preferredStyle: .alert)

                                        let okAction = UIAlertAction(
                                            title: AmityLocalizedStringSet.General.okay
                                                .localizedString, style: .cancel)
                                        alertController.addAction(okAction)

                                        UIApplication.topViewController()?.present(
                                            alertController, animated: true)
                                    }
                                })

                        } catch {
                            postErrorMessage = getErrorMessage(error: error)
                            
                            isLoading = false
                            failedToastAlphaValue = 1.0

                            withAnimation(.easeInOut(duration: 0.5).delay(3.0)) {
                                failedToastAlphaValue = 0.0
                            }
                        }
                    }
                }
            )
            .disabled(!canSave)
            .isHidden(viewModel.mode == .create)
            .accessibilityIdentifier(AccessibilityID.Social.PostComposer.editPostButton)
        }
        .padding([.leading, .trailing], 16)
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
            viewModel.mode == .create
            ? AmityLocalizedStringSet.Social.postCreateError.localizedString
            : AmityLocalizedStringSet.Social.postEditError.localizedString

        if viewModel.postText.count > maxCharLimit {
            message = "Your post wasn't posted because it exceeds the 50,000 characters limit."
        } else if error.isAmityErrorCode(.banWordFound) {
            message = "Your post wasn't posted because it contains a blocked word."
        } else if error.isAmityErrorCode(.linkNotAllowed) {
            message = "Your post wasn't posted because it contains a link that's not allowed."
        } else {
            message =
                viewModel.mode == .create
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
        if viewModel.mode == .create {
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
}

class AmityPostComposerViewModel: ObservableObject {
    private let communityManager = CommunityManager()
    private let postManager = PostManager()
    private let targetId: String?
    private let community: AmityCommunityModel?
    private let post: AmityPostModel?
    let mode: AmityPostComposerMode
    let targetType: AmityPostTargetType
    private let networkMonitor = NetworkMonitor()

    @Published var displayName: String

    @Published var postText: String = ""
    @Published var mentionData: MentionData = MentionData()
    @Published var mentionedUsers: [AmityMentionUserModel] = []

    private let originalPostText: String
    private let originalMedias: [AmityMedia]

    init(targetId: String?, targetType: AmityPostTargetType, community: AmityCommunityModel?) {
        self.targetId = targetId
        self.targetType = targetType
        self.community = community
        self.mode = .create
        self.post = nil
        self.displayName =
            targetType == .community ? community?.displayName ?? "Unknown" : "My Timeline"
        self.originalPostText = ""
        self.originalMedias = []
    }

    // Edit mode
    init(targetId: String, targetType: AmityPostTargetType, post: AmityPostModel) {
        self.targetId = targetId
        self.targetType = targetType
        self.mode = .edit
        self.post = post
        self.community = nil
        self.displayName = "Edit Post"
        self.postText = post.text
        self.originalPostText = post.text
        self.originalMedias = post.medias
        self.mentionData.metadata = post.metadata
    }

    // Add a function to check if post has changes in edit mode
    func hasPostChanges(currentText: String, currentMedias: [AmityMedia]) -> Bool {
        // Check for text changes (ignoring only whitespace changes)
        let trimmedOriginalText = originalPostText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTextChanges = trimmedOriginalText != trimmedCurrentText

        // Check for media changes (count, content)
        let hasMediaChanges = !areMediasEqual(originalMedias, currentMedias)

        return hasTextChanges || hasMediaChanges
    }

    // Helper function to compare two media arrays
    private func areMediasEqual(_ medias1: [AmityMedia], _ medias2: [AmityMedia]) -> Bool {
        guard medias1.count == medias2.count else { return false }

        // Compare by fileId as that's the unique identifier
        let fileIds1 = medias1.compactMap { media -> String? in
            switch media.state {
            case .uploadedImage(let data), .downloadableImage(let data, _):
                return data.fileId
            case .uploadedVideo(let data), .downloadableVideo(let data, _):
                return data.fileId
            default:
                return nil
            }
        }.sorted()

        let fileIds2 = medias2.compactMap { media -> String? in
            switch media.state {
            case .uploadedImage(let data), .downloadableImage(let data, _):
                return data.fileId
            case .uploadedVideo(let data), .downloadableVideo(let data, _):
                return data.fileId
            default:
                return nil
            }
        }.sorted()

        return fileIds1 == fileIds2
    }

    @discardableResult
    func createPost(medias: [AmityMedia], files: [AmityFile]) async throws -> AmityPost {
        guard networkMonitor.isConnected else {
            throw NSError(domain: "Internet is not connected.", code: 500)
        }

        let targetType: AmityPostTargetType = targetId == nil ? .user : .community
        var postBuilder: AmityPostBuilder

        let imagesData = getImagesData(from: medias)
        let videosData = getVideosData(from: medias)
        let filesData = getFilesData(from: files)

        if !imagesData.isEmpty {
            // Image Post
            Log.add(event: .info, "Creating image post with \(imagesData.count) images")
            Log.add(event: .info, "FileIds: \(imagesData.map{ $0.fileId })")

            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(postText)
            imagePostBuilder.setImages(imagesData)
            postBuilder = imagePostBuilder

            return try await postManager.postRepository.createImagePost(
                imagePostBuilder, targetId: targetId, targetType: targetType,
                metadata: mentionData.metadata, mentionees: mentionData.mentionee)

        } else if !videosData.isEmpty {
            // Video Post
            Log.add(event: .info, "Creating video post with \(videosData.count) images")
            Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")

            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(postText)
            videoPostBuilder.setVideos(videosData)
            postBuilder = videoPostBuilder

            return try await postManager.postRepository.createVideoPost(
                videoPostBuilder, targetId: targetId, targetType: targetType,
                metadata: mentionData.metadata, mentionees: mentionData.mentionee)
        } else if !filesData.isEmpty {
            // File Post
            Log.add(event: .info, "Creating file post with \(filesData.count) files")
            Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")

            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(postText)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder

            return try await postManager.postRepository.createFilePost(
                fileBuilder, targetId: targetId, targetType: targetType,
                metadata: mentionData.metadata, mentionees: mentionData.mentionee)
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(postText)
            postBuilder = textPostBuilder

            return try await postManager.postRepository.createTextPost(
                textPostBuilder, targetId: targetId, targetType: targetType,
                metadata: mentionData.metadata, mentionees: mentionData.mentionee)
        }
    }

    func editPost(medias: [AmityMedia], files: [AmityFile]) async throws -> AmityPost? {
        var postBuilder: AmityPostBuilder
        
        // If all media have been removed, use the appropriate empty builder based on original media type
        if medias.isEmpty && !originalMedias.isEmpty {
            // Directly use the type property of the first original media
            if let firstOriginalMedia = originalMedias.first {
                switch firstOriginalMedia.type {
                case .image:
                    Log.add(event: .info, "Removing all images from image post")
                    let imagePostBuilder = AmityImagePostBuilder()
                    imagePostBuilder.setText(postText)
                    imagePostBuilder.setImages([]) // Empty image array
                    postBuilder = imagePostBuilder
                    
                case .video:
                    Log.add(event: .info, "Removing all videos from video post")
                    let videoPostBuilder = AmityVideoPostBuilder()
                    videoPostBuilder.setText(postText)
                    videoPostBuilder.setVideos([]) // Empty video array
                    postBuilder = videoPostBuilder
                    
                case .none:
                    // For files or unknown types, default to text post
                    Log.add(event: .info, "Using text post builder")
                    let textPostBuilder = AmityTextPostBuilder()
                    textPostBuilder.setText(postText)
                    postBuilder = textPostBuilder
                }
            } else {
                // If originalMedias is somehow empty, default to text post
                Log.add(event: .info, "Using text post builder (no original media)")
                let textPostBuilder = AmityTextPostBuilder()
                textPostBuilder.setText(postText)
                postBuilder = textPostBuilder
            }
        } else {
            let imagesData = getImagesData(from: medias)
            let videosData = getVideosData(from: medias)
            let filesData = getFilesData(from: files)

            if !imagesData.isEmpty {
                // Image Post
                Log.add(event: .info, "Editing post with \(imagesData.count) images")
                Log.add(event: .info, "FileIds: \(imagesData.map{ $0.fileId })")

                let imagePostBuilder = AmityImagePostBuilder()
                imagePostBuilder.setText(postText)
                imagePostBuilder.setImages(imagesData)
                postBuilder = imagePostBuilder
            } else if !videosData.isEmpty {
                // Video Post
                Log.add(event: .info, "Editing post with \(videosData.count) videos")
                Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")

                let videoPostBuilder = AmityVideoPostBuilder()
                videoPostBuilder.setText(postText)
                videoPostBuilder.setVideos(videosData)
                postBuilder = videoPostBuilder
            } else if !filesData.isEmpty {
                // File Post
                Log.add(event: .info, "Editing post with \(filesData.count) files")
                Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")

                let fileBuilder = AmityFilePostBuilder()
                fileBuilder.setText(postText)
                fileBuilder.setFiles(getFilesData(from: files))
                postBuilder = fileBuilder
            } else {
                // Text Post
                Log.add(event: .info, "Editing text post")
                let textPostBuilder = AmityTextPostBuilder()
                textPostBuilder.setText(postText)
                postBuilder = textPostBuilder
            }
        }

        if let postId = post?.postId {
            return try await postManager.editPost(
                withId: postId, builder: postBuilder, metadata: mentionData.metadata,
                mentionees: mentionData.mentionee)
        }
        return nil
    }

    private func getImagesData(from medias: [AmityMedia]) -> [AmityImageData] {
        var imagesData: [AmityImageData] = []
        for media in medias {
            switch media.state {
            case .uploadedImage(let imageData), .downloadableImage(let imageData, _):
                imagesData.append(imageData)
            default:
                continue
            }
        }
        return imagesData
    }

    private func getVideosData(from medias: [AmityMedia]) -> [AmityVideoData] {
        var videosData: [AmityVideoData] = []
        for media in medias {
            switch media.state {
            case .uploadedVideo(let videoData), .downloadableVideo(let videoData, _):
                videosData.append(videoData)
            default:
                continue
            }
        }
        return videosData
    }

    private func getFilesData(from files: [AmityFile]) -> [AmityFileData] {
        var filesData: [AmityFileData] = []
        for file in files {
            switch file.state {
            case .downloadable(let fileData), .uploaded(data: let fileData):
                filesData.append(fileData)
            default:
                continue
            }
        }
        return filesData
    }
}
