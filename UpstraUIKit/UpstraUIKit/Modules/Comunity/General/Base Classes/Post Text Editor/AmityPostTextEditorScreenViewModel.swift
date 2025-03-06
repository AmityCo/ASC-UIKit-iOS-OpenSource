//
//  AmityPostTextEditorDataSource.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 26/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK

class AmityPostTextEditorScreenViewModel: AmityPostTextEditorScreenViewModelType {
    
    private let postRepository: AmityPostRepository = AmityPostRepository(client: AmityUIKitManagerInternal.shared.client)
    private var postObjectToken: AmityNotificationToken?
    
    public weak var delegate: AmityPostTextEditorScreenViewModelDelegate?
    private let actionTracker = DispatchGroup()
    
    // MARK: - Datasource
    
    func loadPost(for postId: String) {
        postObjectToken = postRepository.getPost(withId: postId).observe { [weak self] post, error in
            guard let strongSelf = self, let post = post.snapshot else { return }
            strongSelf.delegate?.screenViewModelDidLoadPost(strongSelf, post: post)
            // observe once
            strongSelf.postObjectToken?.invalidate()
        }
    }
    
    // MARK: - Action
    
    func createPost(text: String, medias: [AmityMedia], files: [AmityFile], communityId: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
        
        let imagesData = getImagesData(from: medias)
        let videosData = getVideosData(from: medias)
        let filesData = getFilesData(from: files)
        
        if !imagesData.isEmpty {
            // Image Post
            Log.add("Creating image post with \(imagesData.count) images")
            Log.add("FileIds: \(imagesData.map{ $0.fileId })")
            
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(text)
            imagePostBuilder.setImages(imagesData)
            
            Task { @MainActor in
                do {
                    let post = try await postRepository.createImagePost(imagePostBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees)
                    self.createPostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.createPostResponseHandler(forPost: nil, error: error)
                }
            }
        } else if !videosData.isEmpty {
            // Video Post
            Log.add("Creating video post with \(videosData.count) images")
            Log.add("FileIds: \(videosData.map{ $0.fileId })")
            
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(text)
            videoPostBuilder.setVideos(videosData)
            
            Task { @MainActor in
                do {
                    let post = try await postRepository.createVideoPost(videoPostBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees)
                    self.createPostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.createPostResponseHandler(forPost: nil, error: error)
                }
            }
        } else if !filesData.isEmpty {
            // File Post
            Log.add("Creating file post with \(filesData.count) files")
            Log.add("FileIds: \(filesData.map{ $0.fileId })")
            
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(text)
            fileBuilder.setFiles(getFilesData(from: files))
            
            Task { @MainActor in
                do {
                    let post = try await postRepository.createFilePost(fileBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees)
                    self.createPostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.createPostResponseHandler(forPost: nil, error: error)
                }
            }
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(text)
            
            Task { @MainActor in
                do {
                    let post = try await postRepository.createTextPost(textPostBuilder, targetId: communityId, targetType: targetType, metadata: metadata, mentionees: mentionees)
                    self.createPostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.createPostResponseHandler(forPost: nil, error: error)
                }
            }
        }
    }
    
    /*
     Rules for editing the post:
     - You can delete file/image from the post.
     - You can delete the whole post along with all images & files
     - You cannot update post type. i.e Text - image post or text - file or image to file
     - You cannot add extra images/files or replace images/files in image/file post
     */
    
    func updatePost(oldPost: AmityPostModel, text: String, medias: [AmityMedia], files: [AmityFile], metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?) {
        
        var postBuilder: AmityPostBuilder
        
        let isMediaChanged = oldPost.medias != medias
        let isFileChanged = oldPost.files != files
        
        if oldPost.dataTypeInternal == .image && isMediaChanged {
            // Image Post
            let imagePostBuilder = AmityImagePostBuilder()
            imagePostBuilder.setText(text)
            imagePostBuilder.setImages(getImagesData(from: medias))
            postBuilder = imagePostBuilder
        } else if oldPost.dataTypeInternal == .video && isMediaChanged {
            // Video Post
            let videoPostBuilder = AmityVideoPostBuilder()
            videoPostBuilder.setText(text)
            videoPostBuilder.setVideos(getVideosData(from: medias))
            postBuilder = videoPostBuilder
        } else if oldPost.dataTypeInternal == .file && isFileChanged {
            // File Post
            let fileBuilder = AmityFilePostBuilder()
            fileBuilder.setText(text)
            fileBuilder.setFiles(getFilesData(from: files))
            postBuilder = fileBuilder
        } else {
            // Text Post
            let textPostBuilder = AmityTextPostBuilder()
            textPostBuilder.setText(text)
            postBuilder = textPostBuilder
        }
        
        if let mentionees  {
            Task { @MainActor in
                do {
                    let post = try await postRepository.editPost(withId: oldPost.postId, builder: postBuilder, metadata: metadata, mentionees: mentionees)
                    self.updatePostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.updatePostResponseHandler(forPost: nil, error: error)
                }
            }
        } else {
            Task { @MainActor in
                do {
                    let post = try await postRepository.editPost(withId: oldPost.postId, builder: postBuilder)
                    self.updatePostResponseHandler(forPost: post, error: nil)
                } catch let error {
                    self.updatePostResponseHandler(forPost: nil, error: error)
                }
            }
        }
        
    }
    
    // MARK:- Private Helpers
    
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
    
    // MARK:- Response Helpers
    
    private func createPostResponseHandler(forPost post: AmityPost?, error: Error?) {
        Log.add("File Post Created: \(post != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidCreatePost(self, post: post, error: error)
        NotificationCenter.default.post(name: NSNotification.Name.Post.didCreate, object: nil)
    }
    
    private func updatePostResponseHandler(forPost post: AmityPost?, error: Error?) {
        Log.add("File Post updated: \(post != nil) Error: \(String(describing: error))")
        delegate?.screenViewModelDidUpdatePost(self, error: error)
        NotificationCenter.default.post(name: NSNotification.Name.Post.didUpdate, object: nil)
    }
}
