//
//  LivestreamVideoPlayerViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import AmitySDK

class LivestreamVideoPlayerViewModel: ObservableObject {
    
    let streamManager = StreamManager()
    let postManager = PostManager()
    
    var streamToken: AmityNotificationToken?
    var postToken: AmityNotificationToken?
    
    let post: AmityPostModel
    
    @Published var isLoaded = false
    @Published var stream: AmityStream?
    @Published var isStreamTerminated = false
    @Published var isPostDeleted = false
    
    init(post: AmityPostModel) {
        self.post = post
        observeStream(streamId: post.liveStream?.streamId ?? "")
        observePost(postId: post.postId)
    }
    
    private func observePost(postId: String) {
        postToken?.invalidate()
        postToken = nil
        
        postToken = postManager.getPost(withId: postId).observe { [weak self] data, error in
            guard let self, let post = data.snapshot else { return }
            
            if post.isDeleted {
                isPostDeleted = true
                unobservePostAndStream()
            }
        }
        
        post.object.subscribeEvent(.post) { success, error in
            Log.add(event: .info, "Subscribing post event status: \(success) Error: \(String(describing: error))")
        }
    }
    
    private func observeStream(streamId: String) {
        streamToken?.invalidate()
        streamToken = nil
        isLoaded = false
        
        streamToken = streamManager.getStream(id: streamId).observe { [weak self] data, error in
            guard let self, let stream = data.snapshot else { return }
            
            self.isLoaded = true
            
            if stream.status != .idle {
                self.stream = stream
            }
            
            let terminateLabels = stream.moderation?.terminateLabels ?? []
            if !terminateLabels.isEmpty {
                
                self.isStreamTerminated = true
                self.unobservePostAndStream()
                
                NotificationCenter.default.post(name: .didLivestreamStatusUpdated, object: self.post.object)

                return
            }
            
            if stream.status == .ended {
                NotificationCenter.default.post(name: .didLivestreamStatusUpdated, object: self.post.object)
                
                unobservePostAndStream()
                return
            }
        }
    }
    
    func unobservePostAndStream() {
        self.streamToken?.invalidate()
        self.streamToken = nil
        
        self.postToken?.invalidate()
        self.postToken = nil
                
        self.post.object.unsubscribeEvent(.post) { success, error in
            Log.add(event: .info, "Unsubscribing post event status: \(success) Error: \(String(describing: error))")
        }
    }
    
}
