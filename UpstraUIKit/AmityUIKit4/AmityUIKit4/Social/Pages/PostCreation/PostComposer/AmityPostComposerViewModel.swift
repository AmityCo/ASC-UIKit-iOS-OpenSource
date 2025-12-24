//
//  AmityPostComposerViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/6/25.
//

import SwiftUI
import AmitySDK
import Combine

class AmityPostComposerViewModel: ObservableObject {
    private let communityManager = CommunityManager()
    private let postManager = PostManager()
    private let targetId: String?
    private var community: AmityCommunityModel?
    private var communityToken: AmityNotificationToken?
    private let post: AmityPostModel?
    private let event: AmityEvent?
    
    let mode: AmityPostComposerMode
    let targetType: AmityPostTargetType
    private let networkMonitor = NetworkMonitor()
    
    @Published var displayName: String
    
    let postTitleMaxCount: Int = 150
    var postTitleCount: Int = 0
    @Published var postTitle: String = ""
    @Published var postText: String = ""
    @Published var mentionData: MentionData = MentionData()
    @Published var mentionedUsers: [AmityMentionUserModel] = []
    private let originalPostText: String
    private let originalPostTitle: String
    private let originalMedias: [AmityMedia]
    private var originalLinkPreview: LinkDetail?
    
    @Published var didRemoveLinkPreview = false
    @Published var previewedLink: LinkDetail? // The link being previewed in composer
    @Published var links: [LinkDetail]? = []
    let previewLinkViewModel = PreviewLinkViewModel(text: "")
    var linkCancellable: AnyCancellable?
    
    var isInCreateMode: Bool {
        switch mode {
        case .create, .createClip:
            return true
        case .edit, .editClip:
            return false
        }
    }
    
    var isInClipComposerMode: Bool {
        switch mode {
        case .createClip, .editClip:
            return true
        default:
            return false
        }
    }
    
    init(targetId: String?, targetType: AmityPostTargetType, community: AmityCommunityModel?, mode: AmityPostComposerMode, event: AmityEvent?) {
        self.targetId = targetId
        self.targetType = targetType
        self.community = community
        self.mode = mode
        self.post = nil
        
        if let event {
            self.displayName = event.title
        } else {
            self.displayName = targetType == .community ? community?.displayName ?? "" : "My Timeline"
        }
        self.originalPostText = ""
        self.originalMedias = []
        self.originalPostTitle = ""
        self.event = event
        self.originalLinkPreview = nil
        
        if let communityId = targetId , targetType == .community {
            self.loadTargetCommunity(id: communityId)
        }
        
        self.observeLinkChanges()
    }
    
    // Edit mode
    init(targetId: String, targetType: AmityPostTargetType, post: AmityPostModel, mode: AmityPostComposerMode) {
        self.targetId = targetId
        self.targetType = targetType
        self.mode = mode
        self.post = post
        self.community = nil
        self.displayName = "Edit Post"
        self.postTitle = post.title
        self.postText = post.text
        self.originalPostText = post.text
        self.originalPostTitle = post.title
        self.originalMedias = post.medias
        self.event = nil
        self.mentionData.metadata = post.metadata
        
        post.links.forEach { link in
            if link.renderPreview {
                let previewLink = LinkDetail(index: link.index ?? 0, length: link.length ?? 0, url: link.url)
                
                self.originalLinkPreview = previewLink
                renderPreview(link: previewLink)
            }
        }
        
        self.observeLinkChanges()
    }
    
    func observeLinkChanges() {
        linkCancellable = $links
            .debounce(for: 2, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] extractedLinks in
                guard let self else { return }
                
                if let previewedLink {
                    
                    if let firstLink = extractedLinks?.first, firstLink.url != previewedLink.url {
                        Log.add("Rendering preview for new link: \(firstLink.url)")
                        
                        if didRemoveLinkPreview {
                            self.didRemoveLinkPreview = false
                        }
                        
                        renderPreview(link: firstLink)
                    }
                } else {
                    guard let link = extractedLinks?.first else { return }
                    
                    Log.add("Rendering preview for the first link: \(link.url)")
                    
                    renderPreview(link: link)
                }
            })
    }
    
    func renderPreview(link: LinkDetail) {
        self.previewLinkViewModel.text = link.url
        self.previewedLink = link
        
        Task { @MainActor in
            await self.previewLinkViewModel.getPreviewlinkData()
        }
    }

    func loadTargetCommunity(id: String) {
        communityToken = nil
        communityToken = communityManager.getCommunity(withId: id).observe { [weak self] liveObject, error in
            guard let self else { return }
            if let error {
                self.communityToken?.invalidate()
                self.communityToken = nil
                return
            }
            
            if let snapshot = liveObject.snapshot {
                self.community = AmityCommunityModel(object: snapshot)
                if event == nil {
                    self.displayName = snapshot.displayName
                }
            }
            
            self.communityToken?.invalidate()
            self.communityToken = nil
        }
    }
    // Add a function to check if post has changes in edit mode
    func hasPostChanges(currentTitle: String, currentText: String, currentMedias: [AmityMedia]) -> Bool {
        // Check for text changes (ignoring only whitespace changes)
        let trimmedOriginalText = originalPostText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTextChanges = trimmedOriginalText != trimmedCurrentText
        
        let trimmedOriginalTitle = originalPostTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrentTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitleChanges = trimmedOriginalTitle != trimmedCurrentTitle
        
        // Check for media changes (count, content)
        let hasMediaChanges = !areMediasEqual(originalMedias, currentMedias)
        
        let hasLinkChanges = originalLinkPreview != previewedLink || didRemoveLinkPreview
        
        return hasTextChanges || hasMediaChanges || hasTitleChanges || hasLinkChanges
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
    func createPost(medias: [AmityMedia], files: [AmityFile], hashtags: [AmityHashtagModel], links: [AmityLink]) async throws -> AmityPost {
        guard networkMonitor.isConnected else {
            throw NSError(domain: "Internet is not connected.", code: 500)
        }
        
        let targetType: AmityPostTargetType = targetId == nil ? .user : .community
        
        let imagesData = getImagesData(from: medias)
        let videosData = getVideosData(from: medias)
        let filesData = getFilesData(from: files)
        
        let mentions = AmityMetadataMapper.mentions(fromMetadata: mentionData.metadata ?? [:])
        let hashtags = hashtags.map { AmityHashtag(text: $0.text, index: $0.range.location, length: $0.range.length)}
        let metadata = AmityMetadataMapper.metadata(mentions: mentions, hashtags: hashtags)
        
        
        if !imagesData.isEmpty {
            // Image Post
            Log.add(event: .info, "Creating image post with \(imagesData.count) images")
            Log.add(event: .info, "FileIds: \(imagesData.map{ $0.fileId })")
            
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(postText)
            imagePostBuilder.setTitle(postTitle)
            imagePostBuilder.setImages(imagesData)
            
            return try await postManager.postRepository.createImagePost(
                imagePostBuilder, targetId: targetId, targetType: targetType,
                metadata: metadata, mentionees: mentionData.mentionee, links: links)
            
        } else if !videosData.isEmpty {
            // Video Post
            Log.add(event: .info, "Creating video post with \(videosData.count) images")
            Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")
            
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(postText)
            videoPostBuilder.setTitle(postTitle)
            videoPostBuilder.setVideos(videosData)
            
            return try await postManager.postRepository.createVideoPost(
                videoPostBuilder, targetId: targetId, targetType: targetType,
                metadata: metadata, mentionees: mentionData.mentionee, links: links)
        } else if !filesData.isEmpty {
            // File Post
            Log.add(event: .info, "Creating file post with \(filesData.count) files")
            Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")
            
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(postText)
            fileBuilder.setTitle(postTitle)
            fileBuilder.setFiles(getFilesData(from: files))
            
            return try await postManager.postRepository.createFilePost(
                fileBuilder, targetId: targetId, targetType: targetType,
                metadata: metadata, mentionees: mentionData.mentionee, links: links)
        } else if isInClipComposerMode {
            if case .createClip(_, let draft) = mode {
                let clipBuilder = AmityClipPostBuilder()
                clipBuilder.setClip(draft.clipData)
                clipBuilder.setText(postText)
                clipBuilder.setTitle(postTitle)
                clipBuilder.setIsMuted(draft.isMuted)
                clipBuilder.setDisplayMode(draft.displayMode)
                
                return try await postManager.postRepository.createClipPost(
                    clipBuilder, targetId: targetId, targetType: targetType,
                    metadata: metadata, mentionees: mentionData.mentionee, links: links)
            } else {
                fatalError("Clip post information is not available")
            }
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(postText)
            textPostBuilder.setTitle(postTitle)
            
            let hashtagBuilder = AmityHashtagBuilder()
            let hashtags = hashtags.map { $0.text }
            hashtagBuilder.hashtags(hashtags: hashtags)
            
            return try await postManager.postRepository.createTextPost(
                textPostBuilder, targetId: targetId, targetType: targetType,
                metadata: metadata, mentionees: mentionData.mentionee, hashtags: hashtagBuilder, links: links)
        }
    }
    
    func editPost(medias: [AmityMedia], files: [AmityFile], hashtags: [AmityHashtagModel], links: [AmityLink]) async throws -> AmityPost? {
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
                    imagePostBuilder.setTitle(postTitle)
                    imagePostBuilder.setImages([]) // Empty image array
                    postBuilder = imagePostBuilder
                    
                case .video:
                    Log.add(event: .info, "Removing all videos from video post")
                    let videoPostBuilder = AmityVideoPostBuilder()
                    videoPostBuilder.setText(postText)
                    videoPostBuilder.setTitle(postTitle)
                    videoPostBuilder.setVideos([]) // Empty video array
                    postBuilder = videoPostBuilder
                    
                case .none:
                    // For files or unknown types, default to text post
                    Log.add(event: .info, "Using text post builder")
                    let textPostBuilder = AmityTextPostBuilder()
                    textPostBuilder.setText(postText)
                    textPostBuilder.setTitle(postTitle)
                    postBuilder = textPostBuilder
                }
            } else {
                // If originalMedias is somehow empty, default to text post
                Log.add(event: .info, "Using text post builder (no original media)")
                let textPostBuilder = AmityTextPostBuilder()
                textPostBuilder.setText(postText)
                textPostBuilder.setTitle(postTitle)
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
                imagePostBuilder.setTitle(postTitle)
                imagePostBuilder.setImages(imagesData)
                postBuilder = imagePostBuilder
            } else if !videosData.isEmpty {
                // Video Post
                Log.add(event: .info, "Editing post with \(videosData.count) videos")
                Log.add(event: .info, "FileIds: \(videosData.map{ $0.fileId })")
                
                let videoPostBuilder = AmityVideoPostBuilder()
                videoPostBuilder.setText(postText)
                videoPostBuilder.setTitle(postTitle)
                videoPostBuilder.setVideos(videosData)
                postBuilder = videoPostBuilder
            } else if !filesData.isEmpty {
                // File Post
                Log.add(event: .info, "Editing post with \(filesData.count) files")
                Log.add(event: .info, "FileIds: \(filesData.map{ $0.fileId })")
                
                let fileBuilder = AmityFilePostBuilder()
                fileBuilder.setText(postText)
                fileBuilder.setTitle(postTitle)
                fileBuilder.setFiles(getFilesData(from: files))
                postBuilder = fileBuilder
            } else if isInClipComposerMode {
                Log.add(event: .info, "Editing clip post")
                let clipBuilder = AmityClipPostBuilder()
                clipBuilder.setText(postText)
                clipBuilder.setTitle(postTitle)
                
                postBuilder = clipBuilder
            } else {
                // Text Post
                Log.add(event: .info, "Editing text post")
                let textPostBuilder = AmityTextPostBuilder()
                textPostBuilder.setText(postText)
                textPostBuilder.setTitle(postTitle)
                postBuilder = textPostBuilder
            }
        }
        
        let mentions = AmityMetadataMapper.mentions(fromMetadata: mentionData.metadata ?? [:])
        let hashtags = hashtags.map { AmityHashtag(text: $0.text, index: $0.range.location, length: $0.range.length)}
        let metadata = AmityMetadataMapper.metadata(mentions: mentions, hashtags: hashtags)
        
        let hashtagBuilder = AmityHashtagBuilder()
        hashtagBuilder.hashtags(hashtags: hashtags.map { $0.text })
        
        if let postId = post?.postId {
            return try await postManager.editPost(
                withId: postId, builder: postBuilder, metadata: metadata,
                mentionees: mentionData.mentionee, hashtags: hashtagBuilder, links: links)
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
    
    func getEmbeddedLinks() -> [AmityLink] {
        if let previewedLink {
            let metadata = previewLinkViewModel.previewLinkData
            
            guard let links, !links.isEmpty else {
                return [AmityLink(url: previewedLink.url, index: 0, length: 0, renderPreview: true, domain: metadata.domain, title: metadata.title, imageUrl: metadata.imageUrl?.absoluteString)]
            }
            
            let mappedLinks = links.map {
                if $0.url == previewedLink.url {
                    AmityLink(url: $0.url, index: $0.index, length: $0.length, renderPreview: true, domain: metadata.domain, title: metadata.title, imageUrl: metadata.imageUrl?.absoluteString)
                } else {
                    AmityLink(url: $0.url, index: $0.index, length: $0.length, renderPreview: false, domain: nil, title: nil, imageUrl: nil)
                }
            }
            
            return mappedLinks
        } else {
            guard let links, !links.isEmpty else { return [] }
            
            let mappedLinks = links.map {
                AmityLink(url: $0.url, index: $0.index, length: $0.length, renderPreview: false, domain: nil, title: nil, imageUrl: nil)
            }
            return mappedLinks
        }
    }
}
