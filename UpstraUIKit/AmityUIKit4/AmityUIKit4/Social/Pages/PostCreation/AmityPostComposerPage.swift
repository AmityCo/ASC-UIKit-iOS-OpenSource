//
//  AmityPostComposerPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/6/24.
//

import SwiftUI
import AmitySDK
import Combine

public enum AmityPostComposerMode {
    case create
    case edit
}

public enum AmityPostComposerOptions {
    case editOptions(mode: AmityPostComposerMode = .edit, post: AmityPostModel)
    case createOptions(mode: AmityPostComposerMode = .create, targetId: String?, targetType: AmityPostTargetType, community: AmityCommunityModel?)
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
    private let options: AmityPostComposerOptions
    
    public init(options: AmityPostComposerOptions) {
        self.options = options
        switch options {
        case .editOptions(_, let post):
            self._viewModel = StateObject(wrappedValue: AmityPostComposerViewModel(targetId: post.targetId, targetType: AmityPostTargetType.community, post: post))

            self._textEditorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: post.targetId))))
            self._mediaAttatchmentViewModel = StateObject(wrappedValue: AmityMediaAttachmentViewModel(medias: post.medias))
            self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postComposerPage))
                        
        case .createOptions(_, let targetId, let targetType, let community):
            self._viewModel = StateObject(wrappedValue: AmityPostComposerViewModel(targetId: targetId, targetType: targetType, community: community))
            self._textEditorViewModel = StateObject(wrappedValue: AmityTextEditorViewModel(mentionManager: MentionManager(withType: .post(communityId: targetId))))
            self._mediaAttatchmentViewModel = StateObject(wrappedValue: AmityMediaAttachmentViewModel(medias: []))
            self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .postComposerPage))
        }

    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                navigationBarView
                    .frame(height: 58)
                
                ScrollView {
                    AmityMessageTextEditorView(textEditorViewModel, text: $viewModel.postText, mentionData: $viewModel.mentionData, mentionedUsers: $viewModel.mentionedUsers, textViewHeight: 34)
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
                
                ToastView(message: "Posting...", style: .loading)
                    .padding(.bottom, 16)
                    .opacity(postCreationToastAlphaValue)
                    .isHidden(postCreationToastAlphaValue == 0)
                
                ToastView(message: "Failed to \(viewModel.mode == .create ? "create" : "edit") post", style: .warning)
                    .padding(.bottom, 16)
                    .opacity(failedToastAlphaValue)
                    .isHidden(failedToastAlphaValue == 0)
                
                // Mention List View
                AmityMentionUserListView(mentionedUsers: $viewModel.mentionedUsers, selection: { selectedMention in
                    // Ask view model to handle this selection
                    textEditorViewModel.selectMentionUser(user: selectedMention)
                    
                    // Update attributed Input
                    viewModel.postText = textEditorViewModel.textView.text
                    
                    viewModel.mentionData.mentionee = textEditorViewModel.mentionManager.getMentionees()
                    viewModel.mentionData.metadata = textEditorViewModel.mentionManager.getMetadata()
                    
                }, paginate: {
                    textEditorViewModel.loadMoreMentions()
                })
                .background(Color(viewConfig.theme.backgroundColor))
                .isHidden(viewModel.mentionedUsers.count == 0, remove: true)
                
                // Media Attatchment View
                if case .createOptions(_, _, _, _) = options {
                    VStack(spacing: 5) {
                        BottomSheetDragIndicator()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                        
                        if showSmallComponent {
                            AmityMediaAttachmentComponent(viewModel: mediaAttatchmentViewModel, pageId: id)
                        } else {
                            AmityDetailedMediaAttachmentComponent(viewModel: mediaAttatchmentViewModel, pageId: id)
                        }
                    }
                    .onReceive(keyboardPublisher) { keyboardEvent in
                        withAnimation(.bouncy(duration: 0.15)) {
                            if keyboardEvent.isAppeared {
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
                                        mediaAttatchmentComponentYOffset = gesture.translation.height < 0 ? -5 : 0
                                    } else {
                                        mediaAttatchmentComponentYOffset = gesture.translation.height > 0 ? gesture.translation.height : 0
                                    }
                                }
                            }
                            .onEnded { gesture in
                                withAnimation(.bouncy(duration: 0.15)) {
                                    if mediaAttatchmentComponentYOffset > 100 || mediaAttatchmentComponentYOffset < 0 {
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
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)

    }
    
    
    @ViewBuilder
    private var navigationBarView: some View {
        HStack(spacing: 0) {
            let closeIcon = viewConfig.getConfig(elementId: .closeButtonElement, key: "image", of: String.self) ?? ""
            Image(AmityIcon.getImageResource(named: closeIcon))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .frame(width: 24, height: 24)
                .onTapGesture {
                    showAlert.toggle()
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Discard this post?"), message: Text("The post will be permanently deleted. It cannot be undone."), primaryButton: .cancel(Text("Keep editing")), secondaryButton: .destructive(Text("Discard"), action: {
                        host.controller?.navigationController?.dismiss(animated: true)
                    }))
                }
            
            Spacer()
            
           
            let displayName = viewModel.displayName
            let editPostTitle = viewConfig.getConfig(elementId: .editPostTitle, key: "text", of: String.self) ?? "Edit Post"
            Text(viewModel.mode == .create ? displayName : editPostTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
                .isHidden(viewConfig.isHidden(elementId: .communityDisplayName))
            Spacer()
            
            let postButtonTitle = viewConfig.getConfig(elementId: .createNewPostButton, key: "text", of: String.self) ?? "Post"
            Button(postButtonTitle, action: {
                Task {
                    postCreationToastAlphaValue = 1.0
                    do {
                        let post = try await viewModel.createPost(medias: mediaAttatchmentViewModel.medias, files: [])
                        postCreationToastAlphaValue = 0.0
                        
                        host.controller?.navigationController?.dismiss(animated: true, completion: {
                            if post.getFeedType() == .reviewing {
                                let alertController = UIAlertController(title: "Your post has been submitted to the pending list. It will be reviewed by community moderator.", message: "", preferredStyle: .alert)
                                
                                let okAction = UIAlertAction(title: AmityLocalizedStringSet.General.okay.localizedString, style: .cancel)
                                alertController.addAction(okAction)
                                
                                UIApplication.topViewController()?.present(alertController, animated: true)
                            }
                        })
                        
                        /// Send didPostCreated event to mod global feed listing
                        /// This event is observed in PostFeedViewModel
                        NotificationCenter.default.post(name: .didPostCreated, object: post)
                    } catch {
                        postCreationToastAlphaValue = 0.0
                        failedToastAlphaValue = 1.0
                      
                        withAnimation(.easeInOut(duration: 0.5).delay(3.0)) {
                            failedToastAlphaValue = 0.0
                        }
                    }
                }
            })
            .disabled(viewModel.postText.isEmpty && mediaAttatchmentViewModel.medias.isEmpty)
            .isHidden(viewModel.mode == .edit)
            
            let editPostButtonTitle = viewConfig.getConfig(elementId: .editPostButton, key: "text", of: String.self) ?? "Save"
            Button(editPostButtonTitle, action: {
                Task {
                    postCreationToastAlphaValue = 1.0

                    do {
                        let post = try await viewModel.editPost(medias: mediaAttatchmentViewModel.medias, files: [])
                        postCreationToastAlphaValue = 0.0
                        
                        host.controller?.navigationController?.dismiss(animated: true)

                    } catch {
                        postCreationToastAlphaValue = 0.0
                        failedToastAlphaValue = 1.0
                      
                        withAnimation(.easeInOut(duration: 0.5).delay(3.0)) {
                            failedToastAlphaValue = 0.0
                        }
                    }
                }
            })
            .disabled(viewModel.postText.isEmpty && mediaAttatchmentViewModel.medias.isEmpty)
            .isHidden(viewModel.mode == .create)
        }
        .padding([.leading, .trailing], 16)
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
    
    init(targetId: String?, targetType: AmityPostTargetType, community: AmityCommunityModel?) {
        self.targetId = targetId
        self.targetType = targetType
        self.community = community
        self.mode = .create
        self.post = nil
        self.displayName = targetType == .community ? community?.displayName ?? "Unknown" : "My Timeline"
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
        self.mentionData.metadata = post.metadata
    }
    
    @discardableResult
    func createPost(medias: [AmityMedia], files: [AmityFile]) async throws -> AmityPost {
        guard networkMonitor.isConnected else { throw NSError(domain: "Internet is not connected.", code: 500) }
        
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
        } else if !videosData.isEmpty {
            // Video Post
            Log.add(event: .info, "Creating video post with \(videosData.count) images")
            Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")
            
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(postText)
            videoPostBuilder.setVideos(videosData)
            postBuilder = videoPostBuilder
        } else if !filesData.isEmpty {
            // File Post
            Log.add(event: .info, "Creating file post with \(filesData.count) files")
            Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")
            
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(postText)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(postText)
            postBuilder = textPostBuilder
        }
        
        return try await postManager.createPost(postBuilder, targetId: targetId, targetType: targetType, metadata: mentionData.metadata, mentionees: mentionData.mentionee)
    }
    

    func editPost(medias: [AmityMedia], files: [AmityFile]) async throws {
        
        var postBuilder: AmityPostBuilder
        
        let imagesData = getImagesData(from: medias)
        let videosData = getVideosData(from: medias)
        let filesData = getFilesData(from: files)
        
        if post?.dataTypeInternal == .image {
            // Image Post
            Log.add(event: .info, "Creating image post with \(imagesData.count) images")
            Log.add(event: .info, "FileIds: \(imagesData.map{ $0.fileId })")
            
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(postText)
            imagePostBuilder.setImages(imagesData)
            postBuilder = imagePostBuilder
        } else if post?.dataTypeInternal == .video {
            // Video Post
            Log.add(event: .info, "Creating video post with \(videosData.count) images")
            Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")
            
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(postText)
            videoPostBuilder.setVideos(videosData)
            postBuilder = videoPostBuilder
        } else if post?.dataTypeInternal == .file  {
            // File Post
            Log.add(event: .info, "Creating file post with \(filesData.count) files")
            Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")
            
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(postText)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(postText)
            postBuilder = textPostBuilder
        }
        
        
        if let postId = post?.postId {
            try await postManager.editPost(withId: postId, builder: postBuilder, metadata: mentionData.metadata, mentionees: mentionData.mentionee)
        }
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
            case .downloadable(fileData: let fileData), .uploaded(data: let fileData):
                filesData.append(fileData)
            default:
                continue
            }
        }
        return filesData
    }
}
