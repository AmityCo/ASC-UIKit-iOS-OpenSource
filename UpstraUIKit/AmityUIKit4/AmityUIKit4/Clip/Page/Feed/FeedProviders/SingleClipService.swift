//
//  SingleClipService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/6/25.
//

import SwiftUI
import AmitySDK
import Foundation

/// Used in post detail page
class SingleClipService: ClipService {
    
    let postManager = PostManager()
    
    var postId: String?
    var token: AmityNotificationToken?
    
    init(clipPost: ClipPost) {
        super.init()
        
        self.clips = [clipPost]
        self.startIndex = 0
        self.currentIndex = 0
    }
    
    // To support loading clip post from notification or shareable link
    init(postId: String) {
        super.init()
        
        self.postId = postId
        self.startIndex = 0
        self.currentIndex = 0
    }
    
    override func load() {
        if let postId, !postId.isEmpty {
            self.fetchSinglePost(postId: postId)
        } else {
            self.loadingState = .loaded
            onLoadCompletion?()
        }
    }
    
    override func canLoadMore() -> Bool {
        return false
    }
    
    func fetchSinglePost(postId: String) {
        token = postManager.getPost(withId: postId).observe { [weak self] liveObject, error in
            guard let self else { return }
            
            if let error {
                self.loadingState = .error
                self.onLoadCompletion?()
                
                token?.invalidate()
                token = nil
                
                return
            }
            
            if let snapshot = liveObject.snapshot {
                let postModel = AmityPostModel(post: snapshot)
                
                if let media = postModel.medias.first, let mediaURL = URL(string: media.clip?.fileURL ?? "")  {
                    let clipPost = ClipPost(id: postModel.postId, url: mediaURL, model: postModel)
                    self.clips = [clipPost]
                    
                    self.loadingState = .loaded
                    self.onLoadCompletion?()
                }
                
                token?.invalidate()
                token = nil
            }
        }
    }
}
