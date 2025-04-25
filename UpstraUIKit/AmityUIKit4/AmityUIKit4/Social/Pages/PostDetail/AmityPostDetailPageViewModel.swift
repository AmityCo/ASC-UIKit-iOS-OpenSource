//
//  AmityPostDetailPageViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/3/25.
//
import AmitySDK
import Combine

class AmityPostDetailPageViewModel: ObservableObject {
    private var postObject: AmityObject<AmityPost>?
    private var postId: String = ""
    private var cancellable: AnyCancellable?
    private let postManager = PostManager()
    
    @Published var post: AmityPostModel?
    @Published var isPostDeleted = false
    @Published var isLoading = false
    
    var token: AmityNotificationToken?
    
    init(id: String) {
        self.postId = id
        guard !id.isEmpty else {
            self.isPostDeleted = true
            return
        }
        
        // In other cases, post should already be available in local cache.
        isLoading = true
        observePost(postId: postId)
        
        // Add observer
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePoll(_:)), name: .didVotePoll, object: nil)
    }
    
    init(post: AmityPost) {
        self.postId = post.postId
        self.post = AmityPostModel(post: post)
                
        observePost(postId: post.postId)
        
        // Add observer
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePoll(_:)), name: .didVotePoll, object: nil)
    }
    
    @objc private func didUpdatePoll(_ notification: Notification) {
        observePost(postId: self.postId)
    }
    
    func observePost(postId: String) {
        token?.invalidate()
        token = nil
        
        postObject = postManager.getPost(withId: postId)
        token = postObject?.observe({ [weak self] livePost, error in
            guard let self else { return }
            
            if let error {
                self.isLoading = false
                self.isPostDeleted = true
                return
            }
            
            self.isLoading = false
            
            if let snapshot = livePost.snapshot {
                self.post = AmityPostModel(post: snapshot)
                self.isPostDeleted = snapshot.isDeleted
            }
        })
    }
}
